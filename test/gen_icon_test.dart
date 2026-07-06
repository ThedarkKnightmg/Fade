// One-shot asset generator (run: flutter test test/gen_icon_test.dart).
// Renders the Fade badge from the animated intro — a deep-navy rounded square
// with the electric-blue content_cut_rounded scissors — into:
//   • assets/icon/icon_full.png        (legacy launcher, navy + scissors)
//   • assets/icon/icon_foreground.png  (adaptive foreground, scissors only)
//   • android/.../res/drawable/ic_stat_fade.png (white notif silhouette)
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _navy = Color(0xFF16294B);
const _blue = Color(0xFF2E8BFF);
const _scissors = Icons.content_cut_rounded;

Future<void> _writeBadge({
  required String path,
  required int size,
  required bool background, // navy fill vs transparent
  required double glyphFrac, // glyph size as fraction of canvas
  required Color glyphColor,
}) async {
  final s = size.toDouble();
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, s, s));

  if (background) {
    canvas.drawRect(Rect.fromLTWH(0, 0, s, s), Paint()..color = _navy);
    // A soft top-left glow, echoing the badge's lit look.
    canvas.drawCircle(
      Offset(s * 0.32, s * 0.28),
      s * 0.5,
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(s * 0.32, s * 0.28),
          s * 0.5,
          [_blue.withValues(alpha: 0.28), _blue.withValues(alpha: 0)],
        ),
    );
  }

  final tp = TextPainter(textDirection: TextDirection.ltr);
  tp.text = TextSpan(
    text: String.fromCharCode(_scissors.codePoint),
    style: TextStyle(
      fontSize: s * glyphFrac,
      fontFamily: _scissors.fontFamily,
      package: _scissors.fontPackage,
      color: glyphColor,
    ),
  );
  tp.layout();
  tp.paint(canvas, Offset((s - tp.width) / 2, (s - tp.height) / 2));

  final img = await recorder.endRecording().toImage(size, size);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  final f = File(path);
  f.parent.createSync(recursive: true);
  f.writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('generate Fade icons', (tester) async {
    // Real file I/O + image encoding must run outside the test's fake-async
    // zone, or toImage()/toByteData() never complete.
    await tester.runAsync(() async {
      // Load the real MaterialIcons font so the scissors glyph renders.
      final otf = File(
          r'C:\src\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf');
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(otf.readAsBytesSync().buffer.asByteData()));
      await loader.load();

      await _writeBadge(
        path: 'assets/icon/icon_full.png',
        size: 1024,
        background: true,
        glyphFrac: 0.52,
        glyphColor: _blue,
      );
      // Adaptive foreground: scissors kept inside the ~66% safe zone.
      await _writeBadge(
        path: 'assets/icon/icon_foreground.png',
        size: 1024,
        background: false,
        glyphFrac: 0.40,
        glyphColor: _blue,
      );
      // Notification small icon: white silhouette on transparent (Android
      // masks by alpha), tinted with the accent color at show-time.
      await _writeBadge(
        path: 'android/app/src/main/res/drawable/ic_stat_fade.png',
        size: 96,
        background: false,
        glyphFrac: 0.86,
        glyphColor: Colors.white,
      );
    });

    expect(File('assets/icon/icon_full.png').lengthSync(), greaterThan(0));
  });
}
