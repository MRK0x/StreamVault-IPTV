import 'episode.dart';

/// A season from `seasons[]` in the `/api/tv/series/{id}` response.
class Season {
  const Season({
    required this.number,
    this.name,
    this.cover,
    this.airDate,
    this.episodeCount,
  });

  final int number;
  final String? name;
  final String? cover;
  final String? airDate;
  final int? episodeCount;

  /// The season's custom name from the server if any, otherwise null (the UI
  /// shows "Season N").
  String? get customName => (name?.trim().isNotEmpty ?? false) ? name!.trim() : null;
}

/// Series details: seasons + episodes (the episode owns the stream).
class SeriesInfo {
  const SeriesInfo({required this.seasons, required this.episodes});

  final List<Season> seasons;
  final List<Episode> episodes;

  bool get isEmpty => episodes.isEmpty;

  /// Season numbers actually available (from the episodes), sorted.
  List<int> get seasonNumbers {
    final fromEpisodes = episodes.map((e) => e.season).toSet().toList()..sort();
    return fromEpisodes;
  }

  /// The season's custom name from `seasons[]` if any, otherwise null.
  /// The UI shows a localized "Season N" when it's absent.
  String? seasonName(int number) {
    for (final s in seasons) {
      if (s.number == number) return s.customName;
    }
    return null;
  }

  List<Episode> ofSeason(int number) =>
      episodes.where((e) => e.season == number).toList();
}
