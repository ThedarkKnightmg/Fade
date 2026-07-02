import 'dart:typed_data';

import 'camera_interface.dart';

/// Non-web: no plugin-free live camera, so report unavailable and let the
/// caller fall back to the file picker.
CameraCapture createCamera() => _StubCamera();

class _StubCamera implements CameraCapture {
  @override
  Future<bool> start() async => false;

  @override
  String get viewType => '';

  @override
  Uint8List? capture() => null;

  @override
  void dispose() {}
}
