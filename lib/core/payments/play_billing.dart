import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_purchase/in_app_purchase.dart';

import '../supabase/supabase_config.dart';
import '../supabase/supabase_service.dart';

enum PlayOutcome { granted, cancelled, pending, failed, unavailable }

class PlayResult {
  const PlayResult(this.outcome, {this.boosts = 0, this.vipUntil, this.already = false});
  final PlayOutcome outcome;
  final int boosts;
  final DateTime? vipUntil;

  /// The server had already granted this purchase (a retry or a restore).
  final bool already;
}

/// Google Play Billing for VIP and Boost.
///
/// Play requires in-app digital features to be sold through Play Billing, so
/// these never go through Payme/Click. Nothing is granted on the device's
/// word: each purchase token goes to the `play-verify` Edge Function, which
/// asks Google and grants once per token. Only then is the purchase completed
/// (acknowledged / consumed) and mirrored into the app.
///
/// When Play isn't available (web, debug without Play, products not created
/// yet) [product] returns null and callers fall back to the old sheet, which
/// is a demo in debug and "launching soon" in release.
class PlayBilling {
  PlayBilling._();
  static final PlayBilling instance = PlayBilling._();

  static const vipProductId = 'fade_vip_monthly';
  static String boostProductId(String packId) => 'fade_boost_$packId';
  static String? packIdOf(String productId) => productId.startsWith('fade_boost_')
      ? productId.substring('fade_boost_'.length)
      : null;

  /// Mirror a server-confirmed grant into the app (wired in main.dart).
  void Function(String productId, PlayResult result)? onGrant;

  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _sub;
  final Map<String, Completer<PlayResult>> _waiting = {};

  bool get _platformOk =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Listen for purchases, and pick up any that finished while the app was
  /// closed (Play re-delivers unacknowledged ones). Safe to call repeatedly.
  void start() {
    if (!_platformOk || _sub != null) return;
    try {
      _sub = _iap.purchaseStream.listen(_onUpdates, onError: (_) {});
      _iap.restorePurchases().catchError((_) {});
    } catch (_) {
      // No Play services (emulator without Play, etc.): billing stays off.
    }
  }

  /// The Play product, or null when it can't be sold here.
  Future<ProductDetails?> product(String id) async {
    if (!_platformOk) return null;
    try {
      if (!await _iap.isAvailable()) return null;
      final r = await _iap.queryProductDetails({id});
      return r.productDetails.isEmpty ? null : r.productDetails.first;
    } catch (_) {
      return null;
    }
  }

  /// Buy [p] and wait for the server's verdict.
  Future<PlayResult> buy(ProductDetails p) async {
    start();
    final done = Completer<PlayResult>();
    _waiting[p.id] = done;
    final param = PurchaseParam(productDetails: p);
    try {
      final started = p.id == vipProductId
          ? await _iap.buyNonConsumable(purchaseParam: param)
          : await _iap.buyConsumable(purchaseParam: param);
      if (!started) {
        _waiting.remove(p.id);
        return const PlayResult(PlayOutcome.failed);
      }
    } catch (_) {
      _waiting.remove(p.id);
      return const PlayResult(PlayOutcome.failed);
    }
    return done.future.timeout(const Duration(minutes: 10),
        onTimeout: () => const PlayResult(PlayOutcome.pending));
  }

  Future<void> _onUpdates(List<PurchaseDetails> updates) async {
    for (final pd in updates) {
      final PlayResult r;
      switch (pd.status) {
        case PurchaseStatus.pending:
          // E.g. a cash payment: Play delivers it later as purchased.
          _finish(pd.productID, const PlayResult(PlayOutcome.pending));
          continue;
        case PurchaseStatus.canceled:
          r = const PlayResult(PlayOutcome.cancelled);
        case PurchaseStatus.error:
          r = const PlayResult(PlayOutcome.failed);
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          r = await _verify(pd);
      }
      // Complete (acknowledge / consume) once the server has it, or when the
      // purchase is dead anyway. A verification that couldn't reach the
      // server is left open so Play re-delivers it next launch.
      final settled = r.outcome == PlayOutcome.granted ||
          r.outcome == PlayOutcome.cancelled ||
          (r.outcome == PlayOutcome.failed && pd.status == PurchaseStatus.error);
      if (settled && pd.pendingCompletePurchase) {
        try {
          await _iap.completePurchase(pd);
        } catch (_) {}
      }
      if (r.outcome == PlayOutcome.granted && !r.already) {
        onGrant?.call(pd.productID, r);
      }
      _finish(pd.productID, r);
    }
  }

  void _finish(String productId, PlayResult r) {
    final c = _waiting.remove(productId);
    if (c != null && !c.isCompleted) c.complete(r);
  }

  Future<PlayResult> _verify(PurchaseDetails pd) async {
    final token = pd.verificationData.serverVerificationData;
    String? jwt;
    try {
      jwt = SupabaseService.client.auth.currentSession?.accessToken;
    } catch (_) {}
    if (jwt == null || !SupabaseConfig.isSet) {
      return const PlayResult(PlayOutcome.failed);
    }
    try {
      final res = await http
          .post(
            Uri.parse('${SupabaseConfig.url}/functions/v1/play-verify'),
            headers: {
              'apikey': SupabaseConfig.publishableKey,
              'Authorization': 'Bearer $jwt',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'product_id': pd.productID, 'purchase_token': token}),
          )
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 503) return const PlayResult(PlayOutcome.unavailable);
      final body = jsonDecode(res.body);
      if (res.statusCode != 200 || body is! Map || body['ok'] != true) {
        return const PlayResult(PlayOutcome.failed);
      }
      return PlayResult(
        PlayOutcome.granted,
        boosts: (body['boosts'] as num?)?.toInt() ?? 0,
        vipUntil: DateTime.tryParse('${body['vip_until'] ?? ''}'),
        already: body['already'] == true,
      );
    } catch (_) {
      return const PlayResult(PlayOutcome.failed);
    }
  }
}
