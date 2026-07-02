import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'dart:ui_web' as ui_web;

import 'package:web/web.dart' as web;

import 'camera_interface.dart';

int _seq = 0;

CameraCapture createCamera() => _WebCamera();

/// Live camera on web via `getUserMedia` + a registered platform view.
class _WebCamera implements CameraCapture {
  _WebCamera() : viewType = 'live-camera-${_seq++}';

  @override
  final String viewType;

  web.HTMLVideoElement? _video;
  web.MediaStream? _stream;
  bool _registered = false;

  @override
  Future<bool> start() async {
    try {
      final devices = web.window.navigator.mediaDevices;
      // ignore: unnecessary_null_comparison
      if (devices == null) return false;

      final stream = await devices
          .getUserMedia(web.MediaStreamConstraints(
            video: true.toJS,
            audio: false.toJS,
          ))
          .toDart;

      final video = web.HTMLVideoElement()
        ..autoplay = true
        ..muted = true;
      video.setAttribute('playsinline', 'true');
      video.srcObject = stream;
      video.style.setProperty('width', '100%');
      video.style.setProperty('height', '100%');
      video.style.setProperty('object-fit', 'cover');

      _stream = stream;
      _video = video;

      if (!_registered) {
        ui_web.platformViewRegistry
            .registerViewFactory(viewType, (int _) => video);
        _registered = true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Uint8List? capture() {
    final video = _video;
    if (video == null) return null;
    try {
      final w = video.videoWidth;
      final h = video.videoHeight;
      if (w == 0 || h == 0) return null;
      final canvas = web.HTMLCanvasElement()
        ..width = w
        ..height = h;
      final ctx = canvas.getContext('2d') as web.CanvasRenderingContext2D;
      ctx.drawImage(video, 0, 0);
      final dataUrl = canvas.toDataURL('image/jpeg');
      final comma = dataUrl.indexOf(',');
      if (comma < 0) return null;
      return base64Decode(dataUrl.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    try {
      final tracks = _stream?.getTracks().toDart;
      if (tracks != null) {
        for (final t in tracks) {
          t.stop();
        }
      }
    } catch (_) {}
    try {
      _video?.srcObject = null;
    } catch (_) {}
    _stream = null;
    _video = null;
  }
}
