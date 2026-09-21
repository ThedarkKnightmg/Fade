import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/hairstyle.dart';

/// A selectable hair colour for the try-on.
class HairColor {
  const HairColor(this.name, this.hair, this.shine);
  final String name;
  final Color hair;
  final Color shine; // a lighter tone for the sheen highlight

  static const List<HairColor> options = [
    HairColor('Black', Color(0xFF1B1714), Color(0xFF44392F)),
    HairColor('Brown', Color(0xFF3B2A1C), Color(0xFF6B4A2E)),
    HairColor('Chestnut', Color(0xFF5A3B23), Color(0xFF8A5C34)),
    HairColor('Blonde', Color(0xFFB07D3F), Color(0xFFD9A85E)),
    HairColor('Ash', Color(0xFF6E6A63), Color(0xFF9A958B)),
    // Fashion colours. Kept LAST so the natural five still read as the default
    // run and these are an obvious step outside it. Both are dyed-hair tones
    // rather than pure hues: real violet and emerald dye sit far darker and
    // greyer than the screen colours people expect, and a neon swatch would
    // promise a render the model cannot produce on dark hair.
    HairColor('Purple', Color(0xFF4A2A6B), Color(0xFF8A5CC0)),
    HairColor('Green', Color(0xFF23503A), Color(0xFF4E9B6E)),
  ];
}

enum _Front { down, sweptUp, partSide, partCenter }

class _HairSpec {
  const _HairSpec({
    required this.volume,
    required this.halfW,
    required this.templeY,
    required this.fringeY,
    required this.front,
    this.sideburn = 0.0,
    this.curl = 0.0,
  });

  final double volume; // crown height above the head (0..~0.6)
  final double halfW; // half hair width as fraction of box width
  final double templeY; // where the sides reach, fraction of height
  final double fringeY; // forehead hairline height, fraction of height
  final _Front front;
  final double sideburn; // extra side length below temple

  /// How pronounced the curl is, as a fraction of hair width (0 = smooth).
  /// Non-zero replaces the smooth crown arc with a scalloped one — curls read
  /// by their bumpy OUTLINE, so a bigger smooth blob would just look like more
  /// straight hair.
  final double curl;

  static _HairSpec of(HairSilhouette s) => switch (s) {
        HairSilhouette.buzz => const _HairSpec(
            volume: 0.06,
            halfW: 0.36,
            templeY: 0.42,
            fringeY: 0.44,
            front: _Front.down),
        HairSilhouette.crew => const _HairSpec(
            volume: 0.15,
            halfW: 0.38,
            templeY: 0.42,
            fringeY: 0.43,
            front: _Front.down),
        HairSilhouette.caesar => const _HairSpec(
            volume: 0.13,
            halfW: 0.39,
            templeY: 0.43,
            fringeY: 0.50,
            front: _Front.down),
        HairSilhouette.crop => const _HairSpec(
            volume: 0.21,
            halfW: 0.40,
            templeY: 0.44,
            fringeY: 0.50,
            front: _Front.down),
        HairSilhouette.taper => const _HairSpec(
            volume: 0.27,
            halfW: 0.40,
            templeY: 0.42,
            fringeY: 0.41,
            front: _Front.sweptUp),
        HairSilhouette.sidePart => const _HairSpec(
            volume: 0.27,
            halfW: 0.41,
            templeY: 0.42,
            fringeY: 0.40,
            front: _Front.partSide),
        HairSilhouette.pompadour => const _HairSpec(
            volume: 0.56,
            halfW: 0.40,
            templeY: 0.40,
            fringeY: 0.33,
            front: _Front.sweptUp),
        HairSilhouette.quiff => const _HairSpec(
            volume: 0.43,
            halfW: 0.40,
            templeY: 0.41,
            fringeY: 0.36,
            front: _Front.sweptUp),
        HairSilhouette.slick => const _HairSpec(
            volume: 0.31,
            halfW: 0.42,
            templeY: 0.46,
            fringeY: 0.33,
            front: _Front.sweptUp,
            sideburn: 0.06),
        HairSilhouette.curtains => const _HairSpec(
            volume: 0.30,
            halfW: 0.44,
            templeY: 0.50,
            fringeY: 0.42,
            front: _Front.partCenter,
            sideburn: 0.05),
        // Curls sit wider and taller than the length alone would suggest —
        // the hair springs OUT, not down — so this gets more halfW and volume
        // than a straight cut of the same length, plus the scalloped edge.
        HairSilhouette.curly => const _HairSpec(
            volume: 0.46,
            halfW: 0.46,
            templeY: 0.44,
            fringeY: 0.47,
            front: _Front.down,
            curl: 0.13),
      };
}

