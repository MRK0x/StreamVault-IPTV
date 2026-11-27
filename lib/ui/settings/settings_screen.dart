import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config.dart';
import '../../core/theme.dart';
import '../../l10n/app_text.dart';
import '../../l10n/format.dart';
import '../../state/locale_controller.dart';
import '../../state/providers.dart';
import '../subscription/activation_sheet.dart';
import 'devices_screen.dart';

/// Settings / My account — iOS-style cards (inset grouped lists).
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _syncing = false;

  /// Admin's Telegram link — set later; once filled in, its button appears
  /// automatically.
  static const String? _adminTelegram = null;

  String _appVersion = '—';

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _appVersion = 'v${info.version}');
  }

  /// Opens an external link (Telegram) in its app or the browser.
  Future<void> _openUrl(String url) async {
    final ok = await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppText.of(context).settingsLinkFailed)));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _syncAll() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final messenger = ScaffoldMessenger.of(context);
    final t = AppText.of(context);
    try {
      await syncAllCatalog(ref);
      messenger.showSnackBar(SnackBar(content: Text(t.syncDone)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.syncFailed(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  String _syncLabel(DateTime? t) =>
      t == null ? AppText.of(context).syncNever : timeAgo(context, t);

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    final auth = ref.watch(authControllerProvider);
    final username = auth.username ?? t.userFallback;

    return CustomScrollView(
      slivers: [
        SliverAppBar.large(
          backgroundColor: AppColors.canvas,
          surfaceTintColor: Colors.transparent,
          title: Text(t.navAccount),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _profileHeader(username),
                const SizedBox(height: AppSpacing.xl),
                _group(t.settingsSubscription,
                    [_planTile(username), _activateTile(), _devicesTile()]),
                const SizedBox(height: AppSpacing.lg),
                _group(t.settingsContent, [_syncTile()]),
                const SizedBox(height: AppSpacing.lg),
                // Removed: "Security & privacy" (nothing useful), "Playback"
                // (two options with no effect), and "Notifications" (always
                // on, no toggle).
                _group(t.settingsGeneral, [_languageTile()]),
                const SizedBox(height: AppSpacing.lg),
                _group(t.settingsAbout, [
                  _tile(Icons.info_outline_rounded, t.settingsVersion,
                      trailing: _appVersion, chevron: false),
                  _linkTile(
                    Icons.send_rounded,
                    t.settingsTelegramChannel,
                    subtitle: '@bugv4',
                    url: 'https://t.me/bugv4',
                  ),
                  // The admin icon appears automatically once the link above
                  // is set.
                  if (_adminTelegram case final admin?)
                    _linkTile(
                      Icons.support_agent_rounded,
                      t.settingsTelegramAdmin,
                      url: admin,
                    ),
                ]),
                const SizedBox(height: AppSpacing.xl),
                _logoutButton(context, ref),
                const SizedBox(height: AppSpacing.lg),
                Center(
                  child: Text(
                    AppConfig.useMockData
                        ? t.settingsDemoMode
                        : t.settingsConnectedTo(AppConfig.baseUrl),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileHeader(String username) {
    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.brand, AppColors.surfaceAccent],
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            username.characters.first.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(username,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            // The real status from the server (not static text).
            Builder(builder: (ctx) {
              final s = ref.watch(accountProvider).valueOrNull?.subscription;
              if (s == null) {
                return const Text('…',
                    style: TextStyle(
                        color: AppColors.textTertiary, fontSize: 13));
              }
              return Text(
                s.never
                    ? AppText.of(ctx).subscriptionNone
                    : s.expired
                        ? AppText.of(ctx).subscriptionExpired
                        : AppText.of(ctx).subscriptionActive,
                style: TextStyle(
                    color: s.expired ? AppColors.live : AppColors.success,
                    fontSize: 13),
              );
            }),
          ],
        ),
      ],
    );
  }

  /// Subscription — username + days remaining + expiry date (from
  /// `/api/me/`).
  ///
  /// The plan name (`subscription.plan`) is **deliberately not shown** to the
  /// user — it's an internal label.
  Widget _planTile(String username) {
    final t = AppText.of(context);
    final acc = ref.watch(accountProvider);
    return acc.when(
      loading: () => _tile(Icons.workspace_premium_rounded, username,
          trailing: '…', chevron: false),
      error: (_, _) => ListTile(
        leading: const Icon(Icons.workspace_premium_rounded,
            color: AppColors.brand, size: 22),
        title: Text(username,
            style: const TextStyle(
                color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
        subtitle: Text(t.settingsFetchFailedTapRetry,
            style: const TextStyle(color: AppColors.live, fontSize: 11)),
        onTap: () => ref.invalidate(accountProvider),
      ),
      data: (a) {
        final s = a.subscription;
        final days = s.daysLeft;
        final warn = s.expired || days <= 3;
        return ListTile(
          leading: Icon(Icons.workspace_premium_rounded,
              color: warn ? AppColors.warning : AppColors.brand, size: 22),
          title: Text(a.username.isEmpty ? username : a.username,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: Text(
            // A new account that never subscribed ≠ an expired subscription.
            s.never
                ? t.subscriptionNone
                : s.expired
                    ? t.planExpiredOn(shortDate(context, s.expiryDate))
                    : t.planRemaining(
                        t.planDays(days), shortDate(context, s.expiryDate)),
            style: TextStyle(
              color: warn ? AppColors.warning : AppColors.textTertiary,
              fontSize: 11,
            ),
          ),
          // No subscription or expired ⇒ tap to activate with a code (same
          // sheet as sign-up).
          trailing: (s.never || s.expired)
              ? const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textTertiary)
              : null,
          onTap: (s.never || s.expired)
              ? () => showActivationSheet(context)
              : null,
        );
      },
    );
  }

  /// "Activate with code" — **the same sheet as sign-up**, always available
  /// (renew/upgrade).
  Widget _activateTile() {
    return ListTile(
      leading: const Icon(Icons.redeem_rounded,
          color: AppColors.brand, size: 22),
      title: Text(AppText.of(context).activateFromSettings,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_left_rounded,
          color: AppColors.textTertiary),
      onTap: () => showActivationSheet(context),
    );
  }

  /// Linked devices — count vs. the plan limit; opens the management screen.
  Widget _devicesTile() {
    final devices = ref.watch(devicesProvider).valueOrNull;
    final max = ref.watch(accountProvider).valueOrNull?.subscription.maxDevices;
    final count = devices?.length;
    final over = count != null && max != null && count > max;

    final t = AppText.of(context);
    return ListTile(
      leading: Icon(Icons.devices_rounded,
          color: over ? AppColors.live : AppColors.brand, size: 22),
      title: Text(t.devicesTitle,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: over
          ? Text(t.devicesOverLimit,
              style: const TextStyle(color: AppColors.live, fontSize: 11))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count == null ? '…' : (max == null ? '$count' : '$count / $max'),
            style: TextStyle(
                color: over ? AppColors.live : AppColors.textTertiary,
                fontWeight: over ? FontWeight.w700 : FontWeight.w400),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left_rounded, color: AppColors.textTertiary),
        ],
      ),
      onTap: () => Navigator.of(context).push(
        CupertinoPageRoute(builder: (_) => const DevicesScreen()),
      ),
    );
  }

  /// Language — Arabic/English; the choice is saved and applied instantly to
  /// all screens.
  Widget _languageTile() {
    final current = ref.watch(localeProvider);
    return ListTile(
      leading: const Icon(Icons.language_rounded, color: AppColors.brand, size: 22),
      title: Text(AppText.of(context).settingsLanguage,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(localeName(current),
              style: const TextStyle(color: AppColors.textTertiary)),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_left_rounded, color: AppColors.textTertiary),
        ],
      ),
      onTap: _pickLanguage,
    );
  }

  Future<void> _pickLanguage() async {
    final current = ref.read(localeProvider);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(AppText.of(sheetCtx).settingsLanguage,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.md),
            for (final l in LocaleController.supported)
              ListTile(
                title: Text(localeName(l),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
                trailing: l.languageCode == current.languageCode
                    ? const Icon(Icons.check_rounded, color: AppColors.brand)
                    : null,
                onTap: () {
                  Navigator.pop(sheetCtx);
                  ref.read(localeProvider.notifier).set(l);
                },
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  /// An item that opens an external link (Telegram).
  Widget _linkTile(IconData icon, String label,
      {String? subtitle, required String url}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brand, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      subtitle: subtitle == null
          ? null
          : Text(subtitle,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 11)),
      trailing: const Icon(Icons.open_in_new_rounded,
          color: AppColors.textTertiary, size: 18),
      onTap: () => _openUrl(url),
    );
  }

  /// "Sync all" — the catalog is loaded once and kept locally; this button
  /// refreshes it.
  Widget _syncTile() {
    final t = AppText.of(context);
    final last = ref.watch(lastSyncProvider).valueOrNull;
    return ListTile(
      leading: _syncing
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.4, color: AppColors.brand),
            )
          : const Icon(Icons.sync_rounded, color: AppColors.brand, size: 22),
      title: Text(
        _syncing ? t.syncing : t.syncAll,
        style: const TextStyle(
            color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        _syncing ? t.syncingSubtitle : t.syncLastAt(_syncLabel(last)),
        style: const TextStyle(color: AppColors.textTertiary, fontSize: 11),
      ),
      trailing: _syncing
          ? null
          : const Icon(Icons.chevron_left_rounded,
              color: AppColors.textTertiary),
      onTap: _syncing ? null : _syncAll,
    );
  }

  Widget _group(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadii.lg),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1)
                  const Divider(
                      height: 1, indent: 52, color: AppColors.divider),
              ]
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(IconData icon, String label,
      {String? trailing, bool chevron = true}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.brand, size: 22),
      title: Text(label,
          style: const TextStyle(
              color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(color: AppColors.textTertiary)),
          if (chevron) ...[
            const SizedBox(width: 4),
            const Icon(Icons.chevron_left_rounded,
                color: AppColors.textTertiary),
          ],
        ],
      ),
      onTap: chevron ? () {} : null,
    );
  }

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.live.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        // Full logout: session + voice room + catalog cache + all account
        // providers.
        onTap: () => logoutAndClear(ref),
        child: SizedBox(
          height: 52,
          child: Center(
            child: Text(AppText.of(context).settingsLogout,
                style: const TextStyle(
                    color: AppColors.live,
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
