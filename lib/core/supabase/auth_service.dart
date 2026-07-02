import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Real phone-OTP auth on top of Supabase.
///
/// Flow: [sendCode] texts a 6-digit code (Supabase → your SMS provider), then
/// [verifyCode] exchanges the code for a real session. Sessions persist across
/// launches automatically (supabase_flutter stores them).
///
/// Requires the Phone provider + an SMS gateway (e.g. Twilio) configured in the
/// Supabase dashboard — without it [sendCode] throws and the message surfaces
/// to the UI.
class AuthService {
  AuthService._();

  static GoTrueClient get _auth => SupabaseService.client.auth;

  /// Normalise a typed number to E.164. Uzbekistan default (+998) when the user
  /// types a bare 9-digit local number; otherwise respects a leading country
  /// code (with or without '+').
  static String normalizePhone(String raw) {
    var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.startsWith('00')) d = d.substring(2);
    if (d.length == 9) d = '998$d'; // bare UZ mobile (90 123 45 67)
    return '+$d';
  }

  /// Text a login code to [phoneE164]. Creates the user if new.
  static Future<void> sendCode(String phoneE164) =>
      _auth.signInWithOtp(phone: phoneE164);

  /// Exchange the SMS [code] for a session. Throws on a wrong/expired code.
  static Future<AuthResponse> verifyCode(String phoneE164, String code) =>
      _auth.verifyOTP(phone: phoneE164, token: code, type: OtpType.sms);

  static Future<void> signOut() => _auth.signOut();

  static Session? get session =>
      SupabaseService.isReady ? _auth.currentSession : null;
  static User? get user => SupabaseService.isReady ? _auth.currentUser : null;
  static bool get isSignedIn => session != null;

  /// Fires on sign-in / sign-out / token refresh — lets the app react to the
  /// real session (e.g. route to home or back to the login screen).
  static Stream<AuthState> get changes => _auth.onAuthStateChange;
}
