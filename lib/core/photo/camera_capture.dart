import 'camera_interface.dart';
import 'camera_stub.dart'
    if (dart.library.js_interop) 'camera_web.dart' as impl;

export 'camera_interface.dart';

/// Create a [CameraCapture] for the current platform (live camera on web,
/// an always-unavailable stub elsewhere).
CameraCapture createCamera() => impl.createCamera();
