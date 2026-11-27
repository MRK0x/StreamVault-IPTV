import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_api.dart';
import '../../core/theme.dart';
import '../../l10n/app_text.dart';
import '../../state/providers.dart';
import '../app.dart';
import '../subscription/activation_sheet.dart';
import '../widgets/brand_button.dart';
import '../widgets/rounded_field.dart';

/// Create a new account — `POST /api/auth/register/`.
///
/// The server activates the account immediately and returns a JWT (no
/// subscription), so we sign in directly without a second login request. 400
/// errors are shown **under their field**, not as a generic message.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscure = true;
  bool _busy = false;

  /// Field errors — from UI validation or from the server response.
  String? _userErr;
  String? _emailErr;
  String? _passErr;
  String? _confirmErr;

  /// Generic error (throttle/network) that isn't tied to a specific field.
  String? _formErr;

  @override
  void dispose() {
    _userCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Instant validation before submitting — saves a network round trip and
  /// protects the 5 attempts/hour limit.
  /// (Django's other rules — common/numeric-only/too-similar — can't be
  ///  checked here, so the server returns them and we display them.)
  bool _validate() {
    final t = AppText.of(context);
    final user = _userCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;

    String? userErr;
    if (user.isEmpty) {
      userErr = t.authValUsernameRequired;
    } else if (user.length < 3) {
      userErr = t.authValUsernameShort;
    }

    String? emailErr;
    if (email.isEmpty) {
      emailErr = t.authValEmailRequired;
    } else if (!_isEmail(email)) {
      emailErr = t.authValEmailInvalid;
    }

    String? passErr;
    if (pass.isEmpty) {
      passErr = t.authValPasswordRequired;
    } else if (pass.length < 8) {
      passErr = t.authValPasswordShort; // Django rule: at least 8 characters
    }

    final confirmErr =
        _confirmCtrl.text != pass ? t.authValPasswordMismatch : null;

    setState(() {
      _userErr = userErr;
      _emailErr = emailErr;
      _passErr = passErr;
      _confirmErr = confirmErr;
      _formErr = null;
    });
    return userErr == null &&
        emailErr == null &&
        passErr == null &&
        confirmErr == null;
  }

  static bool _isEmail(String v) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_busy || !_validate()) return;
    setState(() => _busy = true);

    final outcome = await ref.read(authControllerProvider.notifier).register(
          username: _userCtrl.text,
          email: _emailCtrl.text,
          password: _passCtrl.text,
        );
    if (!mounted) return;
    setState(() => _busy = false);

    switch (outcome.status) {
      case RegisterStatus.success:
        // The session is already saved in the controller (redeem needs a
        // Bearer), and the gate signs in automatically. Close the register
        // screen, then show the activation sheet — the account was created
        // without a subscription (active:false), so no content until activated.
        Navigator.of(context).maybePop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = rootNavigatorKey.currentContext;
          if (ctx != null) showActivationSheet(ctx);
        });
      case RegisterStatus.invalidFields:
        final t = AppText.of(context);
        setState(() {
          _userErr = _msgFor(t, RegisterField.username, outcome.fieldErrors);
          _emailErr = _msgFor(t, RegisterField.email, outcome.fieldErrors);
          _passErr = _msgFor(t, RegisterField.password, outcome.fieldErrors);
        });
      case RegisterStatus.throttled:
        setState(() => _formErr = AppText.of(context).authErrorThrottled);
      case RegisterStatus.error:
        setState(() => _formErr = AppText.of(context).authErrorRegisterFailed);
    }
  }

  /// Localizes a server error for a given field.
  ///
  /// **Logic is driven by the field name** (the key); the server's English text
  /// is used here — in the UI layer only — as a hint to pick a more precise
  /// message. Any text we don't recognize falls back to a generic message for
  /// the field, so English never reaches the user.
  String? _msgFor(
      AppText t, RegisterField field, Map<RegisterField, String> errors) {
    final raw = errors[field];
    if (raw == null) return null;
    final m = raw.toLowerCase();
    return switch (field) {
      RegisterField.username => m.contains('already')
          ? t.authErrUsernameTaken
          : t.authErrUsernameGeneric,
      RegisterField.email => m.contains('already')
          ? t.authErrEmailTaken
          : m.contains('valid')
              ? t.authValEmailInvalid
              : t.authErrEmailGeneric,
      RegisterField.password => m.contains('too short')
          ? t.authValPasswordShort
          : m.contains('too common')
              ? t.authErrPasswordCommon
              : m.contains('numeric')
                  ? t.authErrPasswordNumeric
                  : m.contains('similar')
                      ? t.authErrPasswordSimilar
                      : t.authErrPasswordGeneric,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = AppText.of(context);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: Text(t.authRegisterTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, 0, AppSpacing.xl, AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.authRegisterSubtitle,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xl),
              RoundedField(
                controller: _userCtrl,
                hint: t.authUsername,
                icon: Icons.person_outline_rounded,
                textInputAction: TextInputAction.next,
                errorText: _userErr,
              ),
              const SizedBox(height: AppSpacing.md),
              RoundedField(
                controller: _emailCtrl,
                hint: t.authEmail,
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                errorText: _emailErr,
              ),
              const SizedBox(height: AppSpacing.md),
              RoundedField(
                controller: _passCtrl,
                hint: t.authPassword,
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                textInputAction: TextInputAction.next,
                errorText: _passErr,
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
              const SizedBox(height: AppSpacing.md),
              RoundedField(
                controller: _confirmCtrl,
                hint: t.authConfirmPassword,
                icon: Icons.lock_reset_rounded,
                obscure: _obscure,
                textInputAction: TextInputAction.done,
                onSubmit: (_) => _submit(),
                errorText: _confirmErr,
              ),
              if (_formErr case final e?) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  e,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.live, fontSize: 13),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              BrandButton(
                label: t.authRegisterSubmit,
                loading: _busy,
                onPressed: _submit,
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(t.authHaveAccount,
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(t.authLoginInstead,
                        style: const TextStyle(
                            color: AppColors.brand,
                            fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
