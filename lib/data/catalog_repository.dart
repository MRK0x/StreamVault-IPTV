import 'grouping.dart';
import 'models/category_group.dart';
import 'models/content_row.dart';
import 'models/media_item.dart';
import 'models/series_info.dart';
import 'mock_catalog.dart';

/// Catalog contract — a real implementation (dio → /api/tv/*) replaces the
/// mock later without changing the UI.
abstract class CatalogRepository {
  Future<MediaItem> featured();
  Future<List<ContentRow>> homeRows();
  Future<List<MediaItem>> liveChannels();
  Future<List<MediaItem>> movies();
  Future<List<MediaItem>> series();

  /// Groups by category (group name + its items) — for browsing.
  Future<List<CategoryGroup>> liveGroups();
  Future<List<CategoryGroup>> movieGroups();
  Future<List<CategoryGroup>> seriesGroups();

  /// Series details (seasons + episodes) — fetched on demand.
  /// The episode owns the stream (not the series).
  Future<SeriesInfo> seriesInfo(String seriesId);

  /// Clears the in-memory cache (for pull-to-refresh). No-op in the mock.
  void clearCache() {}

  /// "Sync all": clears the memory **and disk** cache so the catalog is
  /// reloaded from the network.
  Future<void> purgeStorage() async {}

  /// Time of the last successful sync (null = not loaded yet).
  Future<DateTime?> lastSync() async => null;
}

/// Mock implementation with local data — runs the full UI without a server
/// (demo mode).
class MockCatalogRepository implements CatalogRepository {
  const MockCatalogRepository();

  Future<T> _delayed<T>(T value) =>
      Future<T>.delayed(const Duration(milliseconds: 350), () => value);

  @override
  Future<MediaItem> featured() => _delayed(MockCatalog.featured);

  @override
  Future<List<ContentRow>> homeRows() => _delayed(MockCatalog.homeRows);

  @override
  Future<List<MediaItem>> liveChannels() => _delayed(MockCatalog.liveChannels);

  @override
  Future<List<MediaItem>> movies() => _delayed(MockCatalog.movies);

  @override
  Future<List<MediaItem>> series() => _delayed(MockCatalog.series);

  @override
  Future<List<CategoryGroup>> liveGroups() =>
      _delayed(buildGroups(MockCatalog.liveChannels, MockCatalog.mockCategories));

  @override
  Future<List<CategoryGroup>> movieGroups() =>
      _delayed(buildGroups(MockCatalog.movies, MockCatalog.mockCategories));

  @override
  Future<List<CategoryGroup>> seriesGroups() =>
      _delayed(buildGroups(MockCatalog.series, MockCatalog.mockCategories));

  @override
  Future<SeriesInfo> seriesInfo(String seriesId) => _delayed(
        SeriesInfo(seasons: const [], episodes: MockCatalog.episodesFor(seriesId)),
      );

  @override
  void clearCache() {}

  @override
  Future<void> purgeStorage() async {}

  @override
  Future<DateTime?> lastSync() async => null;
}
