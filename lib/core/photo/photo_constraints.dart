import 'dart:typed_data';

/// Largest selfie we will read into memory. Anything bigger is rejected
/// before decoding so a malicious or accidental huge file can't exhaust
/// memory or wedge the UI. 12 MB comfortably covers real phone photos.
const int kMaxPhotoBytes = 12 * 1024 * 1024;

/// Smallest plausible image — guards against empty/truncated selections.
const int kMinPhotoBytes = 64;

/// The magic-byte signatures of the image formats browsers actually hand us.
bool isValidPhotoBytes(Uint8List bytes) {
  if (bytes.length < kMinPhotoBytes || bytes.length > kMaxPhotoBytes) {
    return false;
  }
  // JPEG: FF D8 FF
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return true;
  }
  // PNG: 89 50 4E 47 0D 0A 1A 0A
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return true;
  }
  // GIF: "GIF8"
  if (bytes.length >= 4 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return true;
  }
  // WEBP: "RIFF"????"WEBP"
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return true;
  }
  // BMP: "BM"
  if (bytes.length >= 2 && bytes[0] == 0x42 && bytes[1] == 0x4D) {
    return true;
  }
  return false;
}
