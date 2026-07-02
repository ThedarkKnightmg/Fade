/// One line in the barber's wallet ledger. A mock record — no real money moves;
/// top-ups and fee settlement hand off to a payment provider in production.
class WalletTx {
  WalletTx({
    required this.label,
    required this.amountSom,
    required this.credit,
    required this.at,
    this.sub,
  });

  final String label;

  /// Amount in so'm (always positive; [credit] gives the direction).
  final int amountSom;

  /// true = money in (top-up), false = a commission fee out.
  final bool credit;
  final DateTime at;
  final String? sub;
}
