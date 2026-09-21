import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// What Apple handed back about the person.
///
/// Note the nullable name: Apple returns the full name ONLY on the very first
/// authorisation for a given Apple ID. Every later sign-in returns nulls, which
/// is why the app must store it on first contact rather than re-asking.
class AppleProfile {
  const AppleProfile({required this.name, required this.email});

  final String name;
  final String email;
}

/// "Continue with Apple".
///
/// This exists because App Store Review Guideline 4.8 REQUIRES an equivalent
/// Apple sign-in wherever a third-party option (Google, here) is offered. An
/// iOS build without it is rejected, so it is a shipping requirement rather
/// than a nice-to-have.
///
/// It also happens to be the strongest privacy option offered: Apple can relay
/// a hidden address, so a client can book without handing over a real email.
///
/// The nonce dance below is Apple's replay protection: a RAW nonce goes to
/// Supabase, its SHA-256 goes to Apple, and Apple embeds the hash in the
/// identity token. Supabase re-hashes the raw value and compares. Send the same
/// form to both and verification fails.
class AppleAuth {
  AppleAuth._();

  /// Apple sign-in only exists on Apple platforms. Android and web hide the
  /// button entirely rather than showing one that cannot work.
  static bool get available {
    if (kIsWeb) return false;
    try {
      return Platform.isIOS || Platform.isMacOS;
    } catch (_) {
      return false;
    }
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';
    final rnd = Random.secure();
    return List.generate(length, (_) => charset[rnd.nextInt(charset.length)])
        .join();
  }

  /// Runs the whole flow. Returns the profile on success, or null when the user
  /// cancelled the sheet — a cancel is a choice, not an error, and must stay
  /// silent. Throws only when something is genuinely misconfigured.
  static Future<AppleProfile?> signIn() async {
    if (!SupabaseService.isReady) {
      throw StateError('Supabase is not initialised — see SupabaseService.init');
    }

    final rawNonce = _randomNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      // Nearly always one specific setup mistake, so name it.
      throw StateError(
        'Apple returned no identity token. Check that the "Sign in with Apple" '
        'capability is enabled on the uz.fade.app target in Xcode and that the '
        'Apple provider is switched on in Supabase.',
      );
    }

    await SupabaseService.client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce, // RAW here; Apple got the hash
    );

    // Apple gives the name only on the FIRST authorisation ever. On every
    // subsequent sign-in these are null, so fall back to whatever the session
    // already carries rather than blanking a name the user already set.
    final given = credential.givenName?.trim() ?? '';
    final family = credential.familyName?.trim() ?? '';
    final fromApple = '$given $family'.trim();
    final meta = SupabaseService.currentUser?.userMetadata;
    final fallback = (meta?['full_name'] ?? meta?['name'] ?? '') as String? ?? '';

    return AppleProfile(
      name: fromApple.isNotEmpty ? fromApple : fallback.trim(),
      email: credential.email ??
          SupabaseService.currentUser?.email ??
          '',
    );
  }
}
