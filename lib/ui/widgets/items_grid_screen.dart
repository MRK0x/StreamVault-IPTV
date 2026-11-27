import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../detail/detail_screen.dart';
import '../home/widgets/poster_card.dart';

/// Full grid of a single category's items — used for "See all" and for a
/// chosen category's channels.
///
/// Type-aware: channels are square logos (not tall posters), movies/series
/// are 2:3 posters. Has an inline search that appears when there is a lot
/// of content.
class ItemsGridScreen extends StatefulWidget {
  const ItemsGridScreen({super.key, required this.title, required this.items});

  final String title;
  final List<MediaItem> items;

  @override
  State<ItemsGridScreen> createState() => _ItemsGridScreenState();
}

class _ItemsGridScreenState extends State<ItemsGridScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  bool get _isLive =>
      widget.items.isNotEmpty && widget.items.first.kind == MediaKind.live;

  /// Search only shows when worthwhile (a small category doesn't need it).
  bool get _searchable => widget.items.length > 12;

  List<MediaItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.items;
    return widget.items
        .where((m) => m.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.canvas,
            surfaceTintColor: Colors.transparent,
            title:
                Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          if (_searchable)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: _searchField(),
              ),
            ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(AppText.of(context).browseNoContent,
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 14)),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  // Channels are smaller with more per row (square logo);
                  // movies are wider.
                  maxCrossAxisExtent: _isLive ? 108 : 150,
                  mainAxisSpacing: AppSpacing.lg,
                  crossAxisSpacing: AppSpacing.md,
                  // Channel: square image + name line. Movie: tall 2:3 poster.
                  childAspectRatio: _isLive ? 0.82 : 0.52,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, i) => PosterCard(
                    item: items[i],
                    width: double.infinity,
                    onTap: () => openDetail(context, items[i]),
                  ),
                  childCount: items.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _searchCtrl,
      onChanged: (v) => setState(() => _query = v),
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: AppText.of(context).browseSearchChannels,
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
}
