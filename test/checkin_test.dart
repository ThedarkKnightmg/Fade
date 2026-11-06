import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:barber_app/data/models/booking.dart';
import 'package:barber_app/data/models/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Arrival check-in: the CLIENT scans the barber's printed poster; the barber
// never scans. At closing the barber marks who came, and the two accounts are
// compared.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
  });

  final shop = MockData.demoShops.first;
  final barber = shop.barbers.first;
  final today = DateTime.now();
  DateTime at(int h, [int m = 0]) =>
      DateTime(today.year, today.month, today.day, h, m);

  Booking mine(String id, DateTime when) => Booking(
        id: id,
        barbershop: shop,
        barber: barber,
        service: const BarberService(
          id: 's',
          name: 'Cut',
          description: '',
          price: 10,
          durationMinutes: 30,
          icon: Icons.content_cut_rounded,
        ),
        dateTime: when,
        status: BookingStatus.upcoming,
      );

  // The real poster code: on the demo device this barber IS the signed-in
  // barber, so the code is actually checked (a made-up one is refused).
  String poster(String barberId) =>
      'fade:barber:$barberId:${AppState.instance.checkinCode}';

  test('a client scan marks arrival, inside the check-in window only', () {
    final s = AppState.instance;
    // 19:00 is free in the demo diary (Aziz already holds 15:00).
    expect(s.addBooking(mine('c1', at(19))), isTrue);

    expect(s.clientCheckIn('hello', now: at(19)), CheckInResult.notFadeCode);
    expect(s.clientCheckIn(poster('someone-else'), now: at(19)),
        CheckInResult.noBookingHere);
    expect(s.clientCheckIn(poster(barber.id), now: at(17)),
        CheckInResult.tooEarly); // opens 18:15
    expect(s.clientCheckIn(poster(barber.id), now: at(20, 10)),
        CheckInResult.tooLate); // closes 20:00

    expect(s.clientCheckIn(poster(barber.id), nearShop: true, now: at(18, 50)),
        CheckInResult.ok);
    final b = s.bookings.firstWhere((b) => b.id == 'c1');
    expect(b.arrivedAt, at(18, 50));
    expect(b.arrivedNearShop, isTrue);
    // Arrival is not completion: the barber settles the visit at closing.
    expect(b.status, BookingStatus.upcoming);

    expect(s.clientCheckIn(poster(barber.id), now: at(18, 55)),
        CheckInResult.alreadyIn);
  });

  test('closing the day compares the barber with the clients', () {
    expect(AppState.dayOutcome(scanned: true, came: true), DayOutcome.verified);
    expect(AppState.dayOutcome(scanned: false, came: true), DayOutcome.unverified);
    expect(AppState.dayOutcome(scanned: true, came: false), DayOutcome.disputed);
    expect(AppState.dayOutcome(scanned: false, came: false), DayOutcome.noShow);
  });

  test('closeDay applies each outcome', () {
    final s = AppState.instance;
    Booking client(String id, String name, int hour, {bool scanned = false}) =>
        Booking(
          id: id,
          barbershop: shop,
          barber: barber,
          service: mine('x', at(9)).service,
          dateTime: at(hour),
          status: BookingStatus.upcoming,
          clientName: name,
          arrivedAt: scanned ? at(hour - 1, 58) : null,
        );
    for (final b in <Booking>[
      client('v', 'Vera', 6, scanned: true),
      client('u', 'Umar', 7),
      client('d', 'Dina', 8, scanned: true),
      client('n', 'Nodir', 9),
    ]) {
      expect(s.addBooking(b), isTrue, reason: b.id);
    }

    final counts = s.closeDay({'v': true, 'u': true, 'd': false, 'n': false});
    expect(counts[DayOutcome.verified], 1);
    expect(counts[DayOutcome.unverified], 1);
    expect(counts[DayOutcome.disputed], 1);
    expect(counts[DayOutcome.noShow], 1);

    Booking get(String id) => s.bookings.firstWhere((b) => b.id == id);
    expect(get('v').status, BookingStatus.completed);
    expect(get('v').isVerified, isTrue);
    expect(s.verifiedScanStreakFor('Vera'), 1);

    expect(get('u').status, BookingStatus.completed);
    expect(get('u').isVerified, isFalse);
    expect(s.verifiedScanStreakFor('Umar'), 0); // no proof, no VIP progress

    expect(get('d').status, BookingStatus.cancelled);
    expect(get('d').disputed, isTrue);
    expect(get('d').chargeIntent, isNull); // the client had proof: no fee

    expect(get('n').status, BookingStatus.noShow);
  });
}
