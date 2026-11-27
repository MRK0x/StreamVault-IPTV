import 'package:flutter/services.dart';

/// Upper-cases input — for room codes and subscription codes.
///
/// Safe both ways: the server requires room codes in upper case, and
/// subscription codes are generated from an upper-case-only alphabet
/// (`ABCDEFGHJKLMNPQRSTUVWXYZ23456789`), so upper-casing does no harm.
class UpperCaseFormatter extends TextInputFormatter {
  const UpperCaseFormatter();

  @override
  TextEditingValue formatEditUpdate(
          TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
