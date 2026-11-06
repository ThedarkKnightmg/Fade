import 'package:barber_app/core/utils/slot_fit.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:barber_app/data/models/booking.dart';
import 'package:barber_app/data/models/service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Booking rules found broken in the logic audit:
//  * only a cut's START slot was checked, so a long cut could overlap the
//    next booking or run past closing;
//  * accepting a request didn't check it was still a request, so a booking
//    the client had cancelled could be accepted back to life.
void main() {
  final day = DateTime.now().add(const Duration(days: 3));
  DateTime at(int h, [int m = 0]) =>
      DateTime(day.year, day.month, day.day, h, m);

  BarberService cut(int minutes) => BarberService(
        id: 'svc_$minutes',
        name: 'Cut $minutes',
        description: '',
        price: 10,
        durationMinutes: minutes,
        icon: Icons.content_cut_rounded,
      );

  group('unfitStarts', () {
    final slots = [for (var h = 9; h < 20; h++) ...[at(h), at(h, 30)]];

    test('a long cut cannot start where it would run into a booking', () {
      final bad = unfitStarts(
        slots: slots,
        taken: {at(10, 30)},
        minutes: 55,
        closesAt: at(20),
      );
      expect(bad, contains(at(10))); // 10:00-10:55 hits 10:30
      expect(bad, contains(at(10, 30))); // taken itself
      expect(bad, isNot(contains(at(9)))); // 9:00-9:55 is clear
      expect(bad, isNot(contains(at(11)))); // after it is clear
    });

    test('a cut must end by closing time', () {
      final bad = unfitStarts(
          slots: slots, taken: {}, minutes: 60, closesAt: at(20));
      expect(bad, contains(at(19, 30))); // would end 20:30
      expect(bad, isNot(contains(at(19)))); // ends exactly at 20:00
    });
  });

  group('AppState', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AppState.instance.load();
    });

    Booking booking(String id, DateTime when, int minutes,
            {BookingStatus status = BookingStatus.upcoming}) =>
        Booking(
          id: id,
          barbershop: MockData.demoShops.first,
          barber: MockData.demoShops.first.barbers.first,
          service: cut(minutes),
          dateTime: when,
          status: status,
          clientName: 'Test client',
        );

    test('addBooking rejects a cut that overlaps a later booking', () {
      final s = AppState.instance;
      expect(s.addBooking(booking('t_a', at(10, 30), 30)), isTrue);
      expect(s.addBooking(booking('t_b', at(10), 55)), isFalse);
      expect(s.addBooking(booking('t_c', at(9), 55)), isTrue);
    });

    test('a cancelled booking cannot be accepted back to life', () {
      final s = AppState.instance;
      s.addBooking(booking('t_x', at(15), 30, status: BookingStatus.requested));
      s.cancelBooking('t_x');
      BookingStatus status() => s.bookings.firstWhere((b) => b.id == 't_x').status;
      expect(status(), BookingStatus.cancelled);
      s.confirmBooking('t_x');
      expect(status(), BookingStatus.cancelled);
      s.declineBooking('t_x');
      expect(status(), BookingStatus.cancelled);
    });
  });
}
