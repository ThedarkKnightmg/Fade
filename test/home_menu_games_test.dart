import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Opening Games from the home menu used to pop twice: once to close the menu,
// and once more, which removed the home screen and left the games sheet over
// a black, empty navigator.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppState.instance.signOut();
  });

  testWidgets('Games from the home menu keeps the home screen underneath',
      (t) async {
    t.view.physicalSize = const Size(420, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreen()),
    ));
    // Let the home screen's entrance reveal finish before tapping it.
    for (var i = 0; i < 15; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }

    // With no saved address, home opens the location prompt on first launch.
    // Dismiss it, as a user would, before using the menu.
    Navigator.of(t.element(find.byType(HomeScreen)))
        .popUntil((route) => route.isFirst);
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }

    await t.tap(find.byIcon(Icons.menu_rounded));
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    await t.tap(find.text(L.gamesTitle).last);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }

    // The games sheet is up, and the home screen is still behind it.
    expect(find.text(L.lineGameTitle), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);

    // Dismissing the sheet lands back on home, not on an empty navigator.
    Navigator.of(t.element(find.text(L.lineGameTitle))).pop();
    for (var i = 0; i < 4; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
