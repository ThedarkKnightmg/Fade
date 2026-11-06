import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/presentation/screens/game/clean_line_game.dart';
import 'package:barber_app/presentation/screens/game/scissor_master_game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Playtesting found both games ending a newcomer's run before they had learned
// the controls:
//  * Scissor Master: the first tuft fell ~1.8s in and every miss cost a life,
//    so an idle (or just slow) player was out in about five seconds.
//  * Clean Line: touching down anywhere but the exact start counted as a slip
//    and ended the run on the first touch.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpGame(WidgetTester t, Widget game) async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    final previous = FlutterError.onError;
    FlutterError.onError = (d) {
      if (!d.exceptionAsString().contains('overflowed')) previous?.call(d);
    };
    addTearDown(() => FlutterError.onError = previous);
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    await t.pumpWidget(MaterialApp(theme: AppTheme.light, home: game));
    await t.pump();
  }

  Future<void> run(WidgetTester t, Duration d) async {
    const frame = Duration(milliseconds: 16);
    for (var e = Duration.zero; e < d; e += frame) {
      await t.pump(frame);
    }
  }

  testWidgets('Scissor Master: the warm-up keeps a newcomer in the game',
      (t) async {
    await pumpGame(t, const ScissorMasterGame());
    await t.tap(find.text(L.gamePlay));
    await t.pump();

    // Hands off for 7 seconds: inside the warm-up, misses cost nothing.
    await run(t, const Duration(seconds: 7));
    expect(find.text(L.gameOver), findsNothing);

    // ...but it IS a game: once the warm-up ends, misses count again.
    await run(t, const Duration(seconds: 14));
    expect(find.text(L.gameOver), findsOneWidget);
  });

  testWidgets('Clean Line: touching down away from the line is not a slip',
      (t) async {
    await pumpGame(t, const CleanLineGame());
    await t.tap(find.text(L.gamePlay));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    // A drag in the bottom corner, nowhere near the line.
    await t.dragFrom(const Offset(20, 780), const Offset(60, -10));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text(L.lineGameSlipped), findsNothing);
  });

  testWidgets('Clean Line: a slip costs a steady hand and retries the line',
      (t) async {
    await pumpGame(t, const CleanLineGame());
    await t.tap(find.text(L.gamePlay));
    await t.pump();
    await t.pump(const Duration(milliseconds: 50));

    // The field is the line painter's canvas. The line starts at 14% of its
    // width, somewhere between 36% and 58% of its height.
    final field = t.getRect(find.byWidgetPredicate((w) =>
        w is CustomPaint &&
        w.painter.runtimeType.toString() == '_LinePainter'));

    // Probe down the start column: touch, trace a little to the right, then
    // veer far off. Only the probe that lands on the start traces; the rest
    // are ignored (not slips), so exactly one slip happens.
    Future<bool> slipOnce() async {
      for (var fy = 0.34; fy <= 0.60; fy += 0.01) {
        final start = Offset(field.left + field.width * 0.14,
            field.top + field.height * fy);
        final g = await t.startGesture(start);
        for (var i = 1; i <= 8; i++) {
          await g.moveTo(start + Offset(i * 3.0, 0));
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.moveTo(start + const Offset(24, -220));
        await t.pump(const Duration(milliseconds: 16));
        await g.up();
        await t.pump(const Duration(milliseconds: 100));
        if (find.text(L.lineGameRetry).evaluate().isNotEmpty ||
            find.text(L.gameAgain).evaluate().isNotEmpty) {
          return true;
        }
      }
      return false;
    }

    expect(await slipOnce(), isTrue, reason: 'never found the line start');
    // First slip: a hand is lost, the run goes on.
    expect(find.text(L.lineGameHandsLeft(1)), findsOneWidget);
    await t.tap(find.text(L.lineGameRetry));
    await t.pump(const Duration(milliseconds: 100));

    // Second slip: no hands left, the run ends.
    expect(await slipOnce(), isTrue);
    expect(find.text(L.gameAgain), findsOneWidget);
    expect(find.text(L.lineGameRetry), findsNothing);
  });
}
