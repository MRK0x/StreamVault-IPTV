import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../data/account_api.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../widgets/brand_button.dart';
import '../widgets/rounded_field.dart';
import '../widgets/upper_case_formatter.dart';

/// Subscription activation sheet with a coupon —
/// `POST /api/subscriptions/redeem/`.
///
/// **One sheet for two places**: shown automatically after sign-up (accounts
/// are created without a subscription), and opened from Settings for any
/// signed-in user (renew/upgrade). We don't duplicate the UI.
///
/// Requires Bearer ⇒ only called after the session is saved.
Future<void> showActivationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true, // keyboard doesn't cover the field
    backgroundColor: Colors.transparent,
    builder: (_) => const _ActivationSheet(),
  );
}

class _ActivationSheet extends ConsumerStatefulWidget {
  const _ActivationSheet();

  @override
  ConsumerState<_ActivationSheet> createState() => _ActivationSheetState();
}

class _ActivationSheetState extends ConsumerState<_ActivationSheet> {
  final _codeCtrl = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppText.of(context);
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _err = t.activateEmpty);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _err = null;
    });

    final result = await ref.read(accountApiProvider).redeem(code);
    if (!mounted) return;

    if (result == RedeemStatus.success) {
      // The redeem response differs from /api/me/'s shape — reload the single
      // source of truth so the UI updates instantly without a restart.
      ref.invalidate(accountProvider);
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(t.activateSuccess)));
      return;
    }

    setState(() {
      _busy = false;
      _err = switch (result) {
        RedeemStatus.invalidCode => t.activateErrInvalid,
        RedeemStatus.throttled => t.activateErrThrottled,
        _ => t.activateErrGeneric,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
        top: AppSpacing.md,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                const Icon(Icons.redeem_rounded, color: AppColors.brand),
                const SizedBox(width: 8),
                Text(t.activateTitle,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 6),
            Text(t.activateSubtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: AppSpacing.lg),
            RoundedField(
              controller: _codeCtrl,
              hint: t.activateCodeHint,
              icon: Icons.confirmation_number_outlined,
              textInputAction: TextInputAction.done,
              onSubmit: (_) => _submit(),
              errorText: _err,
              // Codes are generated in uppercase only (and the server is
              // case-sensitive).
              formatters: const [UpperCaseFormatter()],
              maxLength: 32, // server limit
            ),
            const SizedBox(height: AppSpacing.md),
            BrandButton(
              label: t.activateSubmit,
              icon: Icons.check_rounded,
              loading: _busy,
              onPressed: _submit,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).pop(),
              child: Text(t.activateLater,
                  style: const TextStyle(color: AppColors.textTertiary)),
            ),
          ],
        ),
      ),
    );
  }
}
