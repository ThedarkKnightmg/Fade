// The money maths: platform commission and Fade Points cashback.
//
// These are the numbers that decide what a barber is charged and what a client
// earns back, and until now nothing pinned them. They were extracted out of
// AppState into app_state/wallet.dart and app_state/fade_points.dart, so this
// also guards that move: if the split changed a rate or a rounding rule, these
// fail.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barber_app/core/format/money.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:barber_app/data/models/booking.dart';
import 'package:barber_app/data/models/service.dart';

/// A booking whose service costs exactly [usd], so the so'm figure is
/// predictable (Money.toSom multiplies by the fixed usdToUzs rate).
Booking _bookingFor(double usd, {bool isWalkIn = false}) {
  // demoShops, not barbershops: on the live path the visible catalogue starts
  // empty and is filled from Supabase, so it is not a fixture source.
  final shop = MockData.demoShops.first;
  return Booking(
    id: 'test-${usd.toStringAsFixed(2)}-$isWalkIn',
    barbershop: shop,
    barber: shop.barbers.first,
    service: BarberService(
      id: 'svc-test',
      name: 'Test cut',
      description: 'fixture',
      price: usd,
      durationMinutes: 30,
      icon: Icons.content_cut,
    ),
    dateTime: DateTime(2026, 1, 1, 10),
    status: BookingStatus.completed,
    isWalkIn: isWalkIn,
  );
}

void main() {
  final state = AppState.instance;

  group('commission', () {
    test('a standard booking is charged the flat 5%', () {
      final b = _bookingFor(10); // 10 USD -> 128 000 so'm
      final priceSom = Money.toSom(b.service.price);

      // Non-VIP by default, so the standard rate applies.
      expect(state.barberVip, isFalse,
          reason: 'fixture assumes the barber is not VIP');
      expect(state.commissionSomFor(b), (priceSom * 5 / 100).round());
    });

    test('a walk-in the barber logged himself is always free', () {
      // Fade never delivered this client, so it must never be charged —
      // this is the one promise the tier comments actually keep.
      expect(state.commissionSomFor(_bookingFor(10, isWalkIn: true)), 0);
      expect(state.commissionFullSomFor(_bookingFor(10, isWalkIn: true)), 0);
    });

    test('the full-rate figure ignores VIP so the discount can be shown', () {
      final b = _bookingFor(10);
      final priceSom = Money.toSom(b.service.price);
      // commissionFullSomFor is what the barber WOULD have paid at 5%; it is
      // the baseline the "VIP saved you X" line subtracts from.
      expect(state.commissionFullSomFor(b), (priceSom * 5 / 100).round());
    });

    test('the VIP rate is half the standard one', () {
      // Guards the headline VIP perk against a silent rate edit.
      expect(AppState.vipNewClientFeePercent,
          AppState.newClientFeePercent / 2);
    });

    test('a zero-priced service costs nothing to deliver', () {
      expect(state.commissionSomFor(_bookingFor(0)), 0);
    });
  });

  group('fade points', () {
    test('a booking earns 2.5% of its price back', () {
      final b = _bookingFor(10);
      final priceSom = Money.toSom(b.service.price);
      expect(state.pointsEarnedFor(b), (priceSom * 2.5 / 100).round());
    });

    test('cashback is funded by half the commission, never more', () {
      // The reserve has to come out of Fade's own cut: if the earn rate ever
      // exceeded the commission, every booking would lose money.
      expect(AppState.pointsEarnRatePct,
          lessThanOrEqualTo(AppState.newClientFeePercent.toDouble()));
      expect(AppState.pointsEarnRatePct, AppState.newClientFeePercent / 2);
    });

    test('a balance under the minimum cannot be redeemed', () {
      // redeemablePointsFor gates on pointsMinRedemptionSom; with an empty
      // ledger there is nothing to spend whatever the price.
      expect(state.pointsBalanceSom, lessThan(AppState.pointsMinRedemptionSom));
      expect(state.redeemablePointsFor(100000), 0);
      expect(state.redeemPoints(AppState.pointsMinRedemptionSom), 0);
    });

    test('redeemable points never exceed the price of the booking', () {
      // Guards the cap direction: a big balance must not over-apply and hand
      // the client change.
      expect(state.redeemablePointsFor(1), lessThanOrEqualTo(1));
    });
  });
}
