import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:image/image.dart' as imglib;

import '../../data/models/hairstyle.dart';
import 'face_box.dart';

/// Normalises a photo to a clean [size]x[size] JPEG for the AI.
///
/// Square + a fixed size means the model never squishes a portrait into a
/// square (the main cause of blur/distortion) and the returned image is crisp.
/// The crop is biased toward the top so the head/hair is kept.
///
/// Done on the CPU with the `image` package, in a background isolate. It used
/// to be drawn with a ui.PictureRecorder and read back with toImage(), and
/// some Android GPUs read that back as a blank, black frame: the worker then
/// edited a black photo and the user got a black result. Returns null if the
/// photo can't be decoded; callers must not fall back to the original bytes,
/// because a full-size photo is exactly what makes SD-1.5 return black.
Future<Uint8List?> preparePhotoSquare(Uint8List photo, {int size = 768}) =>
    Isolate.run(() => _squareOnCpu(photo, size));

Uint8List? _squareOnCpu(Uint8List photo, int size) {
  try {
    final decoded = imglib.decodeImage(photo);
    if (decoded == null) return null;
    // Camera photos store "rotate me" in EXIF; bake it in so the head is up.
    final src = imglib.bakeOrientation(decoded);
    final side = math.min(src.width, src.height);
    if (side == 0) return null;
    final sx = (src.width - side) ~/ 2; // centre horizontally
    final sy = ((src.height - side) * 0.2).round(); // bias up: keep the hair
    final square =
        imglib.copyCrop(src, x: sx, y: sy, width: side, height: side);
    final out = imglib.copyResize(square,
        width: size, height: size, interpolation: imglib.Interpolation.cubic);
    return imglib.encodeJpg(out, quality: 92);
  } catch (_) {
    return null;
  }
}

/// Builds an inpainting mask the same size as [photo]: WHITE over the hair
/// (a crown + temples dome) with the FACE carved back out in BLACK, and black
/// everywhere else (shoulders / background).
///
/// Stable-Diffusion inpainting only repaints the white area and copies the
/// black area through untouched — so the face and background stay exactly as
/// shot and only the hair is regenerated. Shaping the white as a dome and
/// punching out a soft face oval (instead of a flat top band) keeps the
/// eyes/nose/mouth safe and gives the new hairline a natural curve.
Future<Uint8List?> buildHairMask(Uint8List photo,
    {HairSilhouette? silhouette}) async {
  final gpu = await _buildHairMaskOnGpu(photo, silhouette: silhouette);
  if (gpu != null && !await Isolate.run(() => _isBlank(gpu))) return gpu;
  // Some Android GPUs read a drawn picture back as blank. An all-black mask
  // tells the model to keep everything, so the hair would never change. Fall
  // back to the fixed-layout mask, drawn on the CPU.
  return Isolate.run(() => buildHairMaskOnCpu(photo, silhouette: silhouette));
}