/// Paints a stylised hair shape that sits over the top of a head in a photo.
/// It is intentionally a clean, recognisable preview (not a photoreal render),
/// so the user can compare how each cut frames their face.
class HairOverlayPainter extends CustomPainter {
  HairOverlayPainter({
    required this.silhouette,
    required this.color,
  });

  final HairSilhouette silhouette;
  final HairColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final spec = _HairSpec.of(silhouette);

    final halfW = w * spec.halfW;
    final templeY = h * spec.templeY;
    final fringeY = h * spec.fringeY;
    final crownY = h * (0.26 - spec.volume * 0.40); // higher volume → smaller y
    final burstY = templeY + h * spec.sideburn;

    final path = Path();
    // Left side, from sideburn up to temple.
    path.moveTo(cx - halfW * 0.82, burstY);
    path.lineTo(cx - halfW, templeY);
    // Crown: left temple → over the top → right temple.
    if (spec.curl > 0) {
      _scallopedCrown(path, cx, halfW, templeY, crownY, spec.curl * halfW);
    } else {
      path.cubicTo(
        cx - halfW, crownY + (templeY - crownY) * 0.25,
        cx - halfW * 0.5, crownY,
        cx, crownY,
      );
      path.cubicTo(
        cx + halfW * 0.5, crownY,
        cx + halfW, crownY + (templeY - crownY) * 0.25,
        cx + halfW, templeY,
      );
    }
    // Right side down to sideburn.
    path.lineTo(cx + halfW * 0.82, burstY);

    // Hairline back across the forehead (carves out the face).
    switch (spec.front) {
      case _Front.down:
        // Gentle convex line that dips onto the forehead.
        path.cubicTo(
          cx + halfW * 0.55, fringeY,
          cx - halfW * 0.55, fringeY,
          cx - halfW * 0.82, burstY,
        );
        break;
      case _Front.sweptUp:
        // Rises in the centre, exposing the forehead — volume swept up.
        path.cubicTo(
          cx + halfW * 0.5, fringeY + h * 0.02,
          cx + halfW * 0.18, fringeY - h * 0.06,
          cx, fringeY - h * 0.05,
        );
        path.cubicTo(
          cx - halfW * 0.18, fringeY - h * 0.06,
          cx - halfW * 0.5, fringeY + h * 0.02,
          cx - halfW * 0.82, burstY,
        );
        break;
      case _Front.partSide:
        // Diagonal part — heavier on the left.
        path.cubicTo(
          cx + halfW * 0.4, fringeY + h * 0.01,
          cx - halfW * 0.1, fringeY - h * 0.05,
          cx - halfW * 0.45, fringeY + h * 0.05,
        );
        path.cubicTo(
          cx - halfW * 0.6, fringeY + h * 0.08,
          cx - halfW * 0.72, fringeY + h * 0.04,
          cx - halfW * 0.82, burstY,
        );
        break;
      case _Front.partCenter:
        // Two curtains with a dip down the middle.
        path.cubicTo(
          cx + halfW * 0.55, fringeY,
          cx + halfW * 0.18, fringeY + h * 0.02,
          cx, fringeY + h * 0.10,
        );
        path.cubicTo(
          cx - halfW * 0.18, fringeY + h * 0.02,
          cx - halfW * 0.55, fringeY,
          cx - halfW * 0.82, burstY,
        );
        break;
    }
    path.close();

    // 1) Soft contact shadow so the hair sits onto the face, not floats.
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x4D000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    final bounds = path.getBounds();
    final rootDark = Color.lerp(color.hair, Colors.black, 0.22)!;
    final tipDark = Color.lerp(color.hair, Colors.black, 0.34)!;

