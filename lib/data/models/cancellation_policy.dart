/// The cancellation policy: free to cancel until [windowHours] before the slot;
/// cancel later — or no-show — and [feeRate] of the price applies. It protects
/// the barber's time without charging the client anything up front.
class CancellationPolicy {
  const CancellationPolicy({this.windowHours = 4, this.feeRate = 0.5});

  final int windowHours;
  final double feeRate;

  static const CancellationPolicy standard = CancellationPolicy();

  /// True when [slot] is within [windowHours] of now (fee territory). A slot in
  /// the past counts as inside the window (a missed appointment).
  bool isInsideWindow(DateTime slot, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    return slot.difference(ref) < Duration(hours: windowHours);
  }

  /// The fee, in the same USD-ish units service prices are stored in. Convert
  /// for display with Money.som — never surface raw USD.
  double feeUsd(double servicePriceUsd) => servicePriceUsd * feeRate;

  int get feePercent => (feeRate * 100).round();
}
