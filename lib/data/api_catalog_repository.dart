import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_paths.dart';
import 'catalog_cache.dart';
import 'catalog_repository.dart';
import 'grouping.dart';
import 'models/category_group.dart';
import 'models/content_row.dart';
import 'models/media_item.dart';
import 'models/series_info.dart';
import 'xtream_mapper.dart';

/// Runs on a background isolate via [compute] — must stay a top-level function.
dynamic _decodeJson(String raw) => jsonDecode(raw);

/// Real catalog via /api/tv/*. Replaces the mock when the secrets are
/// available.
class ApiCatalogRepository implements CatalogRepository {
  ApiCatalogRepository(this._dio);

  final Dio _dio;

  // In-flight dedup: we cache the Future, not the result — so concurrent calls
  // (homeRows + the provider tabs) share a single request per endpoint.
  // (The Xtream provider sometimes returns empty for concurrent duplicate
  // requests.)
  Future<List<MediaItem>>? _live;
  Future<List<MediaItem>>? _movies;
  Future<List<MediaItem>>? _series;

  // Category maps (id → name, ordered) — filled while fetching and used for
  // grouping.
  Map<String, String> _liveCats = const {};
  Map<String, String> _movieCats = const {};
  Map<String, String> _seriesCats = const {};

  @override
  void clearCache() {
    _live = null;
    _movies = null;
    _series = null;
    _episodes.clear();
  }

  /// "Sync all": clear memory + disk → the next fetch hits the network.
  @override
  Future<void> purgeStorage() async {
    clearCache();
    await CatalogCache.clear();
  }

  @override
  Future<DateTime?> lastSync() => CatalogCache.lastSync();

  @override
  Future<List<CategoryGroup>> liveGroups() async =>
      buildGroups(await liveChannels(), _liveCats);

  @override
  Future<List<CategoryGroup>> movieGroups() async =>
      buildGroups(await movies(), _movieCats);

  @override
  Future<List<CategoryGroup>> seriesGroups() async =>
      buildGroups(await series(), _seriesCats);

  // Each series' details are fetched on demand and cached (sharing the
  // in-flight request).
  final Map<String, Future<SeriesInfo>> _episodes = {};

  @override
  Future<SeriesInfo> seriesInfo(String seriesId) {
    return _episodes[seriesId] ??=
        _fetchSeriesInfo(seriesId).catchError((Object e) {
      _episodes.remove(seriesId);
      throw e;
    });
  }

  Future<SeriesInfo> _fetchSeriesInfo(String seriesId) async {
    final data = await _get(ApiPaths.seriesInfo(seriesId));
    return XtreamMapper.seriesInfo(data);
  }

  /// Queue: **one network request at a time**.
  /// The provider (Xtream) returns an empty array for some requests under
  /// concurrent load, so we serialize them instead of firing 6 at once.
  Future<void> _queue = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() task) {
    final c = Completer<T>();
    _queue = _queue.then((_) async {
      try {
        c.complete(await task());
      } catch (e, st) {
        c.completeError(e, st);
      }
    });
    return c.future;
  }

  /// An empty response = a transient provider failure, **not** valid data.
  static bool _isEmpty(dynamic d) =>
      d == null || (d is List && d.isEmpty) || (d is Map && d.isEmpty);

  /// Reads from the disk cache if present and valid, otherwise fetches from the
  /// network and stores it. Decoding always runs on a background isolate (the
  /// catalog is huge).
  ///
  /// There is no time-based expiry: after the first load the catalog stays
  /// local until "Sync all".
  /// **We never cache an empty response** (otherwise content would vanish for
  /// good).
  Future<dynamic> _get(String path) async {
    final cached = await CatalogCache.read(path);
    if (cached != null) {
      final data = await compute(_decodeJson, cached);
      if (!_isEmpty(data)) {
        debugPrint('CACHE hit  $path (${cached.length}B)');
        return data;
      }
      debugPrint('CACHE corrupt (empty) $path → refetching');
    }

    return _serialized(() async {
      // A previous request in the queue may have cached it in the meantime.
      final again = await CatalogCache.read(path);
      if (again != null) {
        final data = await compute(_decodeJson, again);
        if (!_isEmpty(data)) return data;
      }

      dynamic last;
      for (var attempt = 1; attempt <= 3; attempt++) {
        final r = await _dio.get<String>(
          path,
          options: Options(responseType: ResponseType.plain), // raw, for caching
        );
        final raw = r.data ?? '';
        last = await compute(_decodeJson, raw);
        if (!_isEmpty(last)) {
          await CatalogCache.write(path, raw);
          return last;
        }
        debugPrint('Empty response $path (try $attempt/3) → retrying');
        await Future<void>.delayed(Duration(milliseconds: 800 * attempt));
      }
      debugPrint('⚠️ $path still empty after 3 tries, not caching');
      return last;
    });
  }

  @override
  Future<List<MediaItem>> liveChannels() {
    return _live ??= _fetchLive().catchError((Object e) {
      _live = null;
      throw e;
    });
  }

  Future<List<MediaItem>> _fetchLive() async {
    final results = await Future.wait([
      _get(ApiPaths.liveCategories),
      _get(ApiPaths.liveStreams),
    ]);
    _liveCats = XtreamMapper.categories(results[0]);
    return XtreamMapper.live(results[1], _liveCats);
  }

  @override
  Future<List<MediaItem>> movies() {
    return _movies ??= _fetchMovies().catchError((Object e) {
      _movies = null;
      throw e;
    });
  }

  Future<List<MediaItem>> _fetchMovies() async {
    final results = await Future.wait([
      _get(ApiPaths.vodCategories),
      _get(ApiPaths.vodStreams),
    ]);
    _movieCats = XtreamMapper.categories(results[0]);
    return XtreamMapper.movies(results[1], _movieCats);
  }

  @override
  Future<List<MediaItem>> series() {
    return _series ??= _fetchSeries().catchError((Object e) {
      _series = null;
      throw e;
    });
  }

  Future<List<MediaItem>> _fetchSeries() async {
    final results = await Future.wait([
      _get(ApiPaths.seriesCategories),
      _get(ApiPaths.series),
    ]);
    _seriesCats = XtreamMapper.categories(results[0]);
    return XtreamMapper.series(results[1], _seriesCats);
  }

  @override
  Future<MediaItem> featured() async {
    final m = await movies();
    // Pick a movie with a good backdrop for the hero.
    final withBackdrop = m.where((e) =>
        (e.backdropUrl?.isNotEmpty ?? false) && e.rating != null);
    if (withBackdrop.isNotEmpty) {
      withBackdrop.toList().sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
      return withBackdrop.first;
    }
    if (m.isNotEmpty) return m.first;
    final l = await liveChannels();
    return l.first;
  }

  @override
  Future<List<ContentRow>> homeRows() async {
    final results = await Future.wait([
      liveChannels(),
      movies(),
      series(),
    ]);
    final live = results[0];
    final mv = results[1];
    final sr = results[2];

    return [
      if (live.isNotEmpty)
        ContentRow(title: 'قنوات مباشرة', items: live.take(20).toList()),
      if (mv.isNotEmpty)
        ContentRow(title: 'أفلام رائجة', items: mv.take(20).toList()),
      if (sr.isNotEmpty)
        ContentRow(title: 'مسلسلات مختارة', items: sr.take(20).toList()),
      if (mv.length > 20)
        ContentRow(title: 'أضيف حديثاً', items: mv.skip(20).take(20).toList()),
    ];
  }
}
