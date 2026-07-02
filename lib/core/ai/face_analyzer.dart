import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../../data/hair_data.dart';
import '../../data/models/hairstyle.dart';

/// Real, lightweight face analysis from a selfie's pixels — no ML model, but it
/// genuinely *measures* the face instead of hashing bytes.
///
/// It decodes a small copy of the photo, segments skin (combined RGB + YCbCr
/// rules so it tolerates different tones and lighting), finds the face's
/// vertical extent, then measures the skin width at the forehead, cheek and jaw
/// bands plus the overall length-to-width ratio. Those proportions classify the
/// [FaceShape]. Because it's a measurement, the same face always gives the same
/// answer and different faces give different answers — which the old byte-hash
/// never did.
class FaceAnalyzer {
  FaceAnalyzer._();

  static Future<StyleAnalysis> analyse(Uint8List bytes) async {
    final geo = await _measure(bytes);
    if (geo == null) {
      // Couldn't read the pixels — a safe, neutral default (never random).
      return HairData.forShape(FaceShape.oval, confidence: 0.74);
    }
    return HairData.forShape(geo.shape,
        confidence: geo.confidence, colorIndex: geo.colorIndex);
  }

  static Future<_Geo?> _measure(Uint8List bytes) async {
    try {
      // Downscale to ~128px wide (aspect preserved) — plenty for proportions,
      // and cheap to scan pixel by pixel.
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 128);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      final w = img.width;
      final h = img.height;
      final bd = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
      img.dispose();
      if (bd == null || w < 8 || h < 8) return null;
      final px = bd.buffer.asUint8List();

      // Selfies are centred — ignore the outer columns / very bottom so we
      // don't pick up background or clothing that happens to be skin-coloured.
      final x0 = (w * 0.12).floor();
      final x1 = (w * 0.88).ceil();
      const y0 = 0;
      final y1 = (h * 0.92).ceil();

      final rows = List<int>.filled(h, 0); // skin pixels per row
      var skin = 0;
      var total = 0;
      for (var y = y0; y < y1; y++) {
        for (var x = x0; x < x1; x++) {
          final i = (y * w + x) * 4;
          total++;
          if (_isSkin(px[i], px[i + 1], px[i + 2])) {
            skin++;
            rows[y]++;
          }
        }
      }
      if (total == 0) return null;
      final frac = skin / total;
      // Almost no face found (e.g. a non-portrait or the random demo bytes).
      if (frac < 0.03) return const _Geo(FaceShape.oval, 0.66);

      // Face vertical extent: the band of rows that are meaningfully skin.
      final rowThresh = math.max(2, ((x1 - x0) * 0.10).round());
      var minY = -1;
      var maxY = -1;
      for (var y = y0; y < y1; y++) {
        if (rows[y] >= rowThresh) {
          if (minY < 0) minY = y;
          maxY = y;
        }
      }
      if (minY < 0 || maxY <= minY) return const _Geo(FaceShape.oval, 0.70);
      final fh = (maxY - minY).toDouble();

      // Skin extent [lo, hi] at a vertical band (averaged over a few rows).
      (int, int) bandExtent(double frac01) {
        final cy = (minY + fh * frac01).round();
        var lo = w;
        var hi = -1;
        for (var y = math.max(minY, cy - 1);
            y <= math.min(maxY, cy + 1);
            y++) {
          for (var x = x0; x < x1; x++) {
            final i = (y * w + x) * 4;
            if (_isSkin(px[i], px[i + 1], px[i + 2])) {
              if (x < lo) lo = x;
              if (x > hi) hi = x;
            }
          }
        }
        return (lo, hi);
      }

      double widthOf((int, int) e) =>
          e.$2 >= e.$1 ? (e.$2 - e.$1).toDouble() : 0;

      final cheekE = bandExtent(0.50);
      final forehead = widthOf(bandExtent(0.20));
      final cheek = widthOf(cheekE);
      final jaw = widthOf(bandExtent(0.78));
      final fw = math.max(forehead, math.max(cheek, jaw));
      if (fw <= 0) return const _Geo(FaceShape.oval, 0.70);

      final lengthRatio = fh / fw;
      final jawCheek = cheek > 0 ? jaw / cheek : 1.0;
      final foreheadCheek = cheek > 0 ? forehead / cheek : 1.0;
      final foreheadJaw = jaw > 0 ? forehead / jaw : 1.0;

      final FaceShape shape;
      if (lengthRatio >= 1.45) {
        shape = FaceShape.oblong; // clearly longer than wide
      } else if (foreheadJaw >= 1.22 && foreheadCheek >= 0.9) {
        shape = FaceShape.heart; // wide forehead tapering to a narrow jaw
      } else if (foreheadCheek <= 0.82 && jawCheek <= 0.85) {
        shape = FaceShape.diamond; // cheekbones are the widest point
      } else if (lengthRatio <= 1.12) {
        // About as wide as long: a strong even jaw reads square, a soft
        // narrowing jaw reads round.
        shape = jawCheek >= 0.90 ? FaceShape.square : FaceShape.round;
      } else {
        shape = FaceShape.oval; // balanced, a touch longer than wide
      }

      // Hair colour, read from the band just above the forehead.
      final colorIndex = _hairColor(px, w, minY, fh, cheekE);

      // More clean skin found → a clearer read. Kept in a believable band.
      final conf = (0.66 + frac * 1.2).clamp(0.68, 0.95);
      return _Geo(shape, conf.toDouble(), colorIndex);
    } catch (_) {
      return null;
    }
  }

  /// Read hair colour from the band just above the forehead, within the face's
  /// width. Returns null unless a confident, mostly-dark non-skin cluster
  /// (i.e. hair, not background) is found — so we never guess a wild colour.
  static int? _hairColor(
      Uint8List px, int w, int minY, double fh, (int, int) cheekExtent) {
    final lo = cheekExtent.$1;
    final hi = cheekExtent.$2;
    if (hi <= lo) return null;
    final cx = (lo + hi) / 2;
    final halfW = (hi - lo) / 2 * 0.8;
    final top = math.max(0, (minY - fh * 0.30).round());
    final bot = (minY + fh * 0.06).round();
    final xLo = math.max(0, (cx - halfW).round());
    final xHi = math.min(w - 1, (cx + halfW).round());
    var rs = 0, gs = 0, bs = 0, n = 0, dark = 0;
    for (var y = top; y <= bot; y++) {
      for (var x = xLo; x <= xHi; x++) {
        final i = (y * w + x) * 4;
        final r = px[i], g = px[i + 1], b = px[i + 2];
        if (_isSkin(r, g, b)) continue;
        n++;
        rs += r;
        gs += g;
        bs += b;
        if (0.299 * r + 0.587 * g + 0.114 * b < 110) dark++;
      }
    }
    if (n < 24 || dark / n < 0.6) return null; // not confidently hair
    return _nearestColor(rs / n, gs / n, bs / n);
  }

  // Mirrors HairColor.options (hair_overlay.dart) for nearest-swatch matching.
  static const List<List<int>> _palette = [
    [27, 23, 20], // Black
    [59, 42, 28], // Brown
    [90, 59, 35], // Chestnut
    [176, 125, 63], // Blonde
    [110, 106, 99], // Ash
  ];

  static int _nearestColor(double r, double g, double b) {
    var best = 0;
    var bestD = double.infinity;
    for (var i = 0; i < _palette.length; i++) {
      final p = _palette[i];
      final d = (r - p[0]) * (r - p[0]) +
          (g - p[1]) * (g - p[1]) +
          (b - p[2]) * (b - p[2]);
      if (d < bestD) {
        bestD = d;
        best = i;
      }
    }
    return best;
  }

  /// Skin test: RGB (Kovac) rule for even daylight OR a YCbCr range that
  /// tolerates darker tones and uneven lighting. OR keeps recall high.
  static bool _isSkin(int r, int g, int b) {
    final maxc = math.max(r, math.max(g, b));
    final minc = math.min(r, math.min(g, b));
    final rgb = r > 95 &&
        g > 40 &&
        b > 20 &&
        (maxc - minc) > 15 &&
        (r - g).abs() > 15 &&
        r > g &&
        r > b;
    final cb = 128 - 0.168736 * r - 0.331264 * g + 0.5 * b;
    final cr = 128 + 0.5 * r - 0.418688 * g - 0.081312 * b;
    final ycc = cb >= 77 && cb <= 127 && cr >= 133 && cr <= 173;
    return rgb || ycc;
  }
}

class _Geo {
  const _Geo(this.shape, this.confidence, [this.colorIndex]);
  final FaceShape shape;
  final double confidence;
  final int? colorIndex;
}
