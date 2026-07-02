import 'dart:typed_data';

import 'photo_source_stub.dart'
    if (dart.library.js_interop) 'photo_source_web.dart' as impl;

/// Open the device's photo picker / camera and return the chosen image
/// bytes, or null if the user cancelled or the platform can't provide one.
///
/// Implemented without any plugin: on web it uses a native `<input type=file>`
/// (with `capture` for the camera). On other platforms it returns null and
/// the caller falls back to a demo image.
Future<Uint8List?> capturePhoto({bool camera = false}) =>
    impl.capturePhoto(camera: camera);
