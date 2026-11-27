import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/media_item.dart';
import '../../widgets/badges.dart';
import '../../widgets/poster_image.dart';

/// Vertical poster card (2:3) — for movies/series/channels.
class PosterCard extends StatelessWidget {
  const PosterCard({
    super.key,
    required this.item,
    required this.onTap,
    this.width = 124,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded makes the image absorb any leftover space → overflow is
            // impossible (no yellow stripe).
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // No Hero (IndexedStack keeps tabs alive, so tags would
                  // repeat).
                  item.isLive
                      // Channel logos: contain on a dark background (no crop).
                      // Padding scales with the card size, otherwise it would
                      // squeeze the logo in a compact card.
                      ? PosterImage(
                          url: item.posterUrl,
                          seed: item.id,
                          fit: BoxFit.contain,
                          backgroundColor: AppColors.surfaceElevated,
                          padding: EdgeInsets.all(width < 110 ? 8 : 14),
                        )
                      : PosterImage(url: item.posterUrl, seed: item.id),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: item.isLive
                        ? const LiveBadge()
                        : (item.rating != null
                            ? RatingChip(item.rating!)
                            : const SizedBox.shrink()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            if (item.nowPlaying != null || item.year != null)
              Text(
                item.nowPlaying ?? item.year!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal card (16:9) for the "Continue watching" list, with a progress
/// bar and a play button.
class ContinueCard extends StatelessWidget {
  const ContinueCard({
    super.key,
    required this.item,
    required this.onTap,
    this.width = 220,
  });

  final MediaItem item;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PosterImage(
                    url: item.backdropUrl ?? item.posterUrl,
                    seed: item.id,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.5),
                        ],
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.play_circle_fill_rounded,
                        color: Colors.white, size: 44),
                  ),
                  if (item.progress != null)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: ProgressBar(item.progress!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
