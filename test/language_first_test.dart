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
// Tapping a language selects and previews it; Continue commits.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  // The selected card announces itself as selected (the check is drawn,
  // not an icon, so we ask the semantics instead).
  Finder selectedCards() => find.byWidgetPredicate((w) =>
      w is Semantics && w.properties.button == true && w.properties.selected == true);

  // Step time forward frame by frame, as a real screen would, so timers and
  // the animations they start interleave the way they do on a phone.
  Future<void> advance(WidgetTester t, int ms) async {
    for (var e = 0; e < ms; e += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> settle(WidgetTester t, [int frames = 6]) async {
    for (var i = 0; i < frames; i++) {
      await t.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> openPicker(
    WidgetTester t, {
    bool reduceMotion = false,
    Widget next = const Scaffold(body: Text('NEXT')),
  }) async {
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
      home: LanguageScreen(next: next),
    ));
    await settle(t, 5);
  }

  testWidgets('choosing Русский and pressing Далее opens the terms in Russian',
      (t) async {
    await openPicker(t, next: const ConsentScreen(next: SizedBox()));
    expect(AppState.instance.hasChosenLanguage, isFalse);

    await t.tap(find.text('Русский'));
    await settle(t);
    await t.tap(find.text('Далее'));
    await settle(t);

    expect(AppState.instance.language, AppLanguage.ru);
    expect(AppState.instance.hasChosenLanguage, isTrue);
    expect(find.byType(ConsentScreen), findsOneWidget);
    expect(find.text('Прежде чем начать'), findsOneWidget);
  });

  testWidgets('a tap only selects; you can change it; Continue commits',
      (t) async {
    await openPicker(t);
    // Nothing chosen yet: no button to press.
    expect(find.text('Davom etish'), findsNothing);

    await t.tap(find.text('English'));
    await settle(t);
    // Selected and previewed, but not committed and not navigated.
    expect(selectedCards(), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('NEXT'), findsNothing);
    expect(AppState.instance.language, AppLanguage.en);
    expect(AppState.instance.hasChosenLanguage, isFalse);

    // Changing your mind moves the selection and the button's language.
    await t.tap(find.text('Русский'));
    await settle(t);
    expect(selectedCards(), findsOneWidget);
    expect(find.text('Далее'), findsOneWidget);
    expect(find.text('Continue'), findsNothing);

    await t.tap(find.text('Далее'));
    await settle(t);
    expect(find.text('NEXT'), findsOneWidget);
    expect(AppState.instance.language, AppLanguage.ru);
    expect(AppState.instance.hasChosenLanguage, isTrue);
  });

  testWidgets('the heading takes turns asking in each language', (t) async {
    await openPicker(t);
    expect(find.text('Tilni tanlang'), findsOneWidget);

    await advance(t, 2400); // the next phrase sweeps in
    expect(find.text('Выберите язык'), findsOneWidget);
    expect(find.text('Tilni tanlang'), findsNothing);

    await advance(t, 2400);
    expect(find.text('Choose your language'), findsOneWidget);

    // Picking stops the cycle and the heading settles on the choice.
    await t.tap(find.text("O'zbekcha"));
    await settle(t);
    await t.pump(const Duration(seconds: 3));
    await settle(t);
    expect(find.text('Tilni tanlang'), findsOneWidget);
  });

  testWidgets('with reduced motion nothing cycles and Continue still works',
      (t) async {
    await openPicker(t, reduceMotion: true);
    // All three phrases at once, standing still.
    expect(find.text('Tilni tanlang'), findsOneWidget);
    expect(find.text('Выберите язык · Choose your language'), findsOneWidget);
    await t.pump(const Duration(seconds: 5));
    expect(find.text('Tilni tanlang'), findsOneWidget);

    await t.tap(find.text("O'zbekcha"));
    await t.pump();
    await t.tap(find.text('Davom etish'));
    await settle(t, 3);
    expect(find.text('NEXT'), findsOneWidget);
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

  test('a previewed language is not remembered as a choice', () async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    AppState.instance.previewLanguage(AppLanguage.ru);
    await Future<void>.delayed(const Duration(milliseconds: 50)); // autosave

    await AppState.instance.load();
    expect(AppState.instance.hasChosenLanguage, isFalse);
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
}
