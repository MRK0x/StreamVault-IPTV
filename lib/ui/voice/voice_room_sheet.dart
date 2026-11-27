import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../../voice/voice_api.dart' show VoiceErrorCode;
import '../../voice/voice_avatar.dart';
import '../../voice/voice_room_state.dart';
import '../../voice/watch_party_manager.dart';
import '../app.dart';
import '../player/player_screen.dart';
import '../widgets/brand_button.dart';
import '../widgets/glass_card.dart';
import '../widgets/poster_image.dart';
import '../widgets/upper_case_formatter.dart';

/// Is the room sheet open right now? (to toggle open/close from the floating
/// icon)
final voiceSheetOpenProvider = StateProvider<bool>((ref) => false);

/// Translates a voice error code into text for the current language.
String _voiceErrorText(BuildContext context, VoiceErrorCode code) {
  final t = AppText.of(context);
  return switch (code) {
    VoiceErrorCode.invalidResponse => t.voiceErrInvalidResponse,
    VoiceErrorCode.network => t.voiceErrNetwork,
    VoiceErrorCode.kicked => t.voiceErrKicked,
    VoiceErrorCode.notFound => t.voiceErrNotFound,
    VoiceErrorCode.unreachable => t.voiceErrUnreachable,
    VoiceErrorCode.joinFailed => t.voiceErrJoinFailed,
    VoiceErrorCode.micDenied => t.voiceErrMicDenied,
  };
}

/// Opens the room sheet if it's closed, and closes it if it's open.
///
/// It opens on the **root** Navigator so it appears above everything (including
/// the player), and because the floating icon calls it from a `builder` whose
/// context has no Navigator.
void toggleVoiceRoomSheet(BuildContext context, WidgetRef ref) {
  if (ref.read(voiceSheetOpenProvider)) {
    rootNavigatorKey.currentState?.pop();
    return;
  }
  showVoiceRoomSheet(context, ref);
}

void showVoiceRoomSheet(BuildContext context, WidgetRef ref) {
  final ctx = rootNavigatorKey.currentContext ?? context;
  ref.read(voiceSheetOpenProvider.notifier).state = true;
  showModalBottomSheet(
    context: ctx,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _VoiceRoomSheet(),
    // Reset however it was closed (button/drag/backdrop tap/navigation).
  ).whenComplete(() {
    if (ref.context.mounted) {
      ref.read(voiceSheetOpenProvider.notifier).state = false;
    }
  });
}

class _VoiceRoomSheet extends ConsumerWidget {
  const _VoiceRoomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(voiceRoomProvider);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _grabber(),
            if (s.error case final err?) ...[
              Text(_voiceErrorText(context, err),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.live, fontSize: 13)),
              const SizedBox(height: AppSpacing.md),
            ],
            if (s.inRoom) const _InRoomView() else const _JoinView(),
          ],
        ),
      ),
    );
  }

  Widget _grabber() => Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(AppRadii.pill),
        ),
      );
}

/// Create a room or join with a code.
class _JoinView extends ConsumerStatefulWidget {
  const _JoinView();

  @override
  ConsumerState<_JoinView> createState() => _JoinViewState();
}

