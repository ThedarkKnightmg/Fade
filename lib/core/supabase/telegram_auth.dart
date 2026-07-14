import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'supabase_config.dart';

/// "Continue with Telegram" — the bot deep-link flow (the mobile-friendly
/// variant of Telegram Login, and the natural primary sign-in for Uzbekistan):
///
///   1. The app mints a one-time code and opens t.me/<bot>?start=<code>.
///   2. The user taps START in Telegram; the bot's webhook (the
///      telegram-login Edge Function) records code → verified + their name.
///   3. The app polls the same function until the code flips to verified.
///
/// Free (no SMS cost), familiar to every local user, and bot accounts are
/// hard to fake. Requires [SupabaseConfig.telegramBot] + the deployed
/// function; unconfigured builds demo the flow locally instead.
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

  /// Ask the Edge Function whether the bot has seen this code yet.
  /// Returns (verified, firstName) — name is null until verified.
  static Future<(bool, String?)> check(String code) async {
    final res = await http.get(
      Uri.parse(
          '${SupabaseConfig.url}/functions/v1/telegram-login?code=$code'),
      headers: {
        'apikey': SupabaseConfig.publishableKey,
        'Authorization': 'Bearer ${SupabaseConfig.publishableKey}',
      },
    );
    if (res.statusCode != 200) return (false, null);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['status'] == 'verified', json['name'] as String?);
  }
}
