import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/content_row.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../widgets/loading.dart';
import 'widgets/content_row_view.dart';
import 'widgets/hero_header.dart';

/// Home screen — hero + poster rows.
///
/// **Incremental on purpose:** each row is built from its own provider and
/// appears as soon as its data arrives, instead of a `Future.wait` on the
/// whole catalog (which meant waiting for the slowest, ~17s).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Hero item: the highest rated one that has a backdrop.
  MediaItem? _featured(List<MediaItem> movies) {
    if (movies.isEmpty) return null;
    final withArt = movies
        .where((e) => (e.backdropUrl?.isNotEmpty ?? false) && e.rating != null)
        .toList()
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    return withArt.isNotEmpty ? withArt.first : movies.first;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppText.of(context);
    final live = ref.watch(liveChannelsProvider);
    final movies = ref.watch(moviesProvider);
    final series = ref.watch(seriesProvider);

    // No pull-to-refresh: the catalog loads once and stays; refreshing is
    // manual via "Sync all" in Settings — so a stray swipe doesn't refetch.
    return CustomScrollView(
      slivers: [
        // Hero (from movies) — skeleton until they arrive.
        SliverToBoxAdapter(
          child: movies.when(
            data: (m) {
              final f = _featured(m);
              return f == null
                  ? const SizedBox.shrink()
                  : HeroHeader(item: f);
            },
            loading: () => const _HeroSkeleton(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
        _rowSliver(t.homeLiveChannels, live),
        _rowSliver(t.homeTrendingMovies, movies),
        _rowSliver(t.homeSelectedSeries, series),
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  /// Independent row: shows its own loading indicator, then the content as
  /// soon as it arrives.
  Widget _rowSliver(String title, AsyncValue<List<MediaItem>> async) {
    return SliverToBoxAdapter(
      child: async.when(
        data: (items) => items.isEmpty
            ? const SizedBox.shrink()
            : ContentRowView(
                row: ContentRow(title: title, items: items.take(20).toList()),
              ),
        loading: () => _RowSkeleton(title: title),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 460,
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const LoadingView(),
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: 4,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (_, _) => Container(
              width: 124,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
