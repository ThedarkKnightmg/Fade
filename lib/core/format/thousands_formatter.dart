import 'package:flutter/services.dart';

/// Groups a number field's digits as the user types — 13700 → "13 700".
/// Uses a space separator to match how so'm prices are shown across the app.
class ThousandsInputFormatter extends TextInputFormatter {
  const ThousandsInputFormatter([this.separator = ' ']);
  final String separator;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
          text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final grouped = group(digits, separator);
    return TextEditingValue(
      text: grouped,
      selection: TextSelection.collapsed(offset: grouped.length),
    );
  }

  /// Group a digit string: "13700" → "13 700".
  static String group(String digits, [String separator = ' ']) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(separator);
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  /// Group an int: 13700 → "13 700".
  static String groupInt(int value, [String separator = ' ']) =>
      group(value.toString(), separator);
}
