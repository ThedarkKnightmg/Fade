import 'dart:typed_data';

/// A live-camera controller. The web implementation uses `getUserMedia` +
/// a platform view; the stub (non-web) reports unavailable so callers fall
/// back to the file picker.
abstract class CameraCapture {
  /// Open the camera. Returns true if a live stream started.
  Future<bool> start();

  /// The platform-view id to embed in an `HtmlElementView`.
  String get viewType;

  /// Grab the current frame as JPEG bytes (null if not ready).
  Uint8List? capture();

  /// Stop the stream and release the camera.
  void dispose();
}
