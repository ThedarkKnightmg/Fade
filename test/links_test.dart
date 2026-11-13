import 'package:barber_app/core/links.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Every link the app shares must point at a live page, and a barber's QR —
// new or printed before the switch — must still open their shop when scanned.
void main() {
  test('shared links use the live site, never the unhosted fade.uz', () {
    for (final url in [
      FadeLinks.invite('AB12CD'),
      FadeLinks.booking('davron'),
      FadeLinks.join('3f1c0a2e-0000-4000-8000-000000000000'),
    ]) {
      expect(url, startsWith('https://${FadeLinks.host}/'));
      expect(url, isNot(contains('fade.uz')));
    }
    expect(FadeLinks.invite('AB12CD'), endsWith('/i/?c=AB12CD'));
    expect(FadeLinks.booking('davron'), endsWith('/b/?h=davron'));
  });

  test('a scanned booking QR opens the barber\'s shop, old or new format', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState.instance;
    await s.load();
    // The live catalogue starts empty until Supabase answers — stand one in.
    final shop = MockData.demoShops.first;
    MockData.barbershops.add(shop);
    addTearDown(() => MockData.barbershops.remove(shop));
    final handle = AppState.handleFor(shop.barbers.first.name);

    for (final code in [
      FadeLinks.booking(handle), // current QR / shared link
      '${FadeLinks.booking(handle)}&lang=ru', // with extra params
      'https://fade.uz/b/$handle', // printed before the switch
      'fade.uz/b/$handle',
      handle, // typed by hand
    ]) {
      expect(s.shopFromBookingCode(code)?.id, shop.id, reason: code);
    }
    expect(s.shopFromBookingCode('https://${FadeLinks.host}/b/?h='), isNull);
  });
}
