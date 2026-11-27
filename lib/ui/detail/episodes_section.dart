import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/episode.dart';
import '../../data/models/media_item.dart';
import '../../data/models/series_info.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../player/player_screen.dart';
import '../widgets/loading.dart';
import '../widgets/poster_image.dart';

/// A series' seasons/episodes section — the episode owns the stream (played
/// by episode_id).
class EpisodesSection extends ConsumerStatefulWidget {
  const EpisodesSection({super.key, required this.series});

  final MediaItem series;

  @override
  ConsumerState<EpisodesSection> createState() => _EpisodesSectionState();
}

class _EpisodesSectionState extends ConsumerState<EpisodesSection> {
  int? _season;

  void _play(Episode ep) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => PlayerScreen(
          item: ep.toPlayable(
            seriesTitle: widget.series.title,
            fallbackPoster: widget.series.posterUrl,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(seriesInfoProvider(widget.series.id));

    return async.when(
      loading: () => const SizedBox(height: 120, child: LoadingView()),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: ErrorView(
          message: AppText.of(context).detailEpisodesError,
          onRetry: () => ref.invalidate(seriesInfoProvider(widget.series.id)),
        ),
      ),
      data: (info) {
        if (info.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(AppText.of(context).detailNoEpisodes,
                style: const TextStyle(color: AppColors.textTertiary)),
          );
        }
        final seasons = info.seasonNumbers;
        final current = seasons.contains(_season) ? _season! : seasons.first;
        final list = info.ofSeason(current);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Text(AppText.of(context).detailEpisodesCount(list.length),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                if (seasons.length > 1) _seasonPicker(info, seasons, current),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            for (final ep in list) _episodeTile(ep),
          ],
        );
      },
    );
  }

  Widget _seasonPicker(SeriesInfo info, List<int> seasons, int current) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: DropdownButton<int>(
        value: current,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        icon: const Icon(Icons.expand_more_rounded, color: AppColors.brand),
        style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        items: [
          for (final s in seasons)
            DropdownMenuItem(
                value: s,
                child: Text(info.seasonName(s) ??
                    AppText.of(context).detailSeason(s))),
        ],
        onChanged: (v) => setState(() => _season = v),
      ),
    );
  }

  Widget _episodeTile(Episode ep) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: () => _play(ep),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  height: 62,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      PosterImage(
                        url: ep.cover ?? widget.series.posterUrl,
                        seed: ep.id,
                        borderRadius: AppRadii.sm,
                      ),
                      const Center(
                        child: Icon(Icons.play_circle_fill_rounded,
                            color: Colors.white70, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ep.title.isEmpty
                            ? ep.label
                            : '${ep.label} · ${ep.title}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      if (ep.durationSecs != null)
                        Text(
                            AppText.of(context).detailEpisodeMinutes(
                                (ep.durationSecs! / 60).round()),
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 11)),
                      if (ep.plot != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            ep.plot!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
