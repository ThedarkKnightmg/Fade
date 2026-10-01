import 'package:barber_app/core/i18n/app_language.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/presentation/screens/legal/consent_screen.dart';
import 'package:barber_app/presentation/screens/onboarding/language_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A first-time user is asked for a language before anything else, because the
// Terms and Privacy Policy follow and must be readable to mean anything.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('picking a language switches the app, then shows the terms in it',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    expect(AppState.instance.hasChosenLanguage, isFalse);

    t.view.physicalSize = const Size(420, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const LanguageScreen(
        next: ConsentScreen(next: SizedBox()),
      ),
    ));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }

    await t.tap(find.text('Русский'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }

    expect(AppState.instance.language, AppLanguage.ru);
    expect(AppState.instance.hasChosenLanguage, isTrue);
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.text('Прежде чем начать'), findsOneWidget);
  });

  test('the choice survives a restart', () async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    AppState.instance.setLanguage(AppLanguage.en);
    await Future<void>.delayed(const Duration(milliseconds: 50)); // autosave

    await AppState.instance.load();
    expect(AppState.instance.hasChosenLanguage, isTrue);
    expect(AppState.instance.language, AppLanguage.en);
  });

  test('people signed in before this update are not asked again', () async {
    SharedPreferences.setMockInitialValues({
      'auth_stage': 'ready',
      'auth_method': 'telegram',
      'lang': 'ru',
    });
    await AppState.instance.load();
    expect(AppState.instance.hasChosenLanguage, isTrue);
  });

  test('a fresh install is asked', () async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    expect(AppState.instance.hasChosenLanguage, isFalse);
  });

  Future<void> openPicker(WidgetTester t, {bool reduceMotion = false}) async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    t.view.physicalSize = const Size(420, 1000);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: const LanguageScreen(next: Scaffold(body: Text('NEXT'))),
    ));
    for (var i = 0; i < 5; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('the heading takes turns asking in each language', (t) async {
    await openPicker(t);
    expect(find.text('Tilni tanlang'), findsOneWidget);

    await t.pump(const Duration(milliseconds: 2400)); // next phrase
    await t.pump(const Duration(milliseconds: 500)); // swap finishes
    expect(find.text('Выберите язык'), findsOneWidget);
    expect(find.text('Tilni tanlang'), findsNothing);

    await t.pump(const Duration(milliseconds: 2400));
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Choose your language'), findsOneWidget);

    // Leave cleanly: picking stops the cycle before the screen is replaced.
    await t.tap(find.text('English'));
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  });

  testWidgets('a tap confirms with a check, then moves on', (t) async {
    await openPicker(t);
    await t.tap(find.text('English'));
    await t.pump(const Duration(milliseconds: 300));

    // Confirming: the chosen card shows a check and the heading speaks
    // the chosen language; nothing has navigated yet.
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Choose your language'), findsOneWidget);
    expect(find.text('NEXT'), findsNothing);

    // A second tap while confirming is ignored.
    await t.tap(find.text('Русский'), warnIfMissed: false);
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('NEXT'), findsOneWidget);
    expect(AppState.instance.language, AppLanguage.en);
  });

  testWidgets('with reduced motion nothing cycles and the tap goes straight on',
      (t) async {
    await openPicker(t, reduceMotion: true);
    // All three phrases at once, standing still.
    expect(find.text('Tilni tanlang'), findsOneWidget);
    expect(find.text('Выберите язык · Choose your language'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    expect(find.text('Tilni tanlang'), findsOneWidget);

    await t.tap(find.text("O'zbekcha"));
    await t.pump(); // no confirm hold
    await t.pump(const Duration(milliseconds: 600));
    expect(find.text('NEXT'), findsOneWidget);
  });
}
