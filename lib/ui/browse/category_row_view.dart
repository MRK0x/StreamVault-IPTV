import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/category_group.dart';
import '../../l10n/app_text.dart';
import '../detail/detail_screen.dart';
import '../home/widgets/poster_card.dart';
import '../widgets/items_grid_screen.dart';

/// A group (category) row: the name + "Show more" + a horizontal preview row.
class CategoryRowView extends StatelessWidget {
  const CategoryRowView({super.key, required this.group, this.previewCount = 15});

  final CategoryGroup group;
  final int previewCount;

  /// Channels are square logos, not 2:3 posters — so their card is smaller and
  /// shorter; otherwise the small logo would sit inside a tall empty rectangle
  /// and waste space.
  bool get _isLive => group.items.isNotEmpty && group.items.first.isLive;

  double get _cardWidth => _isLive ? 92 : 124;

  /// Row height = the image + the name line (~36).
  double get _rowHeight => _isLive ? 128 : 244;

  /// Display name for the group — a localized "Other" for the unknown
  /// categories group.
  String _title(BuildContext context) =>
      group.id == kOtherCategoryId ? AppText.of(context).browseOther : group.name;

  void _showAll(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) =>
            ItemsGridScreen(title: _title(context), items: group.items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = group.items.take(previewCount).toList();
    final hasMore = group.items.length > preview.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _title(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showAll(context),
                child: Row(
                  children: [
                    Text(AppText.of(context).browseSeeMore,
                        style: const TextStyle(
                            color: AppColors.brand,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const Icon(Icons.chevron_left_rounded,
                        color: AppColors.brand, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: _rowHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: preview.length + (hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, i) {
              if (hasMore && i == preview.length) {
                return _moreTile(context);
              }
              final item = preview[i];
              return PosterCard(
                item: item,
                width: _cardWidth,
                onTap: () => openDetail(context, item),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _moreTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAll(context),
      child: SizedBox(
        width: _cardWidth,
        child: Column(
          children: [
            // Expanded matches the height of the neighbouring cards whatever
            // the size (instead of a fixed ratio that overflows in the short
            // channels row).
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.grid_view_rounded,
                        color: AppColors.brand, size: _isLive ? 22 : 28),
                    const SizedBox(height: 6),
                    Text(AppText.of(context).browseSeeAll,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: _isLive ? 11 : 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
