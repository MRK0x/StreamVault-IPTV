import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme.dart';
import '../../data/models/media_item.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../browse/category_groups_screen.dart';
import '../browse/live_categories_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';

/// The main shell — IndexedStack + an iOS-style frosted bottom tab bar.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  /// Tabs the user has visited — built lazily.
  /// (IndexedStack builds all children immediately; with a 35k-item catalog
  ///  that fired the channels+movies+series fetches together at startup →
  ///  very slow.)
  final Set<int> _visited = {0};

  Widget _pageAt(BuildContext context, int i) {
    return switch (i) {
      0 => const HomeScreen(),
      // Live: categories → channels drill-down (movies/series stay as rows).
      1 => const LiveCategoriesScreen(),
      2 => CategoryGroupsScreen(
          provider: movieGroupsProvider, kind: MediaKind.movie),
      3 => CategoryGroupsScreen(
          provider: seriesGroupsProvider, kind: MediaKind.series),
      _ => const SettingsScreen(),
    };
  }

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _index = i;
      _visited.add(i); // built (and fetched) on first visit only
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    final tabs = <_TabSpec>[
      _TabSpec(t.navHome, Icons.home_rounded, Icons.home_outlined),
      _TabSpec(t.navLive, Icons.live_tv_rounded, Icons.live_tv_outlined),
      _TabSpec(t.navMovies, Icons.movie_rounded, Icons.movie_outlined),
      _TabSpec(t.navSeries, Icons.tv_rounded, Icons.tv_outlined),
      _TabSpec(t.navAccount, Icons.person_rounded, Icons.person_outline_rounded),
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.canvas,
      body: IndexedStack(
        index: _index,
        children: [
          for (int i = 0; i < tabs.length; i++)
            _visited.contains(i) ? _pageAt(context, i) : const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _FrostedTabBar(
        tabs: tabs,
        index: _index,
        onSelect: _select,
      ),
    );
  }
}

class _TabSpec {
  const _TabSpec(this.label, this.active, this.inactive);
  final String label;
  final IconData active;
  final IconData inactive;
}

/// A **floating** nav bar with fully rounded edges — the active tab is a pill
/// with icon + label, the rest are icons only. iOS-style frosted, in the brand
/// colors.
class _FrostedTabBar extends StatelessWidget {
  const _FrostedTabBar({
    required this.tabs,
    required this.index,
    required this.onSelect,
  });

  final List<_TabSpec> tabs;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      // Side + bottom margin make it float above the home indicator.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.xl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              height: 64,
              alignment: Alignment.center, // centers the tab row vertically
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppRadii.xl),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: LayoutBuilder(
                builder: (context, c) {
                  // Each tab's width derives from its "activeness" s∈[0,1];
                  // s of two adjacent tabs always sums to 1, so the total width
                  // is constant = the inner width ⇒ never overflows however the
                  // pill slides.
                  const wInactive = 46.0;
                  final wActive =
                      (c.maxWidth - wInactive * (tabs.length - 1))
                          .clamp(120.0, c.maxWidth);
                  // TweenAnimationBuilder animates the indicator smoothly from
                  // its current value to the new index — the pill slides, it
                  // doesn't jump.
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: index.toDouble()),
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOutCubic,
                    builder: (context, pos, _) {
                      return Row(
                        children: [
                          for (int i = 0; i < tabs.length; i++)
                            _AnimatedTab(
                              spec: tabs[i],
                              // 1 when matched, fading out for neighbours.
                              activeness:
                                  (1 - (i - pos).abs()).clamp(0.0, 1.0),
                              width: wInactive +
                                  (wActive - wInactive) *
                                      (1 - (i - pos).abs()).clamp(0.0, 1.0),
                              onTap: () => onSelect(i),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single tab with animated width and activeness — the pill expands and the
/// icon/label tint and fade in according to [activeness] (0 idle … 1 fully
/// active).
class _AnimatedTab extends StatelessWidget {
  const _AnimatedTab({
    required this.spec,
    required this.activeness,
    required this.width,
    required this.onTap,
  });

  final _TabSpec spec;
  final double activeness; // 0..1
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor =
        Color.lerp(AppColors.textTertiary, AppColors.brandStrong, activeness)!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      // No fixed height — the pill hugs its content, and the bar centers it
      // vertically.
      child: SizedBox(
        width: width,
        child: Center(
          child: Container(
            width: width - 6, // pill fills the slot minus a small margin
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
            decoration: BoxDecoration(
              // The brand background intensifies with activeness.
              color: AppColors.brand.withValues(alpha: 0.20 * activeness),
              borderRadius: BorderRadius.circular(AppRadii.pill),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(activeness > 0.5 ? spec.active : spec.inactive,
                    color: iconColor, size: 21),
                // The label widens and appears with activeness (clipped if
                // the slot is narrow).
                if (activeness > 0.02)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(start: 7),
                      child: Opacity(
                        opacity: activeness,
                        child: Text(
                          spec.label,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.clip,
                          style: const TextStyle(
                            color: AppColors.brandStrong,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
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
