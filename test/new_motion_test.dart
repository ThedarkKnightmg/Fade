import 'package:barber_app/core/i18n/app_language.dart';
import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:barber_app/data/models/booking.dart';
import 'package:barber_app/presentation/screens/barber/barber_requests_screen.dart';
import 'package:barber_app/presentation/widgets/heart_burst.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// New motion must never change WHAT happens, only how it looks:
//  * Accepting a request with the button now plays the swipe's exit first,
//    so the answer must still land (after the card leaves), and with reduced
//    motion it must land at once.
//  * The favourite heart's sparks play when saving, and not at all with
//    reduced motion.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<AppState> barber() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting();
    final s = AppState.instance;
    await s.load();
    s.signInWithIdentity(
      id: 'b',
      fullName: 'Rustam Aliev',
      phone: '+998935550011',
      role: AppRole.barber,
      method: AuthMethod.telegram,
    );
    s.registerBarber(RegisteredBarber(
      firstName: 'Rustam',
      surname: 'Aliev',
      age: 27,
      phone: '+998935550011',
      shopId: MockData.demoShops.first.id,
    ));
    s.setLanguage(AppLanguage.en);
    Intl.defaultLocale = 'en';
    return s;
  }

  void ignoreOverflow() {
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);
  }

  for (final reduce in [false, true]) {
    testWidgets(
        'Accept by button confirms the request'
        '${reduce ? ' at once (reduced motion)' : ' after the card leaves'}',
        (t) async {
      ignoreOverflow();
      final s = await barber();
      expect(s.incomingRequests, isNotEmpty);
      final id = s.incomingRequests.first.id;
      BookingStatus status() => s.bookings.firstWhere((b) => b.id == id).status;

      t.view.physicalSize = const Size(390, 1400);
      t.view.devicePixelRatio = 1.0;
      addTearDown(() {
        t.view.resetPhysicalSize();
        t.view.resetDevicePixelRatio();
      });
      await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        ),
        home: const BarberRequestsScreen(),
      ));
      await t.pump(const Duration(milliseconds: 600));

      await t.tap(find.text(L.confirmBooking).first);
      await t.pump();
      if (reduce) {
        expect(status(), BookingStatus.upcoming);
      } else {
        // Mid-exit: the card is leaving, the answer hasn't been given yet.
        await t.pump(const Duration(milliseconds: 150));
        expect(status(), BookingStatus.requested);
        await t.pump(const Duration(milliseconds: 500));
        expect(status(), BookingStatus.upcoming);
      }
      await t.pump(const Duration(seconds: 3)); // let the toast go
    });
  }

  for (final reduce in [false, true]) {
    testWidgets('heart sparks ${reduce ? 'stay off' : 'play'} when saving',
        (t) async {
      var saved = false;
      await t.pumpWidget(MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, set) => HeartBurstButton(
                saved: saved,
                onTap: () => set(() => saved = !saved),
              ),
            ),
          ),
        ),
      ));
      int paints() => find
          .descendant(
              of: find.byType(HeartBurstButton),
              matching: find.byType(CustomPaint))
          .evaluate()
          .length;
      final before = paints();
      await t.tap(find.byType(HeartBurstButton));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      expect(saved, isTrue);
      expect(paints(), reduce ? before : before + 1);
      await t.pump(const Duration(seconds: 1));
    });
  }
}
