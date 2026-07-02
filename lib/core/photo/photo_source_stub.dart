import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

final ImagePicker _picker = ImagePicker();

/// Native photo source via image_picker: opens the device camera (or the
/// photo gallery) and returns the chosen image bytes, or null if cancelled.
Future<Uint8List?> capturePhoto({bool camera = false}) async {
  try {
    final XFile? file = await _picker.pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 90,
    );
    if (file == null) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}
