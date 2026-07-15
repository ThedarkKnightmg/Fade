import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';
import 'supabase_service.dart';

/// What Google handed back about the person — already verified by Google, so
/// none of it has to be typed into a form.
class GoogleProfile {
  const GoogleProfile({required this.name, required this.email, this.photoUrl});

  final String name;
  final String email;
  final String? photoUrl;
}

/// "Continue with Google" — the native one-tap flow.
///
/// The account sheet is drawn by Google Play Services, so nobody types a name,
/// an email, or a password. Google mints an ID token, Supabase verifies its
/// signature and audience, and the session comes back with a **verified**
/// email attached. Free at any volume — unlike SMS, there's no per-login cost.
///
/// Pairs with [TelegramAuth] rather than replacing it: Telegram proves a
/// **phone** (what a barber calls), Google proves an **email** (what a receipt
/// goes to). Offering both means nobody hits a dead end.
class GoogleAuth {
  GoogleAuth._();

  static bool get configured => SupabaseConfig.googleConfigured;

  /// Runs the whole flow. Returns the profile on success, or null when the
  /// user dismissed the account picker (a cancel is not an error — it must
  /// stay silent). Throws only when something is genuinely misconfigured.
  static Future<GoogleProfile?> signIn() async {
    if (!SupabaseService.isReady) {
      throw StateError('Supabase is not initialised — see SupabaseService.init');
    }

    final google = GoogleSignIn(
      serverClientId: SupabaseConfig.googleWebClientId,
      scopes: const ['email', 'profile'],
    );

    // Always present the picker. Silently reusing whichever account signed in
    // last is the wrong default on a shared phone, and it makes "switch
    // account" impossible without uninstalling.
    await google.signOut();

    final account = await google.signIn();
    if (account == null) return null; // picker dismissed

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      // Nearly always one specific mistake, so name it rather than shrugging.
      throw StateError(
        'Google returned no ID token. The serverClientId must be the WEB '
        'OAuth client ID, and this build\'s signing SHA-1 must be registered '
        'on the Android OAuth client for package uz.fade.app.',
      );
    }

    await SupabaseService.client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );

    return GoogleProfile(
      name: account.displayName ?? '',
      email: account.email,
      photoUrl: account.photoUrl,
    );
  }
}
