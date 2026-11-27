import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import 'voice_room_sheet.dart';

/// Floating "you're in a room" pill — floats above **every** screen,
/// including the player (needed during a watch party).
///
/// Two separate tap targets:
/// - Body (icon + count) → opens the room sheet (via the root Navigator).
/// - Mic icon → mute/unmute directly without opening the sheet.
///
/// **Dragging is free in both axes** and clamped inside the screen bounds
/// (follows the finger 1:1).
class VoiceRoomOverlay extends ConsumerStatefulWidget {
  const VoiceRoomOverlay({super.key});

  @override
  ConsumerState<VoiceRoomOverlay> createState() => _VoiceRoomOverlayState();
}

class _VoiceRoomOverlayState extends ConsumerState<VoiceRoomOverlay> {
  /// Absolute position (left, top). null = not set yet → place it at the
  /// bottom start.
  Offset? _pos;

  final _pillKey = GlobalKey();
  Size _size = const Size(118, 38); // initial guess, corrected after first paint

  static const _margin = 8.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  /// Measure the real size after layout so the clamping is accurate.
  void _measure() {
    final box = _pillKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !mounted) return;
    if ((box.size.width - _size.width).abs() < 0.5 &&
        (box.size.height - _size.height).abs() < 0.5) {
      return;
    }
    setState(() => _size = box.size);
  }

  /// Clamps the position inside the visible bounds (respecting safe areas).
  Offset _clamp(Offset p, Size screen, EdgeInsets pad) {
    final maxX = (screen.width - _size.width - _margin).clamp(_margin, double.infinity);
    final maxY = (screen.height - pad.bottom - _size.height - _margin)
        .clamp(pad.top + _margin, double.infinity);
    return Offset(
      p.dx.clamp(_margin, maxX),
      p.dy.clamp(pad.top + _margin, maxY),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(voiceRoomProvider);
    if (!s.inRoom) return const SizedBox.shrink();

    final media = MediaQuery.of(context);
    final screen = media.size;
    final pad = media.padding;
    final speaking = s.members.any((m) => m.speaking && !m.isLocal);
    final sheetOpen = ref.watch(voiceSheetOpenProvider);

    // Default position: bottom-right of the screen (above the tab bar).
    _pos ??= Offset(
      screen.width - _size.width - 12,
      screen.height - pad.bottom - _size.height - 96,
    );
    // Re-clamp on every build — handles rotation (the player is landscape).
    final pos = _clamp(_pos!, screen, pad);

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        // Free pan in both axes — follows the finger exactly (RTL-agnostic).
        onPanUpdate: (d) => setState(
          () => _pos = _clamp(pos + d.delta, screen, pad),
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          key: _pillKey,
          decoration: BoxDecoration(
            // Lighter color while the sheet is open — a clear toggle-state cue.
            color: sheetOpen ? AppColors.brand : AppColors.surfaceAccent,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(
              color: speaking
                  ? AppColors.success
                  : Colors.white.withValues(alpha: 0.14),
              width: speaking ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Body → toggle the room sheet (open/close) — works even
                // inside the player.
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    toggleVoiceRoomSheet(context, ref);
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 9, 8, 9),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Icon shows what the next tap will do.
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Icon(
                            sheetOpen
                                ? Icons.close_rounded
                                : Icons.groups_rounded,
                            key: ValueKey(sheetOpen),
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${s.members.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(width: 1, height: 18, color: Colors.white24),
                // Mic → mute/unmute directly.
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    ref.read(voiceRoomProvider.notifier).toggleMic();
                  },
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(9, 9, 12, 9),
                    child: Icon(
                      s.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                      size: 18,
                      color: s.micOn ? AppColors.success : Colors.white70,
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
