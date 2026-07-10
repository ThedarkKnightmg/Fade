import 'dart:io';
import 'dart:math';

import 'package:image/image.dart' as img;

/// One-off: cut the barber-chair *station* diorama (chair + table + tools) out
/// of its baked light floor pedestal + frosted back wall, so it can sit
/// transparently on the Yozuvlar tile.
///
/// The outer background and the back wall are light and connected to the image
/// border, so an edge flood clears them. The floor pedestal is enclosed (a
/// faint rim blocks the edge flood), so we ALSO seed the flood from points on
/// the floor itself. The threshold sits between the darker silver leg/shadow
/// tones (~179) and the bright floor (~217), so the flood clears the floor but
/// the darker leg sections block it from climbing up into the table legs.
///
/// Run:  dart run tool/strip_floor.dart
void main() {
  const src = r'C:\Users\Victus\Downloads\Gemini_Generated_Image_3bxk2i3bxk2i3bxk.jpg';
  const out = 'assets/tiles/cuts.png';

  final bytes = File(src).readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    stderr.writeln('decode failed: $src');
    exit(1);
  }
  final image = decoded.convert(numChannels: 4);
  final w = image.width;
  final h = image.height;
  stdout.writeln('src ${w}x$h');

  // Background = light AND near-neutral. Threshold 198 keeps the darker silver
  // legs/base (~179) and the navy subject; clears the ~217 floor + back wall.
  bool isBg(int x, int y) {
    final p = image.getPixel(x, y);
    final r = p.r.toDouble(), g = p.g.toDouble(), b = p.b.toDouble();
    final lum = 0.299 * r + 0.587 * g + 0.114 * b;
    final sat = [r, g, b].reduce(max) - [r, g, b].reduce(min);
    return lum > 184 && sat < 24;
  }

  final removed = List<bool>.filled(w * h, false);
  final stack = <int>[];
  void seed(int x, int y) {
    if (x < 0 || y < 0 || x >= w || y >= h) return;
    final i = y * w + x;
    if (removed[i]) return;
    if (isBg(x, y)) {
      removed[i] = true;
      stack.add(i);
    }
  }

  // Seed every border pixel (outer bg + connected back wall).
  for (var x = 0; x < w; x++) {
    seed(x, 0);
    seed(x, h - 1);
  }
  for (var y = 0; y < h; y++) {
    seed(0, y);
    seed(w - 1, y);
  }
  // Seed points ON the floor pedestal (fractions of the image, so it scales if
  // the source size changes). Spread across the front + mid + right floor.
  const floorSeeds = <List<double>>[
    [0.50, 0.88], [0.32, 0.86], [0.70, 0.85], [0.50, 0.78],
    [0.88, 0.80], [0.80, 0.74], [0.44, 0.92], [0.63, 0.91],
    [0.24, 0.80], [0.58, 0.83], [0.90, 0.66], [0.36, 0.90],
  ];
  for (final s in floorSeeds) {
    seed((s[0] * w).round(), (s[1] * h).round());
  }

  // 8-connected flood so thin rims/anti-aliased seams don't stop it.
  const dirs = [
    [1, 0], [-1, 0], [0, 1], [0, -1],
    [1, 1], [1, -1], [-1, 1], [-1, -1],
  ];
  while (stack.isNotEmpty) {
    final i = stack.removeLast();
    final x = i % w, y = i ~/ w;
    for (final d in dirs) {
      final nx = x + d[0], ny = y + d[1];
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      final ni = ny * w + nx;
      if (removed[ni]) continue;
      if (isBg(nx, ny)) {
        removed[ni] = true;
        stack.add(ni);
      }
    }
  }

  for (var i = 0; i < removed.length; i++) {
    if (removed[i]) image.setPixelRgba(i % w, i ~/ w, 0, 0, 0, 0);
  }

  // Feather the light fringe left on the subject edge (no hard halo).
  final orth = [
    [1, 0], [-1, 0], [0, 1], [0, -1],
  ];
  var feathered = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (removed[i]) continue;
      var edge = false;
      for (final d in orth) {
        final nx = x + d[0], ny = y + d[1];
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        if (removed[ny * w + nx]) {
          edge = true;
          break;
        }
      }
      if (!edge) continue;
      final p = image.getPixel(x, y);
      final lum = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      if (lum > 200) {
        final a = (255 * (1 - (lum - 200) / 55)).clamp(40, 255).toInt();
        image.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), a);
        feathered++;
      }
    }
  }

  // Auto-crop to the opaque content bounds (+ small padding).
  int minX = w, minY = h, maxX = 0, maxY = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (image.getPixel(x, y).a > 8) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }
  const pad = 16;
  minX = max(0, minX - pad);
  minY = max(0, minY - pad);
  maxX = min(w - 1, maxX + pad);
  maxY = min(h - 1, maxY + pad);
  final cropped = img.copyCrop(image,
      x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

  File(out).writeAsBytesSync(img.encodePng(cropped));
  final cleared = removed.where((e) => e).length;
  stdout.writeln('done -> $out  ${cropped.width}x${cropped.height}  '
      'cleared=$cleared  feathered=$feathered');
}
