import 'media_item.dart';

/// A series episode — in Xtream the episode (not the series) **owns** the stream.
/// Playback: `/api/tv/stream/series/{episode.id}.mp4`
class Episode {
  const Episode({
    required this.id,
    required this.title,
    required this.season,
    required this.number,
    this.plot,
    this.cover,
    this.durationSecs,
  });

  /// The episode's real stream ID (episodes[].id).
  final String id;
  final String title;
  final int season;
  final int number;
  final String? plot;
  final String? cover;
  final int? durationSecs;

  String get label => 'S${season}E$number';

  /// Converts it into a playable item (kind=series, id=episode_id).
  MediaItem toPlayable({String? seriesTitle, String? fallbackPoster}) {
    return MediaItem(
      id: id,
      kind: MediaKind.series,
      title: seriesTitle == null ? title : '$seriesTitle — $label',
      posterUrl: cover ?? fallbackPoster ?? '',
      backdropUrl: cover ?? fallbackPoster,
      description: plot,
    );
  }
}
