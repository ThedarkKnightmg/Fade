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
}
