import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../supabase/supabase_config.dart';
import '../supabase/supabase_service.dart';

/// What a real payment is for. The server decides the amount for each.
enum PaymentPurpose { walletTopup, booking }

/// The answer to "start a payment".
class PaymentStart {
  const PaymentStart({
    required this.configured,
    this.paymentId,
    this.amountSom,
    this.paymeUrl,
    this.clickUrl,
    this.error,
  });

  /// False while no provider is set up on the server (no merchant keys yet).
  final bool configured;
  final String? paymentId;
  final int? amountSom;
  final String? paymeUrl;
  final String? clickUrl;
  final String? error;

  bool get ok => configured && error == null && paymentId != null;

  static const notConfigured = PaymentStart(configured: false);
}

/// How a started payment ended, as the SERVER sees it.
enum PaymentOutcome { paid, cancelled, timeout }

/// Talks to the payments Edge Function and reads payment status.
///
/// The app never decides that money moved. It asks the server to open an
/// order (`payments-create`), sends the person to Payme or Click, then reads
/// its own `payments` row, which only Payme's / Click's signed callbacks can
/// mark paid. See supabase/functions/payments-create.
class PaymentsApi {
  PaymentsApi({
    http.Client? client,
    Future<String?> Function()? accessToken,
    Future<String?> Function(String paymentId)? readStatus,
  })  : _client = client ?? http.Client(),
        _token = accessToken ?? _sessionToken,
        _readStatus = readStatus ?? _statusFromDb;

  final http.Client _client;
  final Future<String?> Function() _token;
  final Future<String?> Function(String) _readStatus;

  static final PaymentsApi instance = PaymentsApi();

  static Future<String?> _sessionToken() async {
    try {
      return SupabaseService.client.auth.currentSession?.accessToken;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _statusFromDb(String id) async {
    try {
      final row = await SupabaseService.client
          .from('payments')
          .select('status')
          .eq('id', id)
          .maybeSingle();
      return row?['status'] as String?;
    } catch (_) {
      return null;
    }
  }

  Uri get _createUri =>
      Uri.parse('${SupabaseConfig.url}/functions/v1/payments-create');

  bool? _live;

  /// Whether real payments are switched on (a provider is configured on the
  /// server). Asked once per session: the function answers 503 before doing
  /// anything else when no merchant keys are set.
  Future<bool> isLive() async {
    if (_live != null) return _live!;
    if (!SupabaseConfig.isSet) return _live = false;
    try {
      final res = await _client
          .post(_createUri,
              headers: {
                'apikey': SupabaseConfig.publishableKey,
                'Content-Type': 'application/json',
              },
              body: '{}')
          .timeout(const Duration(seconds: 8));
      // 503 = not configured. Anything else (401 without a session, 400 for
      // the empty probe) means the endpoint is up and has keys.
      return _live = res.statusCode != 503 && res.statusCode != 404;
    } catch (_) {
      return false; // offline: don't cache, ask again next time
    }
  }

  /// Ask the server to open a payment. Never throws.
  Future<PaymentStart> start({
    required PaymentPurpose purpose,
    int? amountSom,
    String? bookingId,
    String? lang,
  }) async {
    if (!SupabaseConfig.isSet) return PaymentStart.notConfigured;
    final token = await _token();
    if (token == null) {
      return const PaymentStart(configured: true, error: 'sign in first');
    }
    try {
      final res = await _client
          .post(
            _createUri,
            headers: {
              'apikey': SupabaseConfig.publishableKey,
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'purpose':
                  purpose == PaymentPurpose.booking ? 'booking' : 'wallet_topup',
              if (amountSom != null) 'amount_som': amountSom,
              if (bookingId != null) 'booking_id': bookingId,
              if (lang != null) 'lang': lang,
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode == 503) {
        _live = false;
        return PaymentStart.notConfigured;
      }
      final body = jsonDecode(res.body);
      if (body is! Map) {
        return const PaymentStart(configured: true, error: 'bad response');
      }
      if (res.statusCode != 200) {
        return PaymentStart(
            configured: true, error: '${body['error'] ?? res.statusCode}');
      }
      _live = true;
      return PaymentStart(
        configured: true,
        paymentId: body['payment_id'] as String?,
        amountSom: (body['amount_som'] as num?)?.round(),
        paymeUrl: body['payme_url'] as String?,
        clickUrl: body['click_url'] as String?,
      );
    } catch (_) {
      return const PaymentStart(configured: true, error: 'network');
    }
  }

  /// Poll the payment until the server says it's settled, or [timeout].
  /// [nudge] completes early to re-check at once (e.g. the app came back to
  /// the foreground from the Payme app).
  Future<PaymentOutcome> waitForResult(
    String paymentId, {
    Duration every = const Duration(milliseconds: 2500),
    Duration timeout = const Duration(minutes: 15),
    bool Function()? stop,
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (stop?.call() ?? false) return PaymentOutcome.timeout;
      final s = await _readStatus(paymentId);
      if (s == 'paid') return PaymentOutcome.paid;
      if (s == 'cancelled' || s == 'failed') return PaymentOutcome.cancelled;
      await Future<void>.delayed(every);
    }
    return PaymentOutcome.timeout;
  }
}
