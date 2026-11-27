import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../detail/detail_screen.dart';
import '../home/widgets/poster_card.dart';

/// Search **scoped to one section** (channels, movies or series) — never
/// mixes types.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, required this.kind});

  final MediaKind kind;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  ProviderListenable<AsyncValue<List<MediaItem>>> get _source =>
      switch (widget.kind) {
        MediaKind.live => liveChannelsProvider,
        MediaKind.movie => moviesProvider,
        MediaKind.series => seriesProvider,
      };

  String get _scopeLabel => switch (widget.kind) {
        MediaKind.live => AppText.of(context).searchScopeLive,
        MediaKind.movie => AppText.of(context).navMovies,
        MediaKind.series => AppText.of(context).navSeries,
      };

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final all = ref.watch(_source).valueOrNull ?? const <MediaItem>[];
    final results =
        q.isEmpty ? const <MediaItem>[] : all.where((m) => m.title.toLowerCase().contains(q)).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: _searchField(),
      ),
      body: q.isEmpty
          ? _hint(AppText.of(context).searchHint(_scopeLabel))
          : results.isEmpty
              ? _hint(AppText.of(context).searchNoResults(_query, _scopeLabel))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                      child: Text(
                          AppText.of(context)
                              .searchResults(results.length, _scopeLabel),
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 13)),
                    ),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.fromLTRB(
                            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          mainAxisSpacing: AppSpacing.lg,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.52,
                        ),
                        itemCount: results.length,
                        itemBuilder: (context, i) => PosterCard(
                          item: results[i],
                          width: double.infinity,
                          onTap: () => openDetail(context, results[i]),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md),
      child: TextField(
        controller: _ctrl,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: (v) => setState(() => _query = v),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: AppText.of(context).searchHint(_scopeLabel),
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          prefixIcon:
              const Icon(Icons.search_rounded, color: AppColors.textTertiary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: AppColors.textTertiary),
                  onPressed: () {
                    _ctrl.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _hint(String text) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.textTertiary, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(text, style: const TextStyle(color: AppColors.textTertiary)),
        ],
      ),
    );
  }
}
