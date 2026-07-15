import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'supabase_config.dart';

/// "Continue with Telegram" — the bot deep-link flow, and our PHONE
/// VERIFICATION too (the natural primary sign-in for Uzbekistan):
///
///   1. The app mints a one-time code and opens t.me/<bot>?start=<code>.
///   2. The user taps START; the bot asks them to share their contact.
///   3. Telegram returns the number IT verified at signup — real proof of
///      ownership, no SMS and no cost — and the webhook marks the code
///      verified with that phone + their name.
///   4. The app polls this function until the code flips to verified.
///
/// Free, familiar to every local user, and bot accounts are hard to fake.
/// Requires [SupabaseConfig.telegramBot] + the deployed function;
/// unconfigured builds demo the flow locally instead.
class TelegramAuth {
  TelegramAuth._();

  static final Random _rng = Random.secure();

  static bool get configured => SupabaseConfig.telegramLoginConfigured;

  /// A fresh unguessable one-time login code.
  static String newCode() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(24, (_) => chars[_rng.nextInt(chars.length)]).join();
  }

  /// The t.me link that opens the bot with this code preloaded.
  static Uri deepLink(String code) =>
      Uri.parse('https://t.me/${SupabaseConfig.telegramBot}?start=$code');

  /// Ask the Edge Function whether this login is confirmed yet.
  /// Returns (verified, name, phone) — set only once the user shared their
  /// contact, so [phone] is Telegram-verified, not typed by hand.
  static Future<(bool, String?, String?)> check(String code) async {
    final res = await http.get(
      Uri.parse(
          '${SupabaseConfig.url}/functions/v1/telegram-login?code=$code'),
      headers: {
        'apikey': SupabaseConfig.publishableKey,
        'Authorization': 'Bearer ${SupabaseConfig.publishableKey}',
      },
    );
    if (res.statusCode != 200) return (false, null, null);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      json['status'] == 'verified',
      json['name'] as String?,
      json['phone'] as String?,
    );
  }
}
