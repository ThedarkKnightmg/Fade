// The invariants that keep a client from booking a barbershop that isn't real.
//
// Background: the visible catalogue used to be seeded with five bundled demo
// shops and only replaced once Supabase answered. If that fetch was slow, empty
// or failed, a real user browsed and booked a demo shop — whose ids are demo
// strings, not database UUIDs, so `BookingRepository.createBooking` dropped the
// insert and returned null. The client kept a local booking and a confirmation
// screen; no barber ever received it. These tests pin the fix.
import 'package:barber_app/core/supabase/supabase_config.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalogue', () {
    test('the live path never ships bundled shops as the catalogue', () {
      // The whole point: with the real catalogue on, there is nothing bookable
      // until Supabase actually answers with shops.
      if (SupabaseConfig.useRealCatalogue) {
        expect(
          MockData.barbershops,
          isEmpty,
          reason: 'demo shops must not be pre-seeded into the live catalogue — '
              'a booking against one is silently dropped and never reaches a '
              'barber',
        );
      } else {
        expect(MockData.barbershops, isNotEmpty,
            reason: 'demo mode still needs a catalogue to show');
      }
    });

    test('demo shops remain available as seeding defaults', () {
      // A brand-new barber needs a starter service menu even when they are the
      // first shop in the city, i.e. when the live catalogue is legitimately
      // empty. That default comes from demoShops, which must stay usable.
      expect(MockData.demoShops, isNotEmpty);
      expect(MockData.demoShops.first.services, isNotEmpty);
      expect(MockData.demoShops.first.barbers, isNotEmpty);
    });

    test('fallbackShop is safe to read with an empty live catalogue', () {
      // Barber-side screens resolve their own shop through this. It must not
      // throw when nothing has loaded — that was the crash the old
      // "keep the mock list" fallback existed to dodge.
      expect(() => MockData.fallbackShop, returnsNormally);
      expect(MockData.fallbackShop.barbers, isNotEmpty);
    });

    test('catalogue getter exposes nothing unless the status says ready', () {
      final state = AppState.instance;
      if (state.catalogueStatus != CatalogueStatus.ready) {
        expect(state.catalogue, isEmpty);
        expect(state.catalogueReady, isFalse);
      }
      // Ready must mean "there are real shops", never "ready but empty" — that
      // combination is what would render a blank list with no explanation.
      if (state.catalogueReady) expect(state.catalogue, isNotEmpty);
    });

    test('a shop with no barbers is unbookable and must not be listed', () {
      // ShopRepository filters these out. Assert the property the filter
      // guarantees, so every shop the UI renders can actually take a booking
      // (and `shop.barbers.first` in the detail screen cannot throw).
      for (final shop in MockData.barbershops) {
        expect(shop.barbers, isNotEmpty, reason: '${shop.name} has no barbers');
      }
    });
  });
}
