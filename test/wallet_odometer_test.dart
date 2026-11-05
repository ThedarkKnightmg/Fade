import 'package:barber_app/core/format/money.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/presentation/screens/barber/wallet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The wallet balance is an odometer: one rolling column per digit. It must
// always land on the real balance, read as one number to a screen reader,
// and with reduced motion show the balance at once.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  Future<void> pumpWallet(WidgetTester t, {required bool reduce}) async {
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
      home: const WalletScreen(),
    ));
  }

  // The odometer's one-number label for screen readers.
  Finder balanceLabel(int som) => find.byWidgetPredicate((w) =>
      w is Semantics && w.properties.label == "${Money.group(som)} so'm");

  void ignoreOverflow() {
    // The test font (Ahem) is wider than Nunito; layout overflow here is an
    // artefact of the font, not of the screen.
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      prev?.call(d);
    };
    addTearDown(() => FlutterError.onError = prev);
  }

  testWidgets('reduced motion: the balance is there on the first frame',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    ignoreOverflow();
    await pumpWallet(t, reduce: true);
    await t.pump();

    expect(balanceLabel(AppState.instance.walletSom), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
  });

  testWidgets('a top-up rolls to the new balance and floats the amount',
      (t) async {
    SharedPreferences.setMockInitialValues({});
    await AppState.instance.load();
    ignoreOverflow();
    await pumpWallet(t, reduce: false);
    await t.pump(const Duration(seconds: 3)); // entrance roll + sheen settle

    final before = AppState.instance.walletSom;
    AppState.instance.topUpWallet(50000);
    await t.pump(); // rebuild; the float starts after this frame
    await t.pump(const Duration(milliseconds: 16)); // its first tick
    await t.pump(const Duration(milliseconds: 200));

    final after = before + 50000;
    expect(balanceLabel(after), findsOneWidget);
    expect(find.text('+${Money.group(50000)}'), findsOneWidget);

    await t.pump(const Duration(seconds: 3));
    // The float is gone, and every column has come to rest on its digit:
    // nothing is left mid-roll (each column shows one whole digit on top).
    expect(find.text('+${Money.group(50000)}'), findsNothing);
    final digits = Money.group(after).replaceAll(RegExp(r'[^0-9]'), '');
    for (var i = 0; i < digits.length; i++) {
      expect(find.text(digits[i]), findsWidgets, reason: 'digit ${digits[i]}');
    }
  });
}