/// The face-anchored mask, drawn on the GPU. Preferred, because it follows the
/// detected head; [buildHairMask] checks its output before trusting it.
Future<Uint8List?> _buildHairMaskOnGpu(Uint8List photo,
    {HairSilhouette? silhouette}) async {
  try {
    final codec = await ui.instantiateImageCodec(photo);
    final frame = await codec.getNextFrame();
    final w = frame.image.width;
    final h = frame.image.height;
    frame.image.dispose();
    if (w == 0 || h == 0) return null;

    final wd = w.toDouble();
    final hd = h.toDouble();

    // WHERE IS THE HEAD? Anchor everything to the detected face instead of
    // assuming it sits at a fixed spot in the frame. Without this, a selfie
    // taken closer/further/off-centre had its repaint zone land somewhere else
    // entirely — the model then "drew hair" over a cheek or the background.
    final face = await detectFaceBox(photo);

    // How far ABOVE the hairline this style needs to build, and how far DOWN
    // past it the sides/temples run — both as multiples of the face height, so
    // they scale with however big the head is in frame.
    final (double up, double down) = switch (silhouette) {
      HairSilhouette.buzz => (0.30, 0.10),
      HairSilhouette.crew => (0.34, 0.10),
      HairSilhouette.caesar => (0.34, 0.12),
      HairSilhouette.crop => (0.38, 0.12),
      HairSilhouette.taper => (0.42, 0.16),
      HairSilhouette.sidePart => (0.44, 0.16),
      HairSilhouette.slick => (0.46, 0.16),
      HairSilhouette.pompadour => (0.62, 0.14),
      HairSilhouette.quiff => (0.58, 0.14),
      HairSilhouette.curtains => (0.46, 0.22),
      // Curls occupy more space than their length implies — the mask has to
      // reach higher and wider or the render clips the top of the hair off.
      HairSilhouette.curly => (0.58, 0.20),
      null => (0.42, 0.14),
    };

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, wd, hd));

    // Keep everything by default (black = preserve).
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, wd, hd),
      ui.Paint()..color = const ui.Color(0xFF000000),
    );

    if (face != null) {
      // ── Face-anchored mask ────────────────────────────────────────────
      //
      // THE MASK MUST COVER THE HAIR BEING REMOVED, not just the space the new
      // hair will occupy. The previous version was an oval from above the head
      // down to `hairlineY + faceH * down`, only 0.78 face-widths wide. An oval
      // is widest at its vertical MIDPOINT — which sat above the hairline — so
      // it tapered to a point exactly at the temples and left the ears and nape
      // black (= copied through untouched). A live test asking for a platinum
      // mohawk came back as a blonde top over brown sides, which is what every
      // user with more than a buzz was getting: new hair pasted onto old hair.
      //
      // The shape is now a dome whose widest point IS the hairline, welded to
      // straight sides running past the ears to the jaw.

      // detectFaceBox counts SKIN, so a bare neck and shoulders inflate the
      // box. Clamp to proportions a real face can actually have before
      // deriving anything from it.
      final faceW = (face.width * wd).clamp(wd * 0.12, wd * 0.58);
      final faceH = (face.height * hd).clamp(faceW * 0.95, faceW * 1.45);

      final cx = face.centerX * wd;
      final hairlineY = face.top * hd; // top of the skin blob
      final eyeY = hairlineY + faceH * 0.30; // eyes ≈ 30% down the face
      final chinY = hairlineY + faceH;

      // Hair is WIDER than the skin box: temples, ears and sideburns all live
      // outside it.
      final halfW = faceW * 1.02;
      final topY = (hairlineY - faceH * up).clamp(-faceH * 0.30, hairlineY);

      // Sides run down past the ears so existing side hair is inside the
      // repaint zone and can actually be cut off. The 0.85 floor is the point:
      // `down` tunes how far past that a style reaches, but no style may mask
      // less than the head itself.
      final sideBottomY = hairlineY + faceH * (0.85 + down);

      // Dome centred ON the hairline, so its widest point is over the temples
      // rather than over the background.
      final dome = ui.Path()
        ..addOval(ui.Rect.fromLTRB(
            cx - halfW, topY, cx + halfW, hairlineY + (hairlineY - topY)));
      final sides = ui.Path()
        ..addRRect(ui.RRect.fromLTRBAndCorners(
          cx - halfW,
          hairlineY,
          cx + halfW,
          sideBottomY,
          bottomLeft: ui.Radius.circular(faceW * 0.38),
          bottomRight: ui.Radius.circular(faceW * 0.38),
        ));

      canvas.drawPath(
        ui.Path.combine(ui.PathOperation.union, dome, sides),
        ui.Paint()
          ..color = const ui.Color(0xFFFFFFFF)
          ..maskFilter =
              ui.MaskFilter.blur(ui.BlurStyle.normal, faceW * 0.045),
      );

      // Carve the FACE back out. The old top edge (hairlineY + faceH * 0.14)
      // lands BELOW the eyebrows whenever the detected skin-top is a fringe or
      // a low hairline — which is the "the AI changed my face" failure. Clamp
      // it so the eyes are ALWAYS preserved.
      final carveTop = math.min(hairlineY + faceH * 0.16, eyeY - faceH * 0.06);
      canvas.drawOval(
        ui.Rect.fromLTRB(
          cx - faceW * 0.50,
          carveTop,
          cx + faceW * 0.50,
          chinY + faceH * 0.06,
        ),
        ui.Paint()
          ..color = const ui.Color(0xFF000000)
          ..maskFilter =
              ui.MaskFilter.blur(ui.BlurStyle.normal, faceW * 0.055),
      );
    } else {
      // ── Fallback: no confident face found, use the old fixed layout ────
      final (double crown, double hairline) = _fixedHairBand(silhouette);
      final crownSoft = (crown + 0.04).clamp(0.0, 1.0);
      final solidEnd =
          (hairline - 0.12).clamp(crownSoft + 0.01, hairline - 0.01);
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, wd, hd),
        ui.Paint()
          ..shader = ui.Gradient.linear(
            const ui.Offset(0, 0),
            ui.Offset(0, hd),
            const [
              ui.Color(0x00FFFFFF),
              ui.Color(0xFFFFFFFF),
              ui.Color(0xFFFFFFFF),
              ui.Color(0x00FFFFFF),
            ],
            [crown, crownSoft, solidEnd, hairline],
          ),
      );
      canvas.drawOval(
        ui.Rect.fromCenter(
          center: ui.Offset(wd * 0.5, hd * 0.64),
          width: wd * 0.62,
          height: hd * 0.66,
        ),
        ui.Paint()
          ..color = const ui.Color(0xFF000000)
          ..maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, wd * 0.045),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    picture.dispose();
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    return data?.buffer.asUint8List();
  } catch (_) {
    return null;
  }
}

