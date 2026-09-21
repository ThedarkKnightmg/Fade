import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/presentation/screens/style/style_studio_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    AppState.instance.clearDesiredStyle();
  });

  // Drive the screen from the empty state to the try-on view on a phone-shaped
  // surface (so the 3:4 hero + cut selector all fit like on a real device).
  Future<void> reachTryOn(WidgetTester t) async {
    t.view.physicalSize = const Size(400, 1300);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });

    await t.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: const StyleStudioScreen()),
    );
    await t.pumpAndSettle();
    expect(find.text(L.addYourPhoto), findsOneWidget);

    // Matched through L rather than English literals: the app's default
    // language is Uzbek, and a UI test should assert which COPY is on screen,
    // not which language it happens to be rendered in.
    final demo = find.text(L.tryDemoFace);
    await t.ensureVisible(demo);
    await t.tap(demo);
    await t.pump(); // analysing
    expect(find.text(L.readingFace), findsOneWidget);
    await t.pump(const Duration(milliseconds: 900));
    await t.pump(const Duration(milliseconds: 900));
    await t.pump();
  }

  testWidgets('demo selfie lands on the try-on with a live preview', (t) async {
    await reachTryOn(t);

    expect(find.text(L.bookThisLook), findsOneWidget);
    expect(find.text(L.yourLook), findsOneWidget);
    expect(find.byType(Slider), findsOneWidget); // the "fit" size control
    expect(find.text(L.colourWord), findsOneWidget);
  });

  testWidgets('tapping a cut updates the chosen look', (t) async {
    await reachTryOn(t);

    // "Classic Taper" is the first thumb in the selector. Matched through
    // L.tr because style names are catalogue data translated at the display
    // site — the English literal only appears when the app is in English.
    final taper = find.text(L.tr('Classic Taper')).first;
    await t.ensureVisible(taper);
    await t.tap(taper);
    await t.pump();

    // It now shows as the selected look (book bar + detail card).
    expect(find.text(L.tr('Classic Taper')), findsWidgets);
    expect(find.text(L.bookThisLook), findsOneWidget);
  });

  testWidgets('new photo resets back to the add-photo screen', (t) async {
    await reachTryOn(t);

    await t.tap(find.text(L.newPhoto));
    await t.pumpAndSettle();

    expect(find.text(L.addYourPhoto), findsOneWidget);
    expect(find.text(L.bookThisLook), findsNothing);
  });
}
