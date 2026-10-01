import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/presentation/screens/onboarding/barber_registration_screen.dart';
import 'package:barber_app/presentation/screens/onboarding/role_choice_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Barber setup is always the ONLY route: sign-in, registration and the splash
// resume all reach it with pushAndRemoveUntil(..., (r) => false). Its back
// arrow used maybePop(), which does nothing on a root route, so the button
// looked dead. These pin the fix.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppState.instance.signOut();
  });

  Future<void> openAsOnlyRoute(WidgetTester t) async {
    t.view.physicalSize = const Size(420, 1400);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const BarberRegistrationScreen(),
    ));
    await t.pump(const Duration(milliseconds: 800));
  }

  testWidgets('back arrow asks to leave, and Stay keeps the screen',
      (t) async {
    await openAsOnlyRoute(t);
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(L.leaveBarberSetupQ), findsOneWidget);

    await t.tap(find.text(L.stay));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(L.leaveBarberSetupQ), findsNothing);
    expect(find.byType(BarberRegistrationScreen), findsOneWidget);
  });

  testWidgets('confirming signs out and returns to the role choice',
      (t) async {
    await openAsOnlyRoute(t);
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text(L.signOut));
    // The dialog closes, then the role choice is pushed: let a few frames run.
    for (var i = 0; i < 6; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }

    expect(find.byType(RoleChoiceScreen), findsOneWidget);
    expect(find.byType(BarberRegistrationScreen), findsNothing);
    expect(AppState.instance.authStage, AuthStage.anonymous);
  });

  testWidgets('the Android back gesture takes the same path', (t) async {
    await openAsOnlyRoute(t);
    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text(L.leaveBarberSetupQ), findsOneWidget);
    expect(find.byType(BarberRegistrationScreen), findsOneWidget);
  });

  testWidgets('no phone on the account is not shown as verified', (t) async {
    await openAsOnlyRoute(t); // signed out: the account has no number
    expect(find.text(L.barberPhoneMissing), findsOneWidget);
    expect(find.text(L.barberPhoneChatOnly), findsOneWidget);
    expect(find.text(L.barberPhoneVerified), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);
  });
}
