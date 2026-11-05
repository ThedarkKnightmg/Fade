import 'package:barber_app/core/i18n/strings.dart';
import 'package:barber_app/core/theme/app_theme.dart';
import 'package:barber_app/data/app_state.dart';
import 'package:barber_app/presentation/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The home tiles have an entrance "clipper pass", a press pop and a scroll
// lean. With reduced motion none of it may stand between a person and the
// tiles: they must be fully there and tappable on the first frame.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('with reduced motion the tiles are there at once', (t) async {
    SharedPreferences.setMockInitialValues({'locPrompt': true});
    await AppState.instance.load();
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });

    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: const Scaffold(body: HomeScreen()),
    ));
    await t.pump(); // one frame, no time for any entrance

    for (final label in [L.quickBook, L.quickAi, L.quickNear, L.quickCuts]) {
      expect(find.text(label).hitTestable(), findsOneWidget, reason: label);
    }
    // No reveal mask in the tree: nothing is half-drawn.
    expect(
      find.descendant(
          of: find.byType(HomeScreen), matching: find.byType(ShaderMask)),
      findsNothing,
    );
    await t.pump(const Duration(seconds: 2));
  });

  testWidgets('stickers stay still while the page scrolls', (t) async {
    SharedPreferences.setMockInitialValues({'locPrompt': true});
    await AppState.instance.load();
    t.view.physicalSize = const Size(390, 900);
    t.view.devicePixelRatio = 1.0;
    addTearDown(() {
      t.view.resetPhysicalSize();
      t.view.resetDevicePixelRatio();
    });
    final prev = FlutterError.onError;
    FlutterError.onError = (d) {
      if (d.exceptionAsString().contains('overflowed')) return;
      prev?.call(d);
    };
    addTearDown(() => FlutterError.onError = prev);

    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: HomeScreen()),
    ));
    await t.pump(const Duration(seconds: 4)); // entrance + glint done

    final sticker = find.byWidgetPredicate((w) =>
        w is Image &&
        w.image is ResizeImage &&
        ((w.image as ResizeImage).imageProvider as AssetImage).assetName ==
            'assets/tiles/book.png');
    final label = find.text(L.quickBook);
    Offset gap() => t.getCenter(sticker) - t.getCenter(label);
    final rest = gap();

    // Mid-scroll, frame by frame: the sticker keeps its place on its tile.
    // The drag starts below the tiles, so no tile is pressed (a press dips
    // the card, which is a different thing).
    final g = await t.startGesture(const Offset(195, 760));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(0, -18));
      await t.pump(const Duration(milliseconds: 16));
      expect((gap() - rest).distance, lessThan(0.01));
    }
    await g.up();
    await t.pump(const Duration(seconds: 2));
  });
}
