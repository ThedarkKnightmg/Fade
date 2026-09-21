import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import '../../data/models/hairstyle.dart';
import 'face_box.dart';

/// Normalises a photo to a clean square PNG of [size]×[size] for the AI.
///
/// Square + a fixed size means the model never squishes a portrait into a
/// square (the main cause of blur/distortion) and the returned image is crisp.
/// The crop is biased toward the top so the head/hair is kept.
Future<Uint8List?> preparePhotoSquare(Uint8List photo, {int size = 768}) async {
  try {
    final codec = await ui.instantiateImageCodec(photo);
    final frame = await codec.getNextFrame();
    final src = frame.image;
    final w = src.width.toDouble();
    final h = src.height.toDouble();
    if (w == 0 || h == 0) {
      src.dispose();
      return null;
    }
    final side = w < h ? w : h;
    final sx = (w - side) / 2; // centre horizontally
    final sy = (h - side) * 0.2; // bias up so the head/hair stays in frame

    final recorder = ui.PictureRecorder();
    final s = size.toDouble();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, s, s));
    canvas.drawImageRect(
      src,
      ui.Rect.fromLTWH(sx, sy, side, side),
      ui.Rect.fromLTWH(0, 0, s, s),
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );
    src.dispose();

    final picture = recorder.endRecording();
    final out = await picture.toImage(size, size);
    picture.dispose();
    final data = await out.toByteData(format: ui.ImageByteFormat.png);
    out.dispose();
    return data?.buffer.asUint8List();
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
      final (double crown, double hairline) = switch (silhouette) {
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
