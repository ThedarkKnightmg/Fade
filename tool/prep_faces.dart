// Prepares the demo try-on faces for the Style Studio.
//
// Run: dart run tool/prep_faces.dart
//
// The source renders are wide (1408x768) and ~1.5MB of PNG each. The try-on
// hero is a portrait 3:4 box, so BoxFit.cover was going to discard most of that
// width anyway — and six full-size PNGs would have put ~9MB into the APK for
// pixels nobody sees.
//
// So: centre-crop each render to 3:4 around the head, downscale to 900x1200,
// and write JPEG. Photographs compress far better as JPEG than PNG, and there
// is no transparency to preserve.
//
// The crop is deterministic and identical for every image, which is the point:
// all the renders share framing, so the same crop keeps the face pinned in
// exactly the same place. If it drifted per-image, flipping between styles
// would look like different people rather than one person changing haircut.
import 'dart:io';

import 'package:image/image.dart' as img;

const _srcDir = 'assets/faces/src';
const _outDir = 'assets/faces';
const _outW = 900;
const _outH = 1200; // 3:4 portrait, matching the try-on hero

void main() {
  final src = Directory(_srcDir);
  if (!src.existsSync()) {
    stderr.writeln('No $_srcDir — put the original PNGs there first.');
    exitCode = 1;
    return;
  }

  for (final file in src.listSync().whereType<File>()) {
    final name = file.uri.pathSegments.last;
    if (!name.toLowerCase().endsWith('.png') &&
        !name.toLowerCase().endsWith('.jpg')) {
      continue;
    }
    final decoded = img.decodeImage(file.readAsBytesSync());
    if (decoded == null) {
      stderr.writeln('skip (undecodable): $name');
      continue;
    }

    // Widest 3:4 portrait window that fits, centred horizontally. Vertically we
    // start at the very top: these are head-and-shoulders renders, so the head
    // sits high in the frame and centring vertically would crop the hair —
    // which is the only thing the picture exists to show.
    final cropH = decoded.height;
    final cropW = (cropH * 3 / 4).round();
    final x = ((decoded.width - cropW) / 2).round().clamp(0, decoded.width);
    final cropped = img.copyCrop(
      decoded,
      x: x,
      y: 0,
      width: cropW.clamp(1, decoded.width - x),
      height: cropH,
    );

    final resized = img.copyResize(
      cropped,
      width: _outW,
      height: _outH,
      interpolation: img.Interpolation.cubic,
    );

    final stem = name.substring(0, name.lastIndexOf('.'));
    final out = File('$_outDir/$stem.jpg');
    out.writeAsBytesSync(img.encodeJpg(resized, quality: 86));
    final kb = (out.lengthSync() / 1024).round();
    stdout.writeln('$name -> ${out.path}  ${_outW}x$_outH  ${kb}KB');
  }
}
