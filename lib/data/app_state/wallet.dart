part of '../app_state.dart';

/// The barber's wallet and the platform's commission.
///
/// The "vending machine": the barber pre-loads a small balance and the app
/// deducts a fee when it delivers a booking.
///
/// WHAT ACTUALLY HAPPENS (see [commissionSomFor]): a FLAT 5% on every booking
/// made through Fade — first visit or fiftieth — halved to 2.5% for VIP. Only
/// walk-ins the barber logs himself are free, since Fade never handled them.
/// This used to describe a four-tier scheme where regulars became free after
/// their first visit; that was never implemented, and the barber intro was
/// written from the comment rather than the code, so the app promised
/// "0% forever" and then charged 5% on visit two. If the tiers ever do get
/// built, change [commissionSomFor] and the copy in the same commit.
///
/// SECURITY: the balance is client-side (shared_preferences). It must move to
/// a server-authoritative ledger before real money is involved.
mixin WalletState on ChangeNotifier, AppStatePlumbing {
  double get effectiveNewClientFeePercent => barberVip
      ? AppState.vipNewClientFeePercent
      : AppState.newClientFeePercent.toDouble();

  int _walletSom = 42000;
  int get walletSom => _walletSom;
  bool get walletLow => _walletSom < 12000;

  // ── The three "coins" in the skeuomorphic wallet ──────────────────────
  // Credit = the prepaid spendable balance (walletSom; top-up refills it,
  // commission fees draw from it). Boost packs & VIP settle via an external
  // provider, not this balance. Earned = money made from completed cuts (real,
  // lifetime). Tips = a modest mock (~12% of earned). Total = the sum shown in
  // the wallet pocket; the week-gain drives the "▲ this week" delta line.
  int get walletEarnedSom => Money.toSom(barberTotalEarned);
  int get walletTipsSom => (walletEarnedSom * 0.12).round();
  int get walletTotalSom => _walletSom + walletEarnedSom + walletTipsSom;
  int get walletWeekGainSom => (barberEarnedThisWeekSom * 1.12).round();

  final List<WalletTx> _ledger = [];
  bool _ledgerSeeded = false;
  List<WalletTx> get walletLedger {
    _ensureLedgerSeed();
    return List.unmodifiable(_ledger);
  }

  void _ensureLedgerSeed() {
    if (_ledgerSeeded) return;
    _ledgerSeeded = true;
    final now = DateTime.now();
    _ledger.addAll([
      WalletTx(
          label: 'Top-up',
          amountSom: 50000,
          credit: true,
          at: now.subtract(const Duration(days: 6))),
      WalletTx(
          label: 'Sardor A.',
          sub: 'New-client fee',
          amountSom: 3500,
          credit: false,
          at: now.subtract(const Duration(days: 5))),
      WalletTx(
          label: 'Jasur T.',
          sub: 'New-client fee',
          amountSom: 4500,
          credit: false,
          at: now.subtract(const Duration(days: 3))),
    ]);
  }

  /// Flat commission: every Fade booking pays the platform rate — 5% standard,
  /// 2.5% for VIP. Only manually-logged walk-ins (the barber's own off-platform
  /// clients) are free, since Fade never handled them.
  int commissionSomFor(Booking b) {
    if (b.isWalkIn) return 0;
    return (Money.toSom(b.service.price) * effectiveNewClientFeePercent / 100)
        .round();
  }

  /// The undiscounted 5% fee — used to show a VIP barber what the discount saved.
  int commissionFullSomFor(Booking b) {
    if (b.isWalkIn) return 0;
    return (Money.toSom(b.service.price) * AppState.newClientFeePercent / 100)
        .round();
  }

  void _chargeCommission(String id) {
    final b = _bookingById(id);
    if (b == null || b.isWalkIn) return; // off-platform walk-ins never charge
    _ensureLedgerSeed();
    final fee = commissionSomFor(b);
    if (fee <= 0) return;
    _walletSom -= fee;
    if (_walletSom < 0) _walletSom = 0; // never show a negative balance
    final vip = barberVip;
    if (vip) {
      final saved = commissionFullSomFor(b) - fee;
      if (saved > 0) _recordVipSaving(saved);
    }
    // Every booking is labelled with the rate applied so the barber SEES it.
    _ledger.insert(
      0,
      WalletTx(
        label: b.clientName ?? b.barber.name,
        sub: 'Booking fee · ${vip ? '2.5%' : '5%'} · ${b.service.name}',
        amountSom: fee,
        credit: false,
        at: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Top-up is a provider-handoff stub — no real money moves here.
  void topUpWallet(int som) {
    _ensureLedgerSeed();
    _walletSom += som;
    _ledger.insert(
        0,
        WalletTx(
            label: 'Top-up', amountSom: som, credit: true, at: DateTime.now()));
    notifyListeners();
  }
}
