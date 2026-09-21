part of '../app_state.dart';

/// Fade Points — the cashback wallet.
///
/// 1 point = 1 UZS. On each completed booking the client earns
/// [AppState.pointsEarnRatePct]% of the price as points (2,500 on a 100,000
/// cut) — a cashback funded from Fade's own commission (half of the standard
/// 5%). Points spend as a discount at checkout (min
/// [AppState.pointsMinRedemptionSom]); the BARBER IS ALWAYS PAID FULL PRICE —
/// the discount comes from the points reserve, never the barber. Points expire
/// [AppState.pointsExpiryDays] after they're earned, and expired points become
/// platform profit (breakage).
///
/// SECURITY: this is a client-side ledger today, like the rest of the app's
/// economy. Points redeemable as money are STORED VALUE and MUST move to a
/// server-authoritative ledger before real payments (kPaymentsLive) —
/// otherwise a rooted user edits their own balance. [refreshServerLoyalty] is
/// the beginning of that move; redemption-at-checkout is still local.
mixin FadePointsState on ChangeNotifier, AppStatePlumbing {
  // Point lots: (amount so'm, earnedAt). Spent oldest-first; oldest expire first.
  final List<({int amount, DateTime earnedAt})> _pointLots = [];
  int _lastPointsEarned = 0;
  int get lastPointsEarned => _lastPointsEarned;

  // Server-authoritative balance (Phase 3B). Null until fetched / when offline;
  // then the local lots below are the mirror. The SERVER is the source of truth.
  int? _serverPointsBalance;
  String? _serverReferralCode;

  /// Pull the real balance + referral code from the server (best-effort).
  Future<void> refreshServerLoyalty() async {
    final bal = await SupabaseLoyalty.balance();
    if (bal != null) {
      _serverPointsBalance = bal;
      notifyListeners();
    }
  }

  /// This user's shareable referral code (server-minted, cached). Falls back to
  /// a local placeholder only when there's no session.
  Future<String> referralCode() async {
    _serverReferralCode ??= await SupabaseLoyalty.myReferralCode();
    return _serverReferralCode ?? 'FADE';
  }

  /// Live spendable balance (so'm) — the server figure when we have it, else the
  /// local mirror (the point lots below).
  int get pointsBalanceSom => _basePointsSom + _gameMintedSom;

  /// The balance the SERVER knows about (or the local lot mirror when offline).
  int get _basePointsSom {
    if (_serverPointsBalance != null) return _serverPointsBalance!;
    final now = DateTime.now();
    return _pointLots
        .where(
            (l) => now.difference(l.earnedAt).inDays <= AppState.pointsExpiryDays)
        .fold(0, (s, l) => s + l.amount);
  }

  /// Points minted locally that the server has no idea about — today, the
  /// waiting-chair game's tokens.
  ///
  /// This exists because the balance PREFERS the server figure, and the server
  /// has no endpoint for awarding game points. Anything minted locally was
  /// therefore invisible the moment a session existed: the player cut a token,
  /// watched "+25" fly up, and saw the balance never move.
  ///
  /// Kept as its own running total rather than a point lot so it survives that
  /// preference — it is ADDED to whatever the base balance is, never replaced
  /// by it. When a server-side award RPC exists this becomes the migration
  /// point: award server-side, then retire this field.
  int _gameMintedSom = 0;

  /// Points a completed booking earns — [AppState.pointsEarnRatePct]% of its
  /// so'm price.
  int pointsEarnedFor(Booking b) =>
      (Money.toSom(b.service.price) * AppState.pointsEarnRatePct / 100).round();

  void _earnFadePoints(Booking b) {
    final pts = pointsEarnedFor(b);
    if (pts <= 0) return;
    _pointLots.add((amount: pts, earnedAt: DateTime.now()));
    _lastPointsEarned = pts;
  }

  /// Mint points from something that is not a booking (today: the waiting-chair
  /// game). Kept as ONE named entry point so there is a single place to swap
  /// for a server-authoritative award later — see the SECURITY note above.
  ///
  /// Every caller must be capped. Points are money, so an uncapped source is a
  /// money printer: unlike cashback, which is bounded by a real cut at a real
  /// price, a game can be played all day.
  void _mintPoints(int som) {
    if (som <= 0) return;
    // Into the game bucket, NOT a point lot: a lot is invisible whenever a
    // server balance exists (see [_gameMintedSom]).
    _gameMintedSom += som;
    _lastPointsEarned = som;
  }

  /// The most a client may apply to a booking of [priceSom]: their balance,
  /// capped at the price, and only once past the minimum threshold.
  int redeemablePointsFor(int priceSom) {
    final bal = pointsBalanceSom;
    if (bal < AppState.pointsMinRedemptionSom) return 0;
    return bal < priceSom ? bal : priceSom;
  }

  /// Spend up to [som] points (oldest lots first). Returns the amount applied.
  /// The barber is still paid full price — the discount is funded from the
  /// reserve (Fade's set-aside commission), never the barber.
  int redeemPoints(int som) {
    _expirePoints();
    var want = som.clamp(0, pointsBalanceSom);
    if (want < AppState.pointsMinRedemptionSom) return 0;
    final applied = want;
    // Spend game-minted points FIRST. They are the only ones the server can't
    // see, so leaving them until last would let a later server refresh make
    // them look spendable twice. They also don't expire, so burning them early
    // never costs the player anything.
    if (_gameMintedSom > 0) {
      final fromGame = want < _gameMintedSom ? want : _gameMintedSom;
      _gameMintedSom -= fromGame;
      want -= fromGame;
    }
    _pointLots.sort((a, b) => a.earnedAt.compareTo(b.earnedAt)); // oldest first
    while (want > 0 && _pointLots.isNotEmpty) {
      final lot = _pointLots.first;
      if (lot.amount <= want) {
        want -= lot.amount;
        _pointLots.removeAt(0);
      } else {
        _pointLots[0] = (amount: lot.amount - want, earnedAt: lot.earnedAt);
        want = 0;
      }
    }
    _save();
    notifyListeners();
    return applied;
  }

  void _expirePoints() {
    final now = DateTime.now();
    _pointLots.removeWhere(
        (l) => now.difference(l.earnedAt).inDays > AppState.pointsExpiryDays);
  }

  /// When the soonest-expiring points lapse (for a "use by" nudge); null if none.
  DateTime? get pointsNextExpiry {
    _expirePoints();
    if (_pointLots.isEmpty) return null;
    final earliest =
        _pointLots.map((l) => l.earnedAt).reduce((a, b) => a.isBefore(b) ? a : b);
    return earliest.add(const Duration(days: AppState.pointsExpiryDays));
  }
}