/// Where the hair band starts (crown) and ends (hairline), as fractions of the
/// photo height, for the fixed layout used when no face is located.
(double, double) _fixedHairBand(HairSilhouette? silhouette) =>
    switch (silhouette) {
      HairSilhouette.buzz => (0.15, 0.42),
      HairSilhouette.crew => (0.12, 0.42),
      HairSilhouette.caesar => (0.12, 0.44),
      HairSilhouette.crop => (0.10, 0.44),
      HairSilhouette.taper => (0.06, 0.45),
      HairSilhouette.sidePart => (0.05, 0.45),
      HairSilhouette.slick => (0.04, 0.46),
      HairSilhouette.pompadour => (0.00, 0.48),
      HairSilhouette.quiff => (0.00, 0.47),
      HairSilhouette.curtains => (0.05, 0.50),
      HairSilhouette.curly => (0.01, 0.47),
      null => (0.05, 0.46),
    };

/// True when a mask has no white anywhere, i.e. nothing would be repainted.
bool _isBlank(Uint8List png) {
  final mask = imglib.decodeImage(png);
  if (mask == null) return true;
  for (var y = 0; y < mask.height; y += 8) {
    for (var x = 0; x < mask.width; x += 8) {
      if (mask.getPixel(x, y).luminance > 32) return false;
    }
  }
  return true;
}

/// The fixed-layout hair mask drawn on the CPU: the same band and face oval as
/// the GPU fallback, for devices whose GPU reads drawn pictures back blank.
@visibleForTesting
Uint8List? buildHairMaskOnCpu(Uint8List photo, {HairSilhouette? silhouette}) {
  try {
    final decoded = imglib.decodeImage(photo);
    if (decoded == null) return null;
    final w = decoded.width;
    final h = decoded.height;
    final (crown, hairline) = _fixedHairBand(silhouette);
    final crownSoft = (crown + 0.04).clamp(0.0, 1.0);
    final solidEnd = (hairline - 0.12).clamp(crownSoft + 0.01, hairline - 0.01);
    final cx = w * 0.5, cy = h * 0.64, rx = w * 0.31, ry = h * 0.33;

    final mask = imglib.Image(width: w, height: h);
    for (var y = 0; y < h; y++) {
      final f = y / h;
      // White ramps in over the crown, holds, then fades out at the hairline.
      final double band;
      if (f < crown || f > hairline) {
        band = 0;
      } else if (f < crownSoft) {
        band = (f - crown) / (crownSoft - crown);
      } else if (f <= solidEnd) {
        band = 1;
      } else {
        band = (hairline - f) / (hairline - solidEnd);
      }
      final dy = (y - cy) / ry;
      for (var x = 0; x < w; x++) {
        final dx = (x - cx) / rx;
        final v = dx * dx + dy * dy <= 1 ? 0 : (band * 255).round();
        mask.setPixelRgb(x, y, v, v, v);
      }
    }
    // Soften the face edge so the new hairline blends instead of cutting.
    return imglib.encodePng(
        imglib.gaussianBlur(mask, radius: math.max(2, (w * 0.02).round())));
  } catch (_) {
    return null;
  }
}
