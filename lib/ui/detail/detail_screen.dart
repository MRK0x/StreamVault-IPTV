import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../player/player_screen.dart';
import '../voice/voice_room_sheet.dart';
import '../widgets/badges.dart';
import '../widgets/brand_button.dart';
import '../widgets/poster_image.dart';
import 'episodes_section.dart';

/// Opens the details screen with an iOS transition (swipe-to-go-back).
void openDetail(BuildContext context, MediaItem item) {
  Navigator.of(context).push(
    CupertinoPageRoute(builder: (_) => DetailScreen(item: item)),
  );
}

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.item});

  final MediaItem item;

  bool get _isSeries => item.kind == MediaKind.series;

  /// A series isn't streamed — play its first episode. Anything else plays
  /// directly.
  void _play(BuildContext context, WidgetRef ref) {
    MediaItem playable = item;
    if (_isSeries) {
      final info = ref.read(seriesInfoProvider(item.id)).valueOrNull;
      if (info == null || info.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.of(context).detailLoadingEpisodes)),
        );
        return;
      }
      playable = info.episodes.first.toPlayable(
        seriesTitle: item.title,
        fallbackPoster: item.posterUrl,
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlayerScreen(item: playable),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 340,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.canvas,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: _circleIcon(
                  Icons.arrow_forward_ios_rounded, () => Navigator.pop(context)),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  PosterImage(
                    url: item.backdropUrl ?? item.posterUrl,
                    seed: item.id,
                    borderRadius: 0,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, AppColors.canvas],
                        stops: [0.35, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      if (item.isLive)
                        const LiveBadge()
                      else if (item.rating != null)
                        RatingChip(item.rating!),
                      _metaPill(_kindLabel(context, item.kind)),
                      if (item.year != null) _metaPill(item.year!),
                      if (item.categoryName != null) _metaPill(item.categoryName!),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  BrandButton(
                    label: item.isLive
                        ? AppText.of(context).detailWatchNow
                        : (_isSeries
                            ? AppText.of(context).detailPlayFirstEpisode
                            : AppText.of(context).detailPlay),
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => _play(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: GhostButton(
                          label: AppText.of(context).detailFavorites,
                          icon: Icons.add_rounded,
                          onPressed: () {},
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: GhostButton(
                          label: AppText.of(context).detailWatchParty,
                          icon: Icons.groups_rounded,
                          onPressed: () => showVoiceRoomSheet(context, ref),
                        ),
                      ),
                    ],
                  ),
                  if (item.nowPlaying != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _sectionTitle(AppText.of(context).detailNowShowing),
                    const SizedBox(height: AppSpacing.sm),
                    Text(item.nowPlaying!,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 15)),
                  ],
                  if (item.description != null) ...[
                    const SizedBox(height: AppSpacing.xl),
                    _sectionTitle(AppText.of(context).detailStory),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                  // Series: seasons + episodes (the episode owns the stream).
                  if (_isSeries) EpisodesSection(series: item),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      );

  /// Kind name (live/movie/series) in the current language.
  String _kindLabel(BuildContext context, MediaKind kind) {
    final t = AppText.of(context);
    return switch (kind) {
      MediaKind.live => t.kindLive,
      MediaKind.movie => t.kindMovie,
      MediaKind.series => t.kindSeries,
    };
  }

  Widget _metaPill(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
        child: Text(t,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      );

  Widget _circleIcon(IconData icon, VoidCallback onTap) => Material(
        color: Colors.black.withValues(alpha: 0.4),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      );
}
