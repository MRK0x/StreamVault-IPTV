import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../l10n/app_text.dart';

/// Red "Live" badge with a pulsing dot.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.live,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.circle, size: 7, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            AppText.of(context).badgeLive,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rating badge with a star.
class RatingChip extends StatelessWidget {
  const RatingChip(this.rating, {super.key});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin progress bar for the "Continue watching" list.
class ProgressBar extends StatelessWidget {
  const ProgressBar(this.value, {super.key});

  final double value; // 0..1

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 4,
        backgroundColor: Colors.white.withValues(alpha: 0.18),
        valueColor: const AlwaysStoppedAnimation(AppColors.brand),
      ),
    );
  }
}
