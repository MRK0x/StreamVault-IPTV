import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/category_group.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../search/search_screen.dart';
import '../widgets/items_grid_screen.dart';
import '../widgets/loading.dart';

/// Drill-down live TV browsing: a list of categories (with counts) → tapping
/// one opens its channels.
///
/// Replaces the horizontal-rows screen for live only; movies/series keep
/// their layout.
class LiveCategoriesScreen extends ConsumerStatefulWidget {
  const LiveCategoriesScreen({super.key});

  @override
  ConsumerState<LiveCategoriesScreen> createState() =>
      _LiveCategoriesScreenState();
}

class _LiveCategoriesScreenState extends ConsumerState<LiveCategoriesScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Category display name: "Other" for unknown ones, otherwise the Arabic
  /// part only (without the English).
  String _title(BuildContext context, CategoryGroup g) => g.id == kOtherCategoryId
      ? AppText.of(context).browseOther
      : cleanLiveCategoryName(g.name);

  List<CategoryGroup> _filter(List<CategoryGroup> groups) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return groups;
    return groups
        .where((g) => _title(context, g).toLowerCase().contains(q))
        .toList();
  }

  void _openCategory(String title, List<MediaItem> items) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (_) => ItemsGridScreen(title: title, items: items),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    final async = ref.watch(liveGroupsProvider);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          floating: true,
          toolbarHeight: 48,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(
                    builder: (_) => const SearchScreen(kind: MediaKind.live)),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        ...async.when(
          loading: () => const [
            SliverFillRemaining(hasScrollBody: false, child: LoadingView()),
          ],
          error: (e, _) => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: '$e',
                onRetry: () => ref.invalidate(liveGroupsProvider),
              ),
            ),
          ],
          data: (groups) {
            if (groups.isEmpty) {
              return [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(message: t.browseNoContent),
                ),
              ];
            }
            final filtered = _filter(groups);
            final total =
                groups.fold<int>(0, (sum, g) => sum + g.items.length);
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: _categorySearch(t),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                sliver: SliverList.list(children: [
                  // "All" — every channel together (shown only when no search
                  // is active).
                  if (_query.trim().isEmpty)
                    _row(
                      icon: Icons.grid_view_rounded,
                      label: t.browseAllChannels,
                      count: total,
                      onTap: () => _openCategory(
                        t.browseAllChannels,
                        [for (final g in groups) ...g.items],
                      ),
                    ),
                  for (final g in filtered)
                    _row(
                      icon: Icons.folder_rounded,
                      label: _title(context, g),
                      count: g.items.length,
                      onTap: () => _openCategory(_title(context, g), g.items),
                    ),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xl),
                      child: Center(
                        child: Text(t.browseNoContent,
                            style: const TextStyle(
                                color: AppColors.textTertiary, fontSize: 14)),
                      ),
                    ),
                ]),
              ),
            ];
          },
        ),
      ],
    );
  }

  Widget _categorySearch(AppText t) {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: t.browseSearchCategories,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textTertiary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _row({
    required IconData icon,
    required String label,
    required int count,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: 14),
            child: Row(
              children: [
                Icon(icon, color: AppColors.brand, size: 22),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                // Channel count — prominent but subtle.
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.brand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                  ),
                  child: Text('$count',
                      style: const TextStyle(
                          color: AppColors.brandStrong,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_left_rounded,
                    color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
