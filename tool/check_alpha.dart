import 'dart:io';

import 'package:image/image.dart' as img;

/// Quick sanity check: prints the alpha at the corners (should be 0 —
/// transparent) and centre (should be opaque) of each stripped sticker.
void main() {
  for (final n in ['book', 'map']) {
    final im = img.decodePng(File('assets/tiles/$n.png').readAsBytesSync())!;
    int a(int x, int y) => im.getPixel(x, y).a.toInt();
    final w = im.width, h = im.height;
    stdout.writeln('$n ${w}x$h  '
        'TL=${a(0, 0)} TR=${a(w - 1, 0)} '
        'BL=${a(0, h - 1)} BR=${a(w - 1, h - 1)}  '
        'center=${a(w ~/ 2, h ~/ 2)}');
  }
}
