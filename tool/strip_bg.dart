import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

/// Removes the flat white/neutral background baked into the 3D sticker PNGs so
/// they sit transparently on the home tiles. Flood-fills inward from every
/// border pixel, clearing only the *connected* light-neutral region — interior
/// light pixels (teeth, eye whites, highlights) are kept because they aren't
/// reachable from the edge.
///
/// Run:  dart run tool/strip_bg.dart
void main(List<String> args) {
  final names = args.isNotEmpty ? args : ['book', 'map'];
  for (final name in names) {
    final path = 'assets/tiles/$name.png';
    final file = File(path);
    if (!file.existsSync()) {
      stdout.writeln('skip $name (not found)');
      continue;
    }
    final decoded = img.decodePng(file.readAsBytesSync());
    if (decoded == null) {
      stdout.writeln('skip $name (decode failed)');
      continue;
    }
    final image = decoded.convert(numChannels: 4);
    final w = image.width;
    final h = image.height;

    // A pixel counts as background if it's light AND near-neutral (so warm
    // skin highlights, which are light but saturated, survive).
    bool isBg(img.Pixel p) {
      final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
      final lum = 0.299 * r + 0.587 * g + 0.114 * b;
      final sat = [r, g, b].reduce(max) - [r, g, b].reduce(min);
      // Light AND near-neutral: catches white plus the soft gray contact
      // shadow the 3D render bakes around/under the badge. Warm skin and hair
      // (saturated) survive because of the low saturation gate.
      return lum > 185 && sat < 26;
    }

    final removed = List<bool>.filled(w * h, false);
    final stack = <int>[];
    void seed(int x, int y) {
      final i = y * w + x;
      if (removed[i]) return;
      if (isBg(image.getPixel(x, y))) {
        removed[i] = true;
        stack.add(i);
      }
    }

    for (var x = 0; x < w; x++) {
      seed(x, 0);
      seed(x, h - 1);
    }
    for (var y = 0; y < h; y++) {
      seed(0, y);
      seed(w - 1, y);
    }

    const dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ];
    while (stack.isNotEmpty) {
      final i = stack.removeLast();
      final x = i % w, y = i ~/ w;
      for (final d in dirs) {
        final nx = x + d[0], ny = y + d[1];
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        final ni = ny * w + nx;
        if (removed[ni]) continue;
        if (isBg(image.getPixel(nx, ny))) {
          removed[ni] = true;
          stack.add(ni);
        }
      }
    }

    // Clear the background.
    for (var i = 0; i < removed.length; i++) {
      if (removed[i]) image.setPixelRgba(i % w, i ~/ w, 0, 0, 0, 0);
    }

    // Feather: soften the light fringe left on the subject's edge so there's
    // no hard white halo against the gray card.
    var feathered = 0;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final i = y * w + x;
        if (removed[i]) continue;
        var nextToHole = false;
        for (final d in dirs) {
          final nx = x + d[0], ny = y + d[1];
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          if (removed[ny * w + nx]) {
            nextToHole = true;
            break;
          }
        }
        if (!nextToHole) continue;
        final p = image.getPixel(x, y);
        final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
        if (lum > 188) {
          final a = (255 * (1 - (lum - 188) / 67)).clamp(35, 255).toInt();
          image.setPixelRgba(
              x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), a);
          feathered++;
        }
      }
    }

    final cleared = removed.where((e) => e).length;
    file.writeAsBytesSync(img.encodePng(image));
    stdout.writeln(
        'done $name: ${w}x$h  cleared=$cleared  feathered=$feathered');
  }
}