    // 2) Base mass with a vertical tonal gradient (root → mid → tip).
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [rootDark, color.hair, tipDark],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(bounds),
    );

    // 3) Texture + shading, clipped to the hair shape.
    canvas.save();
    canvas.clipPath(path);

    _drawStrands(canvas, size, spec, cx, crownY, templeY, fringeY, halfW);

    // Specular highlight band near the crown → volume.
    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCenter(
          center: Offset(cx - halfW * 0.18, crownY + (templeY - crownY) * 0.5),
          width: halfW * 1.3,
          height: (templeY - crownY) * 0.85,
        )),
      Paint()
        ..color = color.shine.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // Deepen the lower mass under the crown.
    canvas.drawPath(
      Path()
        ..addOval(Rect.fromCenter(
          center: Offset(cx, templeY),
          width: halfW * 1.7,
          height: (templeY - crownY) * 1.1,
        )),
      Paint()
        ..color = tipDark.withValues(alpha: 0.32)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.restore();

    // 4) A few flyaway wisps over the top edge so it isn't a hard cut-out.
    _drawFlyaways(canvas, size, spec, cx, crownY, halfW);
  }

  /// Hundreds of fine strands that follow the cut's flow, tinted by [color].
  void _drawStrands(Canvas canvas, Size size, _HairSpec spec, double cx,
      double crownY, double templeY, double fringeY, double halfW) {
    final w = size.width;
    final h = size.height;
    final rnd = math.Random(silhouette.index * 131 + 17);
    final dark = Color.lerp(color.hair, Colors.black, 0.32)!;
    final light = color.shine;
    final swept = spec.front == _Front.sweptUp;
    final growth = Offset(cx, crownY + (templeY - crownY) * 0.18);

    for (var i = 0; i < 210; i++) {
      final r = rnd.nextDouble();
      late Offset start, end, ctrl;

      if (swept) {
        // Front strands sweep from the hairline up and back to the crown.
        final fx = cx + (rnd.nextDouble() * 2 - 1) * halfW * 0.92;
        start = Offset(fx, fringeY + (rnd.nextDouble() * 2 - 1) * h * 0.05);
        end = Offset(cx + (fx - cx) * 0.35,
            crownY + rnd.nextDouble() * (templeY - crownY) * 0.35);
        ctrl = Offset((start.dx + end.dx) / 2 + (rnd.nextDouble() * 2 - 1) * w * 0.03,
            math.min(start.dy, end.dy) - h * 0.05);
      } else {
        // Strands radiate down/out from the crown to the perimeter.
        final ang = (0.13 + 0.74 * rnd.nextDouble()) * math.pi;
        final len = (templeY - crownY) * (0.9 + 1.6 * rnd.nextDouble()) + h * 0.05;
        start = growth + Offset.fromDirection(ang, 5 * rnd.nextDouble());
        end = growth + Offset.fromDirection(ang, len);
        final perp = ang + math.pi / 2;
        ctrl = growth +
            Offset.fromDirection(ang, len * 0.55) +
            Offset.fromDirection(perp, (rnd.nextDouble() * 2 - 1) * w * 0.05);
      }

      final col = Color.lerp(r < 0.18 ? light : dark, color.hair, rnd.nextDouble())!;
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy),
        Paint()
          ..color = col.withValues(alpha: 0.10 + 0.30 * rnd.nextDouble())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6 + 1.3 * rnd.nextDouble()
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Soft wisps crossing the top silhouette to feather the edge.
  void _drawFlyaways(
      Canvas canvas, Size size, _HairSpec spec, double cx, double crownY,
      double halfW) {
    final h = size.height;
    final rnd = math.Random(silhouette.index * 977 + 3);
    final light = color.shine;
    for (var i = 0; i < 14; i++) {
      final x = cx + (rnd.nextDouble() * 2 - 1) * halfW * 0.95;
      final y = crownY + (rnd.nextDouble() * 2 - 1) * h * 0.03;
      final up = h * (0.02 + 0.03 * rnd.nextDouble());
      canvas.drawPath(
        Path()
          ..moveTo(x, y + up)
          ..quadraticBezierTo(
              x + (rnd.nextDouble() * 2 - 1) * 10, y - up * 0.4, x, y - up),
        Paint()
          ..color = light.withValues(alpha: 0.18 + 0.18 * rnd.nextDouble())
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.7 + 0.7 * rnd.nextDouble()
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  /// Walks the crown from the left temple, over the top, to the right temple —
  /// but as a run of outward bumps instead of one smooth arc.
  ///
  /// Curly hair is recognised by its EDGE, not its size: the reason a curly
  /// silhouette reads as curly is that the outline is lumpy. Simply enlarging
  /// the smooth crown would read as "more straight hair", which is why this
  /// takes the same elliptical envelope every other style uses and rides a
  /// series of arcs along it, each bulging outward along the surface normal.
  void _scallopedCrown(
    Path path,
    double cx,
    double halfW,
    double templeY,
    double crownY,
    double bump,
  ) {
    const bumps = 9; // enough to read as curl, few enough to stay tidy
    final rx = halfW;
    final ry = templeY - crownY;

    // Point on the crown envelope. a = pi at the left temple, 0 at the right.
    Offset at(double a) =>
        Offset(cx + rx * math.cos(a), templeY - ry * math.sin(a));

    for (var i = 0; i < bumps; i++) {
      final a0 = math.pi * (1 - i / bumps);
      final a1 = math.pi * (1 - (i + 1) / bumps);
      final mid = (a0 + a1) / 2;
      final end = at(a1);
      // Control point pushed out along the outward normal of the ellipse, so
      // each bump swells away from the head rather than sideways.
      final nx = math.cos(mid);
      final ny = -math.sin(mid);
      final ctrl = at(mid).translate(nx * bump, ny * bump);
      path.quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy);
    }
  }

  @override
  bool shouldRepaint(HairOverlayPainter old) =>
      old.silhouette != silhouette || old.color != color;
}

/// A clean, flat catalogue pictogram of a haircut for the style picker.
///
/// A ghosted head-and-shoulders bust with just the cut's hair shape on top —
/// no fake facial features and no busy strands, so at thumbnail size it reads
/// as a professional icon rather than an uncanny mini-face. The cut is told
/// apart by its volume, hairline and sideburns (the [_HairSpec]); the colour
/// is a simple two-tone ([ink] hair over a [bust] silhouette).
class StyleGlyphPainter extends CustomPainter {
  const StyleGlyphPainter({
    required this.silhouette,
    required this.ink,
    required this.bust,
  });

  final HairSilhouette silhouette;
  final Color ink; // the hair shape (accent when selected, neutral otherwise)
  final Color bust; // the soft head + shoulders silhouette

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final spec = _HairSpec.of(silhouette);
    final bustPaint = Paint()
      ..color = bust
      ..isAntiAlias = true;

    // --- Bust: shoulders + neck + head, one soft flat tone. ---
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.02, h * 1.05)
        ..cubicTo(w * 0.08, h * 0.84, w * 0.30, h * 0.78, cx, h * 0.78)
        ..cubicTo(w * 0.70, h * 0.78, w * 0.92, h * 0.84, w * 0.98, h * 1.05)
        ..close(),
      bustPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, h * 0.70), width: w * 0.22, height: h * 0.20),
        Radius.circular(w * 0.10),
      ),
      bustPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.45), width: w * 0.60, height: h * 0.60),
      bustPaint,
    );

    // --- Hair cap on top, sized to hug the head. ---
    final halfW = w * 0.33;
    final templeY = h * spec.templeY;
    final fringeY = h * spec.fringeY;
    final crownY = h * (0.16 - spec.volume * 0.20); // more volume → higher
    final burstY = templeY + h * spec.sideburn;

    final path = Path()
      ..moveTo(cx - halfW * 0.82, burstY)
      ..lineTo(cx - halfW, templeY)
      ..cubicTo(cx - halfW, crownY + (templeY - crownY) * 0.25,
          cx - halfW * 0.5, crownY, cx, crownY)
      ..cubicTo(cx + halfW * 0.5, crownY, cx + halfW,
          crownY + (templeY - crownY) * 0.25, cx + halfW, templeY)
      ..lineTo(cx + halfW * 0.82, burstY);
    switch (spec.front) {
      case _Front.down:
        path.cubicTo(cx + halfW * 0.55, fringeY, cx - halfW * 0.55, fringeY,
            cx - halfW * 0.82, burstY);
        break;
      case _Front.sweptUp:
        path.cubicTo(cx + halfW * 0.5, fringeY + h * 0.02, cx + halfW * 0.18,
            fringeY - h * 0.06, cx, fringeY - h * 0.05);
        path.cubicTo(cx - halfW * 0.18, fringeY - h * 0.06, cx - halfW * 0.5,
            fringeY + h * 0.02, cx - halfW * 0.82, burstY);
        break;
      case _Front.partSide:
        path.cubicTo(cx + halfW * 0.4, fringeY + h * 0.01, cx - halfW * 0.1,
            fringeY - h * 0.05, cx - halfW * 0.45, fringeY + h * 0.05);
        path.cubicTo(cx - halfW * 0.6, fringeY + h * 0.08, cx - halfW * 0.72,
            fringeY + h * 0.04, cx - halfW * 0.82, burstY);
        break;
      case _Front.partCenter:
        path.cubicTo(cx + halfW * 0.55, fringeY, cx + halfW * 0.18,
            fringeY + h * 0.02, cx, fringeY + h * 0.10);
        path.cubicTo(cx - halfW * 0.18, fringeY + h * 0.02, cx - halfW * 0.55,
            fringeY, cx - halfW * 0.82, burstY);
        break;
    }
    path.close();

    // Flat fill with a barely-there top sheen for a clean, finished look.
    final b = path.getBounds();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(ink, Colors.white, 0.12)!, ink],
        ).createShader(b),
    );
    canvas.save();
    canvas.clipPath(path);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx - halfW * 0.22, crownY + (templeY - crownY) * 0.5),
        width: halfW * 1.0,
        height: (templeY - crownY) * 0.7,
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.06),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(StyleGlyphPainter old) =>
      old.silhouette != silhouette || old.ink != ink || old.bust != bust;
}

