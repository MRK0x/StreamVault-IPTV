import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../../../data/models/content_row.dart';
import '../../detail/detail_screen.dart';
import 'poster_card.dart';

/// Titled horizontal content row (Netflix-style).
class ContentRowView extends StatelessWidget {
  const ContentRowView({super.key, required this.row});

  final ContentRow row;

  @override
  Widget build(BuildContext context) {
    final bool wide = row.isContinueWatching;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              Text(
                row.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Icon(Icons.chevron_left_rounded,
                  color: AppColors.textTertiary, size: 22),
            ],
          ),
        ),
        SizedBox(
          height: wide ? 168 : 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: row.items.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              final item = row.items[i];
              return wide
                  ? ContinueCard(
                      item: item, onTap: () => openDetail(context, item))
                  : PosterCard(
                      item: item, onTap: () => openDetail(context, item));
            },
          ),
        ),
      ],
    );
  }
}
