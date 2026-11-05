import 'package:barber_app/core/i18n/app_language.dart';
import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/data/mock_data.dart';
import 'package:barber_app/presentation/screens/barber/barber_requests_screen.dart';
import 'package:barber_app/presentation/screens/barber/barber_schedule_screen.dart';
import 'package:barber_app/presentation/screens/barber/barber_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The schedule's day grid used to lay out 40px wide (a Stack of Positioned
// blocks has no width of its own, and the screen's Column let it shrink), so
// every booking was clipped and barbers saw an empty schedule. Finding the
// widgets in the tree wasn't enough to catch that; this checks they are
// actually on screen and wide.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('the day grid fills the width and shows the bookings',
      (t) async {
    // Unrelated overflows elsewhere in the shell shouldn't fail this test.
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);

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
    expect(s.barberBookingsOn(DateTime.now()), isNotEmpty);

    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const BarberShell()));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
    await t.tap(find.text(L.navSchedule).last);
    for (var i = 0; i < 8; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }

    final grid = find.descendant(
      of: find.byType(BarberScheduleScreen),
      matching: find.byType(SingleChildScrollView),
    );
    expect(t.getSize(grid).width, greaterThan(300));

    // At least one booking is on screen and can be tapped.
    final name = s.barberBookingsOn(DateTime.now()).first.clientName ?? '';
    final onScreen = find.descendant(
      of: find.byType(BarberScheduleScreen),
      matching: find.textContaining(name.split(' ').first),
    );
    expect(onScreen.hitTestable(), findsWidgets);

    // ...and every block stays inside the grid's right padding instead of
    // running off the screen edge.
    final gridRight = t.getRect(grid).right - 20;
    final texts = find.descendant(of: grid, matching: find.byType(Text));
    for (final e in texts.evaluate()) {
      final rb = e.renderObject! as RenderBox;
      final right = rb.localToGlobal(Offset(rb.size.width, 0)).dx;
      expect(right, lessThanOrEqualTo(gridRight + 0.5),
          reason: '"${(e.widget as Text).data}" runs past the edge');
    }

    // Let the shell's demo request timer fire and settle before teardown.
    await t.pump(const Duration(seconds: 6));
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('request cards show the booking time in full', (t) async {
    // Tests draw text in a placeholder font about twice as wide as Nunito,
    // so other rows can overflow here that don't on a phone; this test is
    // only about the time chip, which must fit even in that wider font.
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);
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

    for (final lang in AppLanguage.values) {
      s.setLanguage(lang);
      Intl.defaultLocale = lang.name;
      t.view.physicalSize = const Size(360, 800); // a small phone
      t.view.devicePixelRatio = 1.0;
      await t.pumpWidget(MaterialApp(
          theme: AppTheme.light, home: const BarberRequestsScreen()));
      for (var i = 0; i < 5; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      // The time chip's label is the one containing ' · ' and a clock time.
      final times = find.byWidgetPredicate((w) =>
          w is Text && RegExp(r'·.*\d{1,2}:\d{2}').hasMatch(w.data ?? ''));
      expect(times, findsWidgets, reason: lang.name);
      for (final e in times.evaluate()) {
        final para = e.renderObject! as RenderParagraph;
        expect(para.didExceedMaxLines, isFalse,
            reason: '${lang.name}: "${(e.widget as Text).data}" was cut off');
      }
    }
    t.view.resetPhysicalSize();
    t.view.resetDevicePixelRatio();
  });
}
