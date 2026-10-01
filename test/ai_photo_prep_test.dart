import 'dart:io';
import 'dart:typed_data';

import 'package:barber_app/core/ai/hair_mask.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as imglib;

// The free AI route sends a 768px square photo plus a hair mask to the worker.
// Both used to be drawn on the GPU and read back with toImage(), which some
// Android GPUs return as a blank frame, so selfies came back black. These pin
// the CPU path that replaced it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  num lum(imglib.Image im, double fx, double fy) =>
      im.getPixel((im.width * fx).floor(), (im.height * fy).floor()).luminance;

  test('a real photo becomes a 768px square that is not black', () async {
    final photo = File('assets/faces/src/base.png').readAsBytesSync();
    final out = await preparePhotoSquare(photo);
    expect(out, isNotNull);

    final im = imglib.decodeJpg(out!)!;
    expect(im.width, 768);
    expect(im.height, 768);
    var total = 0.0;
    for (var y = 0; y < im.height; y += 16) {
      for (var x = 0; x < im.width; x += 16) {
        total += im.getPixel(x, y).luminance;
      }
    }
    final mean = total / ((im.height / 16).ceil() * (im.width / 16).ceil());
    expect(mean, greaterThan(40), reason: 'a black frame averages near 0');
  });

  test('a sideways camera photo is turned upright before cropping', () async {
    // 400x200, red on the left half and blue on the right, tagged "rotate 90°
    // clockwise". Upright, red is on top and blue at the bottom.
    final raw = imglib.Image(width: 400, height: 200);
    for (var y = 0; y < 200; y++) {
      for (var x = 0; x < 400; x++) {
        x < 200
            ? raw.setPixelRgb(x, y, 230, 20, 20)
            : raw.setPixelRgb(x, y, 20, 20, 230);
      }
    }
    raw.exif.imageIfd.orientation = 6;
    final out = await preparePhotoSquare(imglib.encodeJpg(raw));
    final im = imglib.decodeJpg(out!)!;

    final top = im.getPixel(384, 40);
    final bottom = im.getPixel(384, 740);
    expect(top.r, greaterThan(top.b), reason: 'top should be red');
    expect(bottom.b, greaterThan(bottom.r), reason: 'bottom should be blue');
  });

  test('unreadable bytes give null, never the original photo', () async {
    final out = await preparePhotoSquare(Uint8List.fromList([1, 2, 3, 4]));
    expect(out, isNull);
  });

  test('the CPU mask repaints the hair and keeps the face', () {
    final photo = imglib.encodePng(imglib.Image(width: 768, height: 768));
    final mask = imglib.decodePng(buildHairMaskOnCpu(photo)!)!;

    expect(mask.width, 768);
    expect(lum(mask, 0.5, 0.2), greaterThan(200), reason: 'hair is white');
    expect(lum(mask, 0.5, 0.64), lessThan(20), reason: 'face is black');
    expect(lum(mask, 0.5, 0.95), lessThan(20), reason: 'chin/neck is kept');
  });

  test('the full mask is never blank', () async {
    final photo = File('assets/faces/base.jpg').readAsBytesSync();
    final square = await preparePhotoSquare(photo);
    final mask = imglib.decodePng((await buildHairMask(square!))!)!;

    var white = 0;
    for (var y = 0; y < mask.height; y += 8) {
      for (var x = 0; x < mask.width; x += 8) {
        if (mask.getPixel(x, y).luminance > 128) white++;
      }
    }
    expect(white, greaterThan(100), reason: 'something must be repainted');
  });
}
