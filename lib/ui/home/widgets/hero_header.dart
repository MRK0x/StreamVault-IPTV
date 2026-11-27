import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/media_item.dart';
import '../../../l10n/app_text.dart';
import '../../detail/detail_screen.dart';
import '../../widgets/badges.dart';
import '../../widgets/brand_button.dart';
import '../../widgets/poster_image.dart';

/// Top hero with featured content + the brand gradient.
class HeroHeader extends StatelessWidget {
  const HeroHeader({super.key, required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 460,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PosterImage(
            url: item.backdropUrl ?? item.posterUrl,
            seed: 'hero_${item.id}',
            borderRadius: 0,
          ),
          // Hero gradient (HeroTop → HeroBottom)
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.heroTop, Colors.transparent, AppColors.heroBottom],
                stops: [0, 0.5, 1],
              ),
            ),
          ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (item.categoryName != null)
                  Text(
                    item.categoryName!,
                    style: const TextStyle(
                      color: AppColors.brandStrong,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (item.rating != null)
                  RatingChip(item.rating!),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: BrandButton(
                        label: AppText.of(context).homePlay,
                        icon: Icons.play_arrow_rounded,
                        onPressed: () => openDetail(context, item),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: GhostButton(
                        label: AppText.of(context).homeDetails,
                        icon: Icons.info_outline_rounded,
                        onPressed: () => openDetail(context, item),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