/// A neutral head-and-shoulders illustration used when there's no real photo
/// (the "demo selfie"), so cuts can still be previewed on a face.
class FacePlaceholderPainter extends CustomPainter {
  const FacePlaceholderPainter({required this.skin, required this.bg});

  final Color skin;
  final Color bg;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    canvas.drawRect(Offset.zero & size, Paint()..color = bg);

    // Shoulders.
    final shoulders = Path()
      ..moveTo(w * 0.12, h)
      ..cubicTo(w * 0.16, h * 0.82, w * 0.34, h * 0.74, cx, h * 0.74)
      ..cubicTo(w * 0.66, h * 0.74, w * 0.84, h * 0.82, w * 0.88, h)
      ..close();
    canvas.drawPath(
        shoulders, Paint()..color = skin.withValues(alpha: 0.55));

    // Neck.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, h * 0.70), width: w * 0.22, height: h * 0.18),
        const Radius.circular(20),
      ),
      Paint()..color = skin.withValues(alpha: 0.8),
    );

    // Face.
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, h * 0.46), width: w * 0.52, height: h * 0.60),
      Paint()..color = skin,
    );

    // Simple features.
    final feature = Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.012
      ..strokeCap = StrokeCap.round;
    // Eyes.
    canvas.drawLine(Offset(cx - w * 0.13, h * 0.45),
        Offset(cx - w * 0.06, h * 0.45), feature);
    canvas.drawLine(Offset(cx + w * 0.06, h * 0.45),
        Offset(cx + w * 0.13, h * 0.45), feature);
    // Nose + mouth.
    canvas.drawLine(
        Offset(cx, h * 0.50), Offset(cx, h * 0.55), feature);
    canvas.drawLine(Offset(cx - w * 0.07, h * 0.60),
        Offset(cx + w * 0.07, h * 0.60), feature);
  }

  @override
  bool shouldRepaint(FacePlaceholderPainter old) =>
      old.skin != skin || old.bg != bg;
}
