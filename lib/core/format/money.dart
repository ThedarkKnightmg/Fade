/// Currency formatting for the whole app.
///
/// Prices are authored in USD in the mock data; the entire UI shows
/// Uzbekistani so'm. Converting + formatting lives here so there's a single
/// knob ([usdToUzs]) and one consistent format ("358 400 so'm").
class Money {
  Money._();

  /// Approximate USD → UZS rate (2026). Retune everything from here.
  static const int usdToUzs = 12800;

  /// Non-breaking space — keeps grouped digits and the "so'm" unit together
  /// so a price never wraps mid-number.
  static const String _nbsp = ' ';

  /// Convert a USD amount to whole so'm.
  static int toSom(num usd) => (usd * usdToUzs).round();

  /// Group thousands: 358400 → "358 400" (non-breaking spaces).
  static String group(int value) {
    final neg = value < 0;
    final digits = value.abs().toString();
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buf.write(_nbsp);
      buf.write(digits[i]);
    }
    return neg ? '-${buf.toString()}' : buf.toString();
  }

  /// Full label from a USD amount, e.g. "358 400 so'm".
  static String som(num usd) => somValue(toSom(usd));

  /// Full label from a so'm amount already in so'm.
  static String somValue(int som) => "${group(som)}${_nbsp}so'm";

  /// Compact label for tight spots (map pins): "360k", "1.2 mln".
  static String compact(num usd) {
    final v = toSom(usd);
    if (v >= 1000000) {
      final m = v / 1000000;
      return '${m.toStringAsFixed(m % 1 == 0 ? 0 : 1)}${_nbsp}mln';
    }
    if (v >= 1000) return '${(v / 1000).round()}k';
    return '$v';
  }

  /// Short price-tier band for the shop $/$$/$$$ indicator, in so'm.
  static String priceTier(int tier) {
    const k = {1: 150, 2: 300, 3: 500};
    return '${k[tier] ?? 300}k${_nbsp}so\'m';
  }
}
