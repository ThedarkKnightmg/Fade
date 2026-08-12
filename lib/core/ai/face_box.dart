import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Where the head actually is in a photo, in 0..1 fractions of the image.
///
/// [top] is the top of the detected skin region — i.e. roughly the forehead /
/// hairline — so the hair to repaint lives ABOVE it.
class FaceBox {
  const FaceBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final double left, top, right, bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
}

/// Find the head in a selfie by scanning for skin pixels, so the hair mask can
/// be anchored to the ACTUAL head instead of assuming it sits at a fixed spot
/// in the frame.
///
/// This is the whole reason the AI used to "draw elsewhere": the mask was
/// positioned by fixed fractions of the image, so any selfie framed closer,
/// further away or off-centre had its repaint zone land on the wrong place —
/// often the face instead of the hair.
///
/// Deliberately the same cheap on-device technique the face-shape analyzer
/// already uses (downscale to ~128px, threshold skin tones, take the extent):
/// no model download, no network, works offline. Returns null when it can't
/// find a confident face, and the caller falls back to the old fixed layout.
Future<FaceBox?> detectFaceBox(Uint8List photo) async {
  try {
    final codec = await ui.instantiateImageCodec(photo, targetWidth: 128);
    final frame = await codec.getNextFrame();
    final img = frame.image;
    final w = img.width;
    final h = img.height;
    final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    img.dispose();
    if (bd == null || w < 8 || h < 8) return null;
    final px = bd.buffer.asUint8List();

    // Ignore the extreme edges and the very bottom (clothing/background that
    // happens to read as skin).
    final x0 = (w * 0.08).floor();
    final x1 = (w * 0.92).ceil();
    final y1 = (h * 0.94).ceil();

    final rows = List<int>.filled(h, 0);
    final cols = List<int>.filled(w, 0);
    var skin = 0;
    var total = 0;
    for (var y = 0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        final i = (y * w + x) * 4;
        total++;
        if (_isSkin(px[i], px[i + 1], px[i + 2])) {
          skin++;
          rows[y]++;
          cols[x]++;
        }
      }
    }
    // Too little skin to trust (not a portrait, very dark shot, etc.).
    if (total == 0 || skin / total < 0.03) return null;

    // Vertical extent: rows carrying a meaningful amount of skin.
    final rowThresh = math.max(2, ((x1 - x0) * 0.10).round());
    var minY = -1, maxY = -1;
    for (var y = 0; y < y1; y++) {
      if (rows[y] >= rowThresh) {
        if (minY < 0) minY = y;
        maxY = y;
      }
    }
    if (minY < 0 || maxY <= minY) return null;

    // Horizontal extent, measured the same way.
    final colThresh = math.max(2, ((maxY - minY) * 0.10).round());
    var minX = -1, maxX = -1;
    for (var x = x0; x < x1; x++) {
      if (cols[x] >= colThresh) {
        if (minX < 0) minX = x;
        maxX = x;
      }
    }
    if (minX < 0 || maxX <= minX) return null;

    final box = FaceBox(
      left: minX / w,
      top: minY / h,
      right: maxX / w,
      bottom: maxY / h,
    );
    // Sanity: a plausible face occupies a reasonable slice of the frame. If the
    // "face" is the whole image or a sliver, we've detected noise.
    if (box.width < 0.12 || box.width > 0.95) return null;
    if (box.height < 0.12 || box.height > 0.98) return null;
    return box;
  } catch (_) {
    return null;
  }
}

/// Loose skin-tone test in RGB — matches the analyzer's, so both agree on what
/// counts as a face.
bool _isSkin(int r, int g, int b) {
  if (r < 60 || g < 30 || b < 15) return false;
  if (r <= g || r <= b) return false;
  final mx = math.max(r, math.max(g, b));
  final mn = math.min(r, math.min(g, b));
  if (mx - mn < 12) return false;
  return (r - g).abs() > 12 || (r - b) > 18;
}
