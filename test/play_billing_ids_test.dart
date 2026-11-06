import 'package:barber_app/core/payments/play_billing.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

// The Play product ids the app buys must be the ones the server verifies
// (supabase/functions/_shared/play_core.ts), or a real purchase would be
// refused as "unknown product" after the person has paid.
void main() {
  test('every boost pack maps to a server-known Play product and back', () {
    const serverKnown = {
      'fade_boost_starter': 3,
      'fade_boost_growth': 10,
      'fade_boost_pro': 25,
    };
    for (final pack in AppState.boostPacks) {
      final id = PlayBilling.boostProductId(pack.id);
      expect(serverKnown[id], pack.count, reason: id);
      expect(PlayBilling.packIdOf(id), pack.id);
    }
    expect(PlayBilling.vipProductId, 'fade_vip_monthly');
    expect(AppState.vipMonthlyBoosts, 5); // what the server grants with VIP
    expect(PlayBilling.packIdOf(PlayBilling.vipProductId), isNull);
  });
}
