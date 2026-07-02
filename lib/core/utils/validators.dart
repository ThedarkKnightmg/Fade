/// Pure, defensive input validators. Each returns an error string to show
/// under the field, or null when the value is acceptable. They never throw.
class Validators {
  Validators._();

  // Conservative email shape — local@domain.tld, no spaces, bounded length.
  static final RegExp _email = RegExp(
    r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$",
  );

  // Digits, spaces, and + ( ) - only; 7–20 characters of actual digits.
  static final RegExp _phoneAllowed = RegExp(r'^[0-9+()\-\s]+$');

  static String? email(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your email.';
    if (value.length > 254) return 'That email is too long.';
    if (!_email.hasMatch(value)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? raw, {int min = 8}) {
    final value = raw ?? '';
    if (value.isEmpty) return 'Enter a password.';
    if (value.length < min) return 'Use at least $min characters.';
    if (value.length > 128) return 'That password is too long.';
    return null;
  }

  static String? required(String? raw, {String field = 'This field'}) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '$field is required.';
    if (value.length > 80) return '$field is too long.';
    return null;
  }

  static String? fullName(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your name.';
    if (value.length < 2) return 'That name looks too short.';
    if (value.length > 60) return 'That name is too long.';
    return null;
  }

  static String? phone(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return 'Enter your phone number.';
    if (!_phoneAllowed.hasMatch(value)) {
      return 'Use digits and + ( ) - only.';
    }
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 7 || digits.length > 15) {
      return 'Enter a valid phone number.';
    }
    return null;
  }
}
