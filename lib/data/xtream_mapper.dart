import 'models/episode.dart';
import 'models/media_item.dart';
import 'models/series_info.dart';

/// Maps Xtream responses (/api/tv/*) to UI models.
/// Defensive: accepts a list at the root or wrapped in a key
/// (data/streams/…), and missing fields.
class XtreamMapper {
  XtreamMapper._();

  /// Extracts the item list from a response that may be a List or a wrapped
  /// Map.
  static List<Map<String, dynamic>> listOf(dynamic data) {
    dynamic v = data;
    if (v is Map) {
      v = v['data'] ?? v['streams'] ?? v['items'] ?? v['result'] ?? v.values.firstWhere(
            (e) => e is List,
            orElse: () => const [],
          );
    }
    if (v is List) {
      return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return const [];
  }

  /// Map of category_id → category_name.
  static Map<String, String> categories(dynamic data) {
    final out = <String, String>{};
    for (final c in listOf(data)) {
      final id = '${c['category_id'] ?? c['id'] ?? ''}';
      final name = '${c['category_name'] ?? c['name'] ?? ''}';
      if (id.isNotEmpty) out[id] = name;
    }
    return out;
  }

  static List<MediaItem> live(dynamic data, Map<String, String> cats) {
    return listOf(data).map((j) {
      final id = '${j['stream_id'] ?? j['id'] ?? ''}';
      return MediaItem(
        id: id,
        kind: MediaKind.live,
        title: '${j['name'] ?? ''}'.trim(),
        posterUrl: _str(j['stream_icon'] ?? j['icon']),
        categoryId: '${j['category_id'] ?? ''}',
        categoryName: cats['${j['category_id']}'],
      );
    }).where((m) => m.id.isNotEmpty).toList();
  }

  /// We show **mp4 only**: the stream path forces `.mp4`, so any other
  /// container (mkv/avi/ts) isn't found by the CDN, which returns empty → a
  /// broken item. We hide it instead of showing it.
  /// (Missing container = assume mp4.)
  static bool _isMp4(dynamic containerExt) {
    final e = _str(containerExt).trim().toLowerCase();
    return e.isEmpty || e == 'mp4';
  }

  static List<MediaItem> movies(dynamic data, Map<String, String> cats) {
    return listOf(data)
        .where((j) => _isMp4(j['container_extension']))
        .map((j) {
      final id = '${j['stream_id'] ?? j['id'] ?? ''}';
      final poster = _str(j['stream_icon'] ?? j['movie_image'] ?? j['cover']);
      return MediaItem(
        id: id,
        kind: MediaKind.movie,
        title: '${j['name'] ?? ''}'.trim(),
        posterUrl: poster,
        backdropUrl: _firstBackdrop(j) ?? poster,
        categoryId: '${j['category_id'] ?? ''}',
        categoryName: cats['${j['category_id']}'],
        rating: _rating(j['rating']),
        year: _year(j['releaseDate'] ?? j['added']),
        description: _str(j['plot'] ?? j['description']).isEmpty
            ? null
            : _str(j['plot'] ?? j['description']),
      );
    }).where((m) => m.id.isNotEmpty).toList();
  }

  static List<MediaItem> series(dynamic data, Map<String, String> cats) {
    return listOf(data).map((j) {
      final id = '${j['series_id'] ?? j['id'] ?? ''}';
      final poster = _str(j['cover'] ?? j['stream_icon']);
      return MediaItem(
        id: id,
        kind: MediaKind.series,
        title: '${j['name'] ?? j['title'] ?? ''}'.trim(),
        posterUrl: poster,
        backdropUrl: _firstBackdrop(j) ?? poster,
        categoryId: '${j['category_id'] ?? ''}',
        categoryName: cats['${j['category_id']}'],
        rating: _rating(j['rating']),
        year: _year(j['releaseDate'] ?? j['last_modified']),
        description: _str(j['plot'] ?? j['description']).isEmpty
            ? null
            : _str(j['plot'] ?? j['description']),
      );
    }).where((m) => m.id.isNotEmpty).toList();
  }

  /// Series details from `/api/tv/series/{id}` (`get_series_info`
  /// passthrough): seasons + episodes.
  static SeriesInfo seriesInfo(dynamic data) => SeriesInfo(
        seasons: seasons(data),
        episodes: episodes(data),
      );

  /// `seasons[]` — may be absent; seasons are then derived from the episodes.
  static List<Season> seasons(dynamic data) {
    final raw = (data is Map) ? data['seasons'] : null;
    if (raw is! List) return const [];
    final out = <Season>[];
    for (final e in raw.whereType<Map>()) {
      final j = e.cast<String, dynamic>();
      final n = int.tryParse('${j['season_number'] ?? j['season'] ?? ''}');
      if (n == null) continue;
      out.add(Season(
        number: n,
        name: _nullIfEmpty(_str(j['name'])),
        cover: _nullIfEmpty(_str(j['cover'] ?? j['cover_big'])),
        airDate: _nullIfEmpty(_str(j['air_date'])),
        episodeCount: int.tryParse('${j['episode_count'] ?? ''}'),
      ));
    }
    out.sort((a, b) => a.number.compareTo(b.number));
    return out;
  }

  /// A series' episodes from the `/api/tv/series/{id}` response.
  /// Xtream returns `episodes` as a map {"1":[...], "2":[...]} keyed by season
  /// number, but it may also come as a flat list — we accept both shapes.
  static List<Episode> episodes(dynamic data) {
    final raw = (data is Map) ? data['episodes'] : data;
    final out = <Episode>[];

    void addAll(Iterable list, int? seasonHint) {
      for (final e in list.whereType<Map>()) {
        final j = e.cast<String, dynamic>();
        final id = '${j['id'] ?? j['episode_id'] ?? ''}';
        if (id.isEmpty) continue;
        // mp4 only — the CDN doesn't serve episodes in other containers on
        // the .mp4 path.
        if (!_isMp4(j['container_extension'])) continue;
        final info = (j['info'] is Map)
            ? (j['info'] as Map).cast<String, dynamic>()
            : const <String, dynamic>{};
        out.add(Episode(
          id: id,
          // Episode title from the server; left empty when absent so the UI
          // shows just "SxxExx" (we don't build Arabic text in the data
          // layer).
          title: _str(j['title'] ?? info['name']).trim(),
          season: int.tryParse('${j['season'] ?? seasonHint ?? 1}') ??
              (seasonHint ?? 1),
          number: int.tryParse('${j['episode_num'] ?? j['num'] ?? 0}') ?? 0,
          plot: _nullIfEmpty(_str(info['plot'] ?? info['description'])),
          cover: _nullIfEmpty(
              _str(info['movie_image'] ?? info['cover_big'] ?? j['cover'])),
          durationSecs: int.tryParse('${info['duration_secs'] ?? ''}'),
        ));
      }
    }

    if (raw is Map) {
      raw.forEach((season, list) {
        if (list is List) addAll(list, int.tryParse('$season'));
      });
    } else if (raw is List) {
      addAll(raw, null);
    }

    out.sort((a, b) => a.season != b.season
        ? a.season.compareTo(b.season)
        : a.number.compareTo(b.number));
    return out;
  }

  static String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s;

  static String _str(dynamic v) => v == null ? '' : '$v';

  static String? _firstBackdrop(Map<String, dynamic> j) {
    final b = j['backdrop_path'];
    if (b is List && b.isNotEmpty) return '${b.first}';
    if (b is String && b.isNotEmpty) return b;
    return null;
  }

  static double? _rating(dynamic v) {
    if (v == null) return null;
    final d = double.tryParse('$v');
    if (d == null || d <= 0) return null; // 0 = unrated → no badge
    return d > 10 ? 10 : d; // some providers return 0..10
  }

  static String? _year(dynamic v) {
    final s = '$v';
    final m = RegExp(r'(\d{4})').firstMatch(s);
    return m?.group(1);
  }
}
