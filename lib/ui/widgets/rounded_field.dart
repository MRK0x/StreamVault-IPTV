import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show TextInputFormatter;

import '../../core/theme.dart';

/// Shared input field — extracted from the login screen so registration uses
/// exactly the same look (no duplicated styling for the two to drift apart).
class RoundedField extends StatelessWidget {
  const RoundedField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.textInputAction,
    this.keyboardType,
    this.onSubmit,
    this.errorText,
    this.formatters,
    this.maxLength,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onSubmit;

  /// Error shown **under this field** — from UI validation or the server
  /// response (which reports errors per field).
  final String? errorText;

  /// Input formatters (e.g. upper-casing room/subscription codes).
  final List<TextInputFormatter>? formatters;

  /// Length limit — the counter is hidden since the limit is technical, not
  /// user-facing information.
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: w == 0 ? BorderSide.none : BorderSide(color: c, width: w),
        );

    return TextField(
      controller: controller,
      obscureText: obscure,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      onSubmitted: onSubmit,
      inputFormatters: formatters,
      maxLength: maxLength,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        counterText: '', // hide the character counter (the limit is technical)
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: Icon(icon, color: AppColors.textTertiary),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        errorText: errorText,
        errorStyle: const TextStyle(color: AppColors.live, fontSize: 12),
        errorMaxLines: 3,
        border: border(Colors.transparent, 0),
        enabledBorder: border(Colors.white.withValues(alpha: 0.08)),
        focusedBorder: border(AppColors.brand, 1.4),
        errorBorder: border(AppColors.live),
        focusedErrorBorder: border(AppColors.live, 1.4),
      ),
    );
  }
}
