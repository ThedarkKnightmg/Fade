/// Every public link the app shares, built in one place.
///
/// They land on small pages on GitHub Pages (the `gh-pages` branch), which
/// explain the link and send people to the Play Store. When a real domain is
/// set up, change [host] and every link in the app follows.
///
/// Query form (`/b/?h=…`) rather than a path (`/b/…`) on purpose: GitHub Pages
/// has no rewrites, so a path would be served by 404.html with a 404 status,
/// and Telegram/Instagram don't build a link preview for a 404.
class FadeLinks {
  FadeLinks._();

  static const String host = 'thedarkknightmg.github.io/Fade';

  /// A client's friend invite, carrying their referral code.
  static String invite(String code) =>
      'https://$host/i/?c=${Uri.encodeQueryComponent(code)}';

  /// A barber's public booking link — also what their QR card encodes.
  static String booking(String handle) =>
      'https://$host/b/?h=${Uri.encodeQueryComponent(handle)}';

  /// Shown without the scheme, e.g. under the QR card.
  static String bookingDisplay(String handle) => '$host/b/?h=$handle';

  /// A shop owner's invite for colleagues to join the shop's roster.
  static String join(String shopId) =>
      'https://$host/join/?s=${Uri.encodeQueryComponent(shopId)}';
}
