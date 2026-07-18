import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import 'supabase_config.dart';

/// "Continue with Telegram" — the bot deep-link flow, and our PHONE
/// VERIFICATION too (the natural primary sign-in for Uzbekistan). It now yields
/// a REAL Supabase session, not just a local claim:
///
///   1. The app MINTS the attempt first: it generates a code, a device secret,
///      and a two-word check phrase, and registers {code, sha256(secret),
///      phrase} with the Edge Function. Minting-before-opening is what lets the
///      function reject any code an attacker simply invented.
///   2. It opens t.me/<bot>?start=<code>. The bot shows the check phrase and a
///      warning, then asks the user to share their contact.
///   3. Telegram returns the number IT verified at signup. The function checks
///      the contact really belongs to the sender, then — server-side, with the
///      service-role key — creates/fetches the auth user and mints a one-time
///      magic-link token.
///   4. The app polls WITH its device secret (so only this device can read the
///      result), receives the token once, and exchanges it via verifyOTP for a
///      genuine session.
///
/// Free, familiar to every local user, hard to fake, and now server-verified.
class TelegramAuth {
  TelegramAuth._();

  static final Random _rng = Random.secure();

  static bool get configured => SupabaseConfig.telegramLoginConfigured;

  static String _randomToken(int n) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(n, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  /// A fresh unguessable one-time login code.
  static String newCode() => _randomToken(24);

  /// A per-attempt secret the app keeps to itself. Its SHA-256 is registered
  /// with the server; presenting the raw value at poll time proves this is the
  /// same device that started the login.
  static String newDeviceSecret() => _randomToken(40);

  static String deviceHash(String secret) =>
      sha256.convert(utf8.encode(secret)).toString();

  /// Two short words the app shows and the bot echoes — a human check against
  /// a phished link opening the bot without the user having opened the app.
  static String newPhrase() {
    const words = [
      'BLUE', 'TIGER', 'RIVER', 'STONE', 'AMBER', 'FALCON', 'MAPLE', 'COBALT',
      'EMBER', 'QUARTZ', 'WILLOW', 'ORBIT', 'CEDAR', 'IVORY', 'RAVEN', 'DELTA',
    ];
    return '${words[_rng.nextInt(words.length)]} ${words[_rng.nextInt(words.length)]}';
  }

  /// The t.me link that opens the bot with this code preloaded.
  static Uri deepLink(String code) =>
      Uri.parse('https://t.me/${SupabaseConfig.telegramBot}?start=$code');

  static Map<String, String> get _headers => {
        'apikey': SupabaseConfig.publishableKey,
        'Authorization': 'Bearer ${SupabaseConfig.publishableKey}',
        'Content-Type': 'application/json',
      };

  static Uri get _fnUrl =>
      Uri.parse('${SupabaseConfig.url}/functions/v1/telegram-login');

  /// Register the attempt before opening the bot link. Returns true on success.
  static Future<bool> mint({
    required String code,
    required String deviceSecret,
    required String phrase,
  }) async {
    try {
      final res = await http.post(
        _fnUrl,
        headers: _headers,
        body: jsonEncode({
          'action': 'mint',
          'code': code,
          'device_hash': deviceHash(deviceSecret),
          'phrase': phrase,
        }),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Poll for confirmation. Returns (verified, name, phone, tokenHash) — the
  /// tokenHash is the one-time magic-link token to exchange for a session, and
  /// is only returned to the device whose secret matches.
  static Future<(bool, String?, String?, String?)> check(
      String code, String deviceSecret) async {
    final res = await http.get(
      Uri.parse('${_fnUrl.toString()}?code=$code&device=$deviceSecret'),
      headers: _headers,
    );
    if (res.statusCode != 200) return (false, null, null, null);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      json['status'] == 'verified',
      json['name'] as String?,
      json['phone'] as String?,
      json['token_hash'] as String?,
    );
  }
}
