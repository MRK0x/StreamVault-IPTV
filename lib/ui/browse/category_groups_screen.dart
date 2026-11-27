import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/category_group.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../search/search_screen.dart';
import '../widgets/loading.dart';
import 'category_row_view.dart';

/// Browse screen grouped by category (channels/movies/series) — each group
/// under its name + "see more".
class CategoryGroupsScreen extends ConsumerWidget {
  const CategoryGroupsScreen({
    super.key,
    required this.provider,
    required this.kind,
  });

  /// Typed as FutureProvider (not ProviderListenable) so it can be
  /// invalidated on retry.
  final FutureProvider<List<CategoryGroup>> provider;
  final MediaKind kind; // the search scope for this tab

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return CustomScrollView(
      slivers: [
        // No large title: the tab bar at the bottom already says where we
        // are, so a title would be repetition eating space. The search button
        // stays in a compact floating bar.
        SliverAppBar(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          floating: true,
          toolbarHeight: 48,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => SearchScreen(kind: kind)),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        ...async.when(
          data: (groups) => [
            if (groups.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(message: AppText.of(context).browseNoContent),
              )
            else
              SliverList.builder(
                itemCount: groups.length,
                itemBuilder: (_, i) => CategoryRowView(group: groups[i]),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
          loading: () => const [
            SliverFillRemaining(hasScrollBody: false, child: LoadingView()),
          ],
          // Don't show the raw exception text (English and technical) — an
          // Arabic message + retry.
          error: (e, _) => [
            SliverFillRemaining(
              hasScrollBody: false,
              child: ErrorView(
                message: AppText.of(context).browseLoadFailed,
                onRetry: () => ref.invalidate(provider),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
