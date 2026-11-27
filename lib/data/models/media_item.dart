/// Content kind — matches the provider split (live/movie/series).
/// The displayed kind name is localized in the UI (kindLive/kindMovie/kindSeries).
enum MediaKind { live, movie, series }

/// Unified content item for display in the UI. IDs are the stable provider IDs
/// (streamId/seriesId) used for stream resolution and watch-together.
class MediaItem {
  const MediaItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.posterUrl,
    this.backdropUrl,
    this.categoryId,
    this.categoryName,
    this.rating,
    this.year,
    this.description,
    this.nowPlaying,
    this.progress,
  });

  final String id;
  final MediaKind kind;
  final String title;
  final String posterUrl;
  final String? backdropUrl;
  final String? categoryId;
  final String? categoryName;
  final double? rating; // 0..10
  final String? year;
  final String? description;

  /// Current programme (EPG) for live channels.
  final String? nowPlaying;

  /// Watch progress 0..1 for the "Continue watching" row.
  final double? progress;

  bool get isLive => kind == MediaKind.live;
}
