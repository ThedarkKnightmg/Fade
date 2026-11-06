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
    double? hairTop,
  }) : hairTop = hairTop ?? top;

  final double left, top, right, bottom;

  /// Where the person's CURRENT hair ends at the top (0..1), found by walking
  /// up from the forehead until the pixels look like the background. Tall
  /// hair (a pompadour, curls) reaches far above where a short new style
  /// would; the mask has to cover it too, or a crop leaves the old tuft on.
  final double hairTop;

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
    final gate = SkinGate.calibrate(px, w, h);

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
        if (gate.isSkin(px[i], px[i + 1], px[i + 2])) {
          skin++;
          rows[y]++;
          cols[x]++;
        }
      }
    }
    // Too little skin to trust (not a portrait, very dark shot, etc.).
    if (total == 0 || skin / total < 0.03) return null;

    // Vertical extent: rows carrying a meaningful amount of skin.
    // A face row is half skin or more; stray hair highlights stay far below
    // 18%, so this keeps them out of the face's extent.
    final rowThresh = math.max(2, ((x1 - x0) * 0.18).round());
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
      hairTop: _hairTop(px, w, minY, minX, maxX) / h,
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

/// The highest row above [faceTop] that still has hair across the head's
/// width: rows where a quarter or more of the pixels differ clearly from the
/// background, read from the two top corners. Stops at the first run of
/// background rows, so a busy backdrop above the head can't drag it up.
int _hairTop(Uint8List px, int w, int faceTop, int minX, int maxX) {
  if (maxX <= minX || faceTop <= 0) return faceTop;
  // Background colour: the two top corners, 6x6 each.
  var br = 0, bg = 0, bb = 0, n = 0;
  for (final cx in [0, w - 6]) {
    for (var y = 0; y < 6; y++) {
      for (var x = cx; x < cx + 6; x++) {
        final i = (y * w + x) * 4;
        br += px[i];
        bg += px[i + 1];
        bb += px[i + 2];
        n++;
      }
    }
  }
  final r0 = br / n, g0 = bg / n, b0 = bb / n;
  var top = faceTop;
  var gap = 0;
  for (var y = faceTop - 1; y >= 0; y--) {
    var hair = 0;
    for (var x = minX; x <= maxX; x++) {
      final i = (y * w + x) * 4;
      final d = (px[i] - r0).abs() + (px[i + 1] - g0).abs() + (px[i + 2] - b0).abs();
      if (d > 60) hair++;
    }
    if (hair >= (maxX - minX + 1) * 0.25) {
      top = y;
      gap = 0;
    } else if (++gap >= 3) {
      break;
    }
  }
  return top;
}

/// Is this pixel skin, in THIS photo?
///
/// Hue alone can't tell skin from brown or dark-blond hair: both are warm,
/// red-over-green-over-blue. Measured on a real selfie, hair and skin share a
/// hue (17-29 degrees) but not a brightness: hair 0.09-0.52, the face
/// 0.62-0.92. A fixed brightness floor would throw away darker skin, so the
/// floor is calibrated per photo: read how bright the skin is in the middle of
/// the frame (selfies are centred on the face) and only accept warm pixels
/// reasonably close to that. Hair is far darker than the face it frames, on
/// any skin tone.
///
/// Without this the face box began at the top of the hair, the mask kept the
/// hair as "face" and marked the background for repainting, and the render
/// failed for anyone with brown hair.
class SkinGate {
  const SkinGate._(this.minLuma);

  /// Accepts every warm pixel; used when there's too little to calibrate on.
  static const SkinGate loose = SkinGate._(0);

  /// The darkest a pixel may be and still count as skin in this photo.
  final double minLuma;

  bool isSkin(int r, int g, int b) =>
      isSkinHue(r, g, b) && luma(r, g, b) >= minLuma;

  /// Reads the face's brightness from the centre of [px] (RGBA, [w] x [h]).
  factory SkinGate.calibrate(Uint8List px, int w, int h) {
    final samples = <double>[];
    final xa = (w * 0.36).floor(), xb = (w * 0.64).ceil();
    final ya = (h * 0.34).floor(), yb = (h * 0.68).ceil();
    for (var y = ya; y < yb; y++) {
      for (var x = xa; x < xb; x++) {
        final i = (y * w + x) * 4;
        final r = px[i], g = px[i + 1], b = px[i + 2];
        if (isSkinHue(r, g, b)) samples.add(luma(r, g, b));
      }
    }
    if (samples.length < 12) return loose;
    samples.sort();
    // The upper-middle of the centre's warm pixels is lit skin; a fringe or
    // beard intruding into the centre only adds to the darker half.
    final face = samples[(samples.length * 0.65).floor()];
    // 0.65 of the face's brightness. Measured on a pompadour (light-brown
    // highlights): at 0.55 the hair rows still read 10-16% "skin", enough to
    // pass as face; at 0.65 they drop to 5% or less while face rows stay
    // above 50%.
    return SkinGate._(face * 0.65);
  }
}

double luma(int r, int g, int b) => 0.299 * r + 0.587 * g + 0.114 * b;

/// Warm, skin-like colour, before any brightness check: the RGB rule for even
/// daylight OR a YCbCr range that tolerates darker tones and uneven light.
bool isSkinHue(int r, int g, int b) {
  final maxc = math.max(r, math.max(g, b));
  final minc = math.min(r, math.min(g, b));
  final rgb = r > 95 &&
      g > 40 &&
      b > 20 &&
      (maxc - minc) > 15 &&
      (r - g).abs() > 15 &&
      r > g &&
      r > b;
  if (rgb) return true;
  final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
  final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
  return cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173;
}
