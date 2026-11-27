import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/models/account.dart';
import '../../l10n/app_text.dart';
import '../../l10n/format.dart';
import '../../state/providers.dart';
import '../widgets/loading.dart';

/// Linked devices — list your devices, highlight yours, and sign out the rest.
///
/// Sign-out: `DELETE /api/devices/{id}/` — frees a seat and revokes the
/// device's tokens.
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  int? _busyId;

  /// Device display name — a localized default when the server sends none.
  String _displayName(AppText t, UserDevice d) =>
      d.name.trim().isEmpty ? t.deviceFallbackName : d.name;

  Future<void> _evict(UserDevice d) async {
    setState(() => _busyId = d.id);
    final messenger = ScaffoldMessenger.of(context);
    final t = AppText.of(context);
    try {
      await ref.read(accountApiProvider).evictDevice(d.id);
      ref.invalidate(devicesProvider);
      ref.invalidate(accountProvider);
      messenger.showSnackBar(
        SnackBar(content: Text(t.devicesEvicted(_displayName(t, d)))),
      );
    } on DioException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(e.response?.statusCode == 404
            ? t.devicesNotFound
            : t.devicesEvictFailed),
      ));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _confirmEvict(UserDevice d) {
    final t = AppText.of(context);
    showDialog<void>(
      context: context,
      builder: (dCtx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(t.devicesEvictTitle,
            style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(
          t.devicesEvictBody(_displayName(t, d)),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: Text(t.commonCancel,
                style: const TextStyle(color: AppColors.textTertiary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dCtx);
              _evict(d);
            },
            child: Text(t.devicesEvict,
                style: const TextStyle(color: AppColors.live)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(devicesProvider);
    final account = ref.watch(accountProvider).valueOrNull;
    final myDeviceId = account?.device?.deviceId;
    final maxDevices = account?.subscription.maxDevices;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            backgroundColor: AppColors.canvas,
            surfaceTintColor: Colors.transparent,
            title: Text(AppText.of(context).devicesTitle),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.xxl),
            sliver: devices.when(
              loading: () => const SliverFillRemaining(
                  hasScrollBody: false, child: LoadingView()),
              error: (e, _) => SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(
                  message: AppText.of(context).devicesFetchFailed,
                  onRetry: () => ref.invalidate(devicesProvider),
                ),
              ),
              data: (list) => SliverList.list(children: [
                _summary(list.length, maxDevices),
                const SizedBox(height: AppSpacing.lg),
                for (final d in list)
                  _tile(d, isMine: d.deviceId == myDeviceId),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Warning shown when the device count exceeds the plan's limit.
  Widget _summary(int count, int? max) {
    final t = AppText.of(context);
    final over = max != null && count > max;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: over
            ? AppColors.live.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        children: [
          Icon(over ? Icons.warning_amber_rounded : Icons.devices_rounded,
              color: over ? AppColors.live : AppColors.brand, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              max == null
                  ? t.devicesRegistered(count)
                  : over
                      ? t.devicesOverLimitLong(count, max)
                      : t.devicesCountOfMax(count, max),
              style: TextStyle(
                color: over ? AppColors.live : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(UserDevice d, {required bool isMine}) {
    final t = AppText.of(context);
    final busy = _busyId == d.id;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: isMine
            ? Border.all(color: AppColors.brand.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isMine ? Icons.smartphone_rounded : Icons.devices_other_rounded,
            color: isMine ? AppColors.brand : AppColors.textTertiary,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _displayName(t, d),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14),
                      ),
                    ),
                    if (isMine) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(AppRadii.pill),
                        ),
                        child: Text(t.devicesThisDevice,
                            style: const TextStyle(
                                color: AppColors.brand,
                                fontSize: 10,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  t.devicesLastSeen(timeAgo(context, d.lastSeen)),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          if (busy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2.2, color: AppColors.brand),
            )
          else if (!isMine)
            // The user can't sign out their current device here (they use
            // "Log out" instead).
            TextButton(
              onPressed: _busyId != null ? null : () => _confirmEvict(d),
              child: Text(t.devicesEvict,
                  style: const TextStyle(
                      color: AppColors.live, fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

}
