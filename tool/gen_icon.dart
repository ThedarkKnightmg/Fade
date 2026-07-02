// Generates the Fade app icon — LIGHT version of the intro badge:
// a soft near-white square with blue barber scissors in the diagonal
// Material "content_cut" style (two finger rings on the lower-left, blades
// crossing at a pivot and sweeping to pointed tips on the upper/lower right).
// Run:  dart run tool/gen_icon.dart   then  flutter pub run flutter_launcher_icons
import 'dart:io';

import 'package:image/image.dart' as img;

void main() {
  const s = 1024;
  final bg = img.ColorRgb8(0xED, 0xF2, 0xFB); // light background
  final blue = img.ColorRgb8(0x2E, 0x8B, 0xFF); // accent — blue scissors

  final im = img.Image(width: s, height: s);
  img.fill(im, color: bg);

  final th = (s * 0.052).round();

  // Finger rings on the left (stacked), pointed blade tips on the right.
  const ring1 = [344, 344]; // upper-left finger hole
  const ring2 = [344, 680]; // lower-left finger hole
  const tipLower = [792, 764]; // lower-right blade tip
  const tipUpper = [792, 260]; // upper-right blade tip (the prominent sweep)

  void blade(List<int> a, List<int> b) {
    img.drawLine(im,
        x1: a[0], y1: a[1], x2: b[0], y2: b[1],
        color: blue, thickness: th, antialias: true);
    img.fillCircle(im,
        x: b[0], y: b[1], radius: (th / 2).round(), color: blue, antialias: true);
  }

  // Each blade runs from a finger hole through the pivot to the opposite tip.
  blade(ring1, tipLower);
  blade(ring2, tipUpper);

  // Finger rings (blue, with a bg-punched hole). Drawn after the blades so the
  // holes stay clean and the blades read as emerging from the rings.
  final rO = (s * 0.082).round();
  final rI = (s * 0.046).round();
  for (final c in [ring1, ring2]) {
    img.fillCircle(im, x: c[0], y: c[1], radius: rO, color: blue, antialias: true);
    img.fillCircle(im, x: c[0], y: c[1], radius: rI, color: bg, antialias: true);
  }

  // Pivot screw where the blades cross.
  img.fillCircle(im,
      x: 512, y: 512, radius: (s * 0.03).round(), color: blue, antialias: true);

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/icon_full.png').writeAsBytesSync(img.encodePng(im));
  stdout.writeln('wrote assets/icon/icon_full.png (${im.width}x${im.height})');
}
