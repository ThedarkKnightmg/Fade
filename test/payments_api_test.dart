import 'dart:convert';

import 'package:barber_app/core/payments/payments_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// The app's side of real payments: it may only ever learn that money moved
// from the server's payments row, never decide it itself.
void main() {
  PaymentsApi api(MockClient c, {List<String?> statuses = const []}) {
    var i = 0;
    return PaymentsApi(
      client: c,
      accessToken: () async => 'jwt',
      readStatus: (_) async =>
          statuses.isEmpty ? null : statuses[i < statuses.length ? i++ : statuses.length - 1],
    );
  }

  test('no merchant keys on the server: not configured, nothing to pay', () async {
    final a = api(MockClient((_) async => http.Response('{"configured":false}', 503)));
    expect(await a.isLive(), isFalse);
    final s = await a.start(purpose: PaymentPurpose.walletTopup, amountSom: 50000);
    expect(s.configured, isFalse);
    expect(s.ok, isFalse);
  });

  test('a started payment carries the server order and both checkout links', () async {
    late Map<String, dynamic> sent;
    final a = api(MockClient((req) async {
      sent = jsonDecode(req.body) as Map<String, dynamic>;
      expect(req.headers['Authorization'], 'Bearer jwt');
      return http.Response(
          jsonEncode({
            'configured': true,
            'payment_id': 'p1',
            'amount_som': 50000,
            'payme_url': 'https://checkout.paycom.uz/x',
            'click_url': 'https://my.click.uz/services/pay?y',
          }),
          200);
    }));
    final s = await a.start(purpose: PaymentPurpose.walletTopup, amountSom: 50000);
    expect(s.ok, isTrue);
    expect(s.paymentId, 'p1');
    expect(s.paymeUrl, startsWith('https://checkout.paycom.uz/'));
    expect(sent['purpose'], 'wallet_topup');
  });

  test('a refused request is an error, not a payment', () async {
    final a = api(MockClient((_) async => http.Response('{"error":"amount not allowed"}', 400)));
    final s = await a.start(purpose: PaymentPurpose.walletTopup, amountSom: 1);
    expect(s.ok, isFalse);
    expect(s.error, 'amount not allowed');
  });

  test('waiting ends only on what the server says', () async {
    final none = MockClient((_) async => http.Response('', 200));
    expect(
      await api(none, statuses: ['created', 'pending', 'paid'])
          .waitForResult('p1', every: Duration.zero),
      PaymentOutcome.paid,
    );
    expect(
      await api(none, statuses: ['pending', 'cancelled'])
          .waitForResult('p1', every: Duration.zero),
      PaymentOutcome.cancelled,
    );
    expect(
      await api(none, statuses: ['pending'])
          .waitForResult('p1', every: Duration.zero, timeout: const Duration(milliseconds: 30)),
      PaymentOutcome.timeout,
    );
  });
}
