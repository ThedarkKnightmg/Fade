import 'dart:convert';

import 'package:http/http.dart' as http;

import 'supabase_config.dart';

/// Sends in-app feedback to the `feedback` Edge Function, which stores it and
/// pings the owner on Telegram. Best-effort: returns false on any failure so
/// the caller can keep a local copy and nothing a user wrote is lost.
class FeedbackService {
  FeedbackService._();

  static Future<bool> send({
    required String category,
    required String message,
    String? contact,
    String? role,
  }) async {
    if (!SupabaseConfig.isSet) return false;
    try {
      final res = await http
          .post(
            Uri.parse('${SupabaseConfig.url}/functions/v1/feedback'),
            headers: {
              'apikey': SupabaseConfig.publishableKey,
              'Authorization': 'Bearer ${SupabaseConfig.publishableKey}',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'category': category,
              'message': message,
              if (contact != null && contact.isNotEmpty) 'contact': contact,
              if (role != null) 'role': role,
              'platform': 'android',
            }),
          )
          .timeout(const Duration(seconds: 8));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
