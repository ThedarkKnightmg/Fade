import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'photo_constraints.dart';

/// Web photo capture using a native file input — no plugin, no startup
/// registrant. `capture` hints the camera on mobile browsers.
///
/// Hardened: only accepts real images, rejects anything larger than
/// [kMaxPhotoBytes], and never throws or hangs — every path completes the
/// future with bytes or null.
Future<Uint8List?> capturePhoto({bool camera = false}) async {
  final completer = Completer<Uint8List?>();
  void finish(Uint8List? value) {
    if (!completer.isCompleted) completer.complete(value);
  }

  try {
    final input =
        web.document.createElement('input') as web.HTMLInputElement;
    input.type = 'file';
    input.accept = 'image/*';
    if (camera) input.setAttribute('capture', 'user');

    input.onchange = (web.Event _) {
      try {
        final files = input.files;
        if (files == null || files.length == 0) {
          finish(null);
          return;
        }
        final file = files.item(0);
        if (file == null) {
          finish(null);
          return;
        }

        // Reject non-images and oversized files before reading them into
        // memory — a 2 GB "image" should never reach the decoder.
        final type = file.type;
        if (type.isNotEmpty && !type.startsWith('image/')) {
          finish(null);
          return;
        }
        if (file.size <= 0 || file.size > kMaxPhotoBytes) {
          finish(null);
          return;
        }

        final reader = web.FileReader();
        reader.onload = (web.Event _) {
          try {
            final result = reader.result;
            if (result != null && result.isA<JSArrayBuffer>()) {
              final bytes = (result as JSArrayBuffer).toDart.asUint8List();
              finish(isValidPhotoBytes(bytes) ? bytes : null);
            } else {
              finish(null);
            }
          } catch (_) {
            finish(null);
          }
        }.toJS;
        reader.onerror = (web.Event _) {
          finish(null);
        }.toJS;
        reader.readAsArrayBuffer(file);
      } catch (_) {
        finish(null);
      }
    }.toJS;

    // If the dialog is dismissed without a selection, don't hang forever.
    input.oncancel = (web.Event _) {
      finish(null);
    }.toJS;

    input.click();
  } catch (_) {
    finish(null);
  }

  return completer.future;
}
