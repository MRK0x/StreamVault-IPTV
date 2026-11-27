import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_api.dart';
import '../../core/config.dart';
import '../../core/theme.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../widgets/brand_button.dart';
import '../widgets/rounded_field.dart';
import 'register_screen.dart';

/// The login screen — clean iOS style, with the brand identity.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    ref
        .read(authControllerProvider.notifier)
        .login(_userCtrl.text, _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.surfaceAccent, AppColors.canvas],
            stops: [0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xxl),
                  _logo(),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'MRK0sLivE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppText.of(context).authTagline,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: AppSpacing.xxl * 1.4),
                  RoundedField(
                    controller: _userCtrl,
                    hint: AppText.of(context).authUsername,
                    icon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  RoundedField(
                    controller: _passCtrl,
                    hint: AppText.of(context).authPassword,
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    onSubmit: (_) => _submit(),
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textTertiary,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  if (auth.errorCode case final code?) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _errorText(context, code),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.live, fontSize: 13),
                    ),
                  ],
                  if (auth.hasDeviceLimit) _deviceLimitList(auth.devices),
                  const SizedBox(height: AppSpacing.xl),
                  BrandButton(
                    label: AppText.of(context).authLogin,
                    loading: auth.isBusy,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(AppText.of(context).authNoAccount,
                          style: const TextStyle(
                              color: AppColors.textTertiary, fontSize: 13)),
                      TextButton(
                        onPressed: auth.isBusy
                            ? null
                            : () => Navigator.of(context).push(
                                  CupertinoPageRoute(
                                      builder: (_) => const RegisterScreen()),
                                ),
                        child: Text(AppText.of(context).authCreateAccount,
                            style: const TextStyle(
                                color: AppColors.brand,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                  if (AppConfig.useMockData)
                    Text(
                      AppText.of(context).authDemoHint,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Maps an auth error code to text in the current language.
  String _errorText(BuildContext context, AuthErrorCode code) {
    final t = AppText.of(context);
    return switch (code) {
      AuthErrorCode.emptyCredentials => t.authErrorEmptyCredentials,
      AuthErrorCode.badCredentials => t.authErrorBadCredentials,
      AuthErrorCode.network => t.authErrorNetwork,
      AuthErrorCode.deviceLimit => t.authErrorDeviceLimit,
      AuthErrorCode.generic => t.authErrorGeneric,
    };
  }

  Widget _deviceLimitList(List<DeviceInfo> devices) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(AppText.of(context).authDeviceLimitTitle,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          for (final d in devices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.smartphone_rounded,
                  color: AppColors.textTertiary, size: 20),
              title: Text(
                  d.name.trim().isEmpty
                      ? AppText.of(context).deviceFallbackName
                      : d.name,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14)),
              subtitle: d.lastSeen != null
                  ? Text(d.lastSeen!,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 11))
                  : null,
              trailing: TextButton(
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).evictAndRetry(d.id),
                child: Text(AppText.of(context).authEvict,
                    style: const TextStyle(color: AppColors.live)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _logo() {
    return Container(
      width: 88,
      height: 88,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandStrong, AppColors.surfaceAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 52),
    );
  }

  // (`_field` used to live here — extracted into RoundedField so registration
  // uses the same look.)
}
