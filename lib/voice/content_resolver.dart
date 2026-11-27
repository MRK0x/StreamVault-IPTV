import '../data/catalog_repository.dart';
import '../data/models/media_item.dart';
import 'watch_now_info.dart';

/// Resolves a watch-together message to a playable item on **this** device.
///
/// - **live / movie:** catalog lookup by `sid` (stable provider ID).
/// - **series:** by `eid` directly (the episode owns the stream); if missing, by
///   `ser`+`sn`+`ep` after fetching the series details (episodes load on demand).
class ContentResolver {
  ContentResolver(this._repo);

  final CatalogRepository _repo;

  Future<MediaItem?> resolve(WatchNowInfo info) async {
    switch (info.kind) {
      case MediaKind.live:
        return _find(await _repo.liveChannels(), info.streamId);

      case MediaKind.movie:
        return _find(await _repo.movies(), info.streamId);

      case MediaKind.series:
        return _resolveEpisode(info);
    }
  }

  Future<MediaItem?> _resolveEpisode(WatchNowInfo info) async {
    // The episode is directly playable by its ID — no need to fetch the series.
    final eid = info.episodeId;
    if (eid != null && eid.isNotEmpty) {
      return MediaItem(
        id: eid,
        kind: MediaKind.series,
        title: info.title,
        posterUrl: info.image ?? '',
        backdropUrl: info.image,
      );
    }

    // Fallback: ser + sn + ep → fetch the episodes and match.
    final ser = info.seriesId;
    if (ser == null || ser.isEmpty) return null;
    final detail = await _repo.seriesInfo(ser);
    for (final e in detail.episodes) {
      if (e.season == (info.season ?? e.season) &&
          e.number == (info.episode ?? e.number)) {
        return e.toPlayable(seriesTitle: info.title, fallbackPoster: info.image);
      }
    }
    return null;
  }

  MediaItem? _find(List<MediaItem> items, String? id) {
    if (id == null || id.isEmpty) return null;
    for (final m in items) {
      if (m.id == id) return m;
    }
    return null;
  }
}