class _JoinViewState extends ConsumerState<_JoinView> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(voiceRoomProvider);
    final busy = s.isConnecting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: AppColors.brand),
            const SizedBox(width: 8),
            Text(AppText.of(context).voiceRoomTitle,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _avatarPicker(),
        const SizedBox(height: AppSpacing.lg),
        _field(
          _codeCtrl,
          AppText.of(context).voiceEnterCodeHint,
          Icons.vpn_key_rounded,
          // The code is normalised (trim + upper) in the API layer too.
          formatters: [const UpperCaseFormatter()],
        ),
        const SizedBox(height: AppSpacing.md),
        BrandButton(
          label: AppText.of(context).voiceJoin,
          icon: Icons.login_rounded,
          loading: busy,
          onPressed: () {
            final c = _codeCtrl.text.trim();
            if (c.isEmpty) return;
            FocusScope.of(context).unfocus();
            ref.read(voiceRoomProvider.notifier).joinRoom(c);
          },
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Row(children: [
            const Expanded(child: Divider(color: AppColors.divider)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(AppText.of(context).voiceOr,
                  style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ),
            const Expanded(child: Divider(color: AppColors.divider)),
          ]),
        ),
        _field(_nameCtrl, AppText.of(context).voiceNewRoomNameHint,
            Icons.meeting_room_rounded),
        const SizedBox(height: AppSpacing.md),
        GhostButton(
          label: AppText.of(context).voiceCreateRoom,
          icon: Icons.add_rounded,
          onPressed: busy
              ? null
              : () {
                  final n = _nameCtrl.text.trim();
                  if (n.isEmpty) return;
                  FocusScope.of(context).unfocus();
                  ref.read(voiceRoomProvider.notifier).createRoom(name: n);
                },
        ),
      ],
    );
  }

  /// Avatar picker grid before joining — 7 per row × 3 rows (21 images).
  ///
  /// The choice is saved locally and sent on the next join; the server bakes
  /// it into the token so it's fixed for the whole session (changing it
  /// inside a room applies to the next room).
  Widget _avatarPicker() {
    final selected = ref.watch(voiceAvatarProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppText.of(context).voicePickAvatar,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 10)),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          children: [
            for (int i = 0; i < VoiceAvatar.count; i++)
              _avatarTile(i, selected == i),
          ],
        ),
      ],
    );
  }

  Widget _avatarTile(int index, bool selected) {
    return GestureDetector(
      onTap: () => ref.read(voiceAvatarProvider.notifier).select(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.brand : Colors.transparent,
            width: 2,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(VoiceAvatar.assetOf(index), fit: BoxFit.cover),
                // Unselected ones are dimmed (~45%) so the selected one
                // stands out — matches Android.
                if (!selected)
                  Container(
                      color: AppColors.canvas.withValues(alpha: 0.45)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String hint,
    IconData icon, {
    List<TextInputFormatter>? formatters,
  }) {
    return TextField(
      controller: c,
      inputFormatters: formatters,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textTertiary),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

// (UpperCaseFormatter used to live here — moved to
// widgets/upper_case_formatter.dart so the room code and subscription code can
// share it.)

/// "Watching now" — cards of what members are watching + a follow button.
class _WatchingList extends ConsumerWidget {
  const _WatchingList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wp = ref.watch(watchPartyProvider);
    final me = ref.watch(voiceRoomProvider.notifier).localIdentity;
    // Don't show my own card.
    final others = wp.watching.where((e) => e.identity != me).toList();
    if (others.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Text(AppText.of(context).voiceWatchingNow,
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        for (final e in others) _card(context, ref, wp, e),
      ],
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, WatchPartyManager wp,
      WatchingEntry e) {
    final following = wp.followingIdentity == e.identity;
    final info = e.info;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: following
            ? Border.all(color: AppColors.brand.withValues(alpha: 0.6))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 54,
            height: 34,
            child: PosterImage(
              url: info.image ?? '',
              seed: info.contentKey,
              borderRadius: AppRadii.sm,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700),
                ),
                Row(
                  children: [
                    if (info.isLive)
                      Text(AppText.of(context).voiceLive,
                          style: const TextStyle(
                              color: AppColors.live, fontSize: 11))
                    else
                      Text(_fmt(info.positionMs),
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 11)),
                    const SizedBox(width: 6),
                    Icon(
                      info.playing
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              if (following) {
                wp.unfollow();
                return;
              }
              // Start following: open what they're watching on our device.
              final item = await ref.read(contentResolverProvider).resolve(info);
              if (!context.mounted) return;
              if (item == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(AppText.of(context).voiceContentUnavailable)),
                );
                return;
              }
              wp.follow(e.identity);
              Navigator.pop(context); // close the sheet
              Navigator.of(context).push(
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => PlayerScreen(item: item),
                ),
              );
            },
            child: Text(
              following
                  ? AppText.of(context).voiceUnfollow
                  : AppText.of(context).voiceFollow,
              style: TextStyle(
                color: following ? AppColors.textTertiary : AppColors.brand,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _fmt(int ms) {
    final d = Duration(milliseconds: ms);
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

/// Inside the room: code + participants + mic + (admin: kick/end).
class _InRoomView extends ConsumerWidget {
  const _InRoomView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(voiceRoomProvider);
    final ctrl = ref.read(voiceRoomProvider.notifier);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.groups_rounded, color: AppColors.brand),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                s.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
              ),
            ),
            if (s.isAdmin)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brand.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(AppText.of(context).voiceAdmin,
                    style: const TextStyle(
                        color: AppColors.brand,
                        fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _codeRow(context, s.code),
        const _WatchingList(),
        const SizedBox(height: AppSpacing.lg),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: ListView(
            shrinkWrap: true,
            children: [for (final m in s.members) _memberTile(context, ref, m, s)],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: BrandButton(
                label: s.micOn
                    ? AppText.of(context).voiceMuteMic
                    : AppText.of(context).voiceUnmuteMic,
                icon: s.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                onPressed: ctrl.toggleMic,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GhostButton(
                label: s.isAdmin
                    ? AppText.of(context).voiceEndRoom
                    : AppText.of(context).voiceLeave,
                icon: Icons.logout_rounded,
                onPressed: s.busy
                    ? null
                    : () async {
                        if (s.isAdmin) {
                          await ctrl.endRoom();
                        } else {
                          await ctrl.leave();
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _codeRow(BuildContext context, String code) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Text(AppText.of(context).voiceCode,
              style:
                  const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              code,
              style: const TextStyle(
                color: AppColors.brandStrong,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded,
                color: AppColors.textTertiary, size: 18),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppText.of(context).voiceCodeCopied)),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Avatar bubble — 32 diameter; the green ring appears with a 150ms color
  /// fade.
  ///
  /// The ring is **always reserved** (transparent when not speaking) so the
  /// size never changes or flickers, only the color animates — matches Android.
  /// The images are artwork: no tinting, and they fill the circle with cover.
  Widget _avatarBubble(int avatar, bool speaking) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: speaking ? AppColors.success : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Container(
            color: AppColors.surfaceElevated,
            child: Image.asset(VoiceAvatar.assetOf(avatar), fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }

  Widget _memberTile(
      BuildContext context, WidgetRef ref, RoomMember m, VoiceRoomState s) {
    // Kick: admins only, and never themselves.
    final canKick = s.isAdmin && !m.isLocal;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: _avatarBubble(m.avatar, m.speaking),
      title: Row(
        children: [
          Flexible(
            child: Text(
              m.isLocal ? AppText.of(context).voiceYouSuffix(m.name) : m.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
          // The badge comes from this member's metadata ⇒ everyone sees it on
          // the host.
          if (m.isAdmin)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: Tooltip(
                message: AppText.of(context).voiceAdmin,
                child: const Icon(Icons.admin_panel_settings,
                    color: AppColors.brand, size: 16),
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            m.micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
            size: 18,
            color: m.micOn ? AppColors.success : AppColors.textTertiary,
          ),
          if (canKick)
            IconButton(
              icon: const Icon(Icons.person_remove_rounded,
                  color: AppColors.live, size: 18),
              onPressed: s.busy ? null : () => _confirmKick(context, ref, m),
            ),
        ],
      ),
    );
  }

  /// Kicking is **permanent** — confirm before doing it.
  void _confirmKick(BuildContext context, WidgetRef ref, RoomMember m) {
    showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(AppText.of(context).voiceKickConfirmTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          AppText.of(context).voiceKickConfirmBody(m.name),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(AppText.of(context).commonCancel,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              ref.read(voiceRoomProvider.notifier).kick(m.identity);
            },
            child: Text(AppText.of(context).voiceKick,
                style: const TextStyle(color: AppColors.live)),
          ),
        ],
      ),
    );
  }
}
