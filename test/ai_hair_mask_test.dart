import 'dart:io';
import 'dart:typed_data';

import 'package:barber_app/core/ai/face_analyzer.dart';
import 'package:barber_app/core/ai/hair_mask.dart';
import 'package:barber_app/data/hair_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

// The hair mask tells the AI what to repaint: white = hair, black = keep.
//
// It used to find the face by counting warm "skin" pixels, and brown hair is
// warm too. On a brown-haired selfie the face box started at the top of the
// hair, so the mask KEPT the hair and marked the background for repainting;
// the render then failed or changed nothing. These checks use a real photo
// (the bundled demo face, brown hair on a grey wall).
void main() {
  late Uint8List square;

  setUpAll(() async {
    final photo = File('assets/faces/base.jpg').readAsBytesSync();
    square = (await preparePhotoSquare(photo))!;
  });

  // Luminance of the mask at a point given in 0..1 of the 768px square.
  int at(img.Image m, double fx, double fy) =>
      m.getPixel((fx * m.width).round(), (fy * m.height).round()).luminance
          .toInt();

  testWidgets('the mask repaints the hair and keeps face and background',
      (t) async {
    final png = await t.runAsync(() => buildHairMask(square,
        silhouette: HairData.byId('h_buzz').silhouette));
    final m = img.decodeImage(png!)!;

    // Hair on top of the head: repaint.
    expect(at(m, 0.50, 0.10), greaterThan(200), reason: 'top of the hair');
    expect(at(m, 0.40, 0.18), greaterThan(200), reason: 'hair, left of part');
    // The eyes: keep.
    expect(at(m, 0.39, 0.52), lessThan(40), reason: 'left eye');
    expect(at(m, 0.61, 0.52), lessThan(40), reason: 'right eye');
    // The wall beside the head at eye level: keep (it used to be repainted).
    expect(at(m, 0.04, 0.50), lessThan(40), reason: 'background, left');
    expect(at(m, 0.96, 0.50), lessThan(40), reason: 'background, right');
  });

  testWidgets('the analyser reads brown hair as hair, not as face', (t) async {
    final a = await t.runAsync(() => FaceAnalyzer.analyse(square));
    // Brown hair used to count as skin, so no hair colour was ever read and
    // the face measured long (the hair stretched it).
    expect(a!.suggestedColorIndex, isNotNull);
  });
}
