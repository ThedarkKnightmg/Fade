import 'dart:typed_data';

import 'package:barber_app/core/photo/photo_constraints.dart';
import 'package:barber_app/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts well-formed addresses', () {
      for (final ok in [
        'a@b.co',
        'alex.johnson@example.com',
        'a+tag@sub.domain.io',
      ]) {
        expect(Validators.email(ok), isNull, reason: ok);
      }
    });

    test('rejects junk, empties, and overlong input', () {
      for (final bad in [
        '',
        '   ',
        'not-an-email',
        'a@b',
        'a@@b.com',
        'a b@c.com',
        '<script>@x.com',
        'a\n@b.com', // internal newline (header-injection shape)
        'a@b\r.com',
      ]) {
        expect(Validators.email(bad), isNotNull, reason: '"$bad"');
      }
      expect(Validators.email('${'a' * 300}@b.com'), isNotNull);
      expect(Validators.email(null), isNotNull);
    });
  });

  group('Validators.password', () {
    test('enforces a minimum and a sane maximum', () {
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('12345678'), isNull);
      expect(Validators.password(''), isNotNull);
      expect(Validators.password(null), isNotNull);
      expect(Validators.password('a' * 200), isNotNull);
    });
  });

  group('Validators.phone', () {
    test('accepts real numbers, rejects letters/symbols', () {
      expect(Validators.phone('+1 (555) 234-1908'), isNull);
      expect(Validators.phone('5551234'), isNull);
      expect(Validators.phone('call me'), isNotNull);
      expect(Validators.phone('123'), isNotNull); // too few digits
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone(r"'; DROP TABLE--"), isNotNull);
    });
  });

  group('Validators.fullName', () {
    test('bounds length', () {
      expect(Validators.fullName('Al'), isNull);
      expect(Validators.fullName('A'), isNotNull);
      expect(Validators.fullName(''), isNotNull);
      expect(Validators.fullName('x' * 100), isNotNull);
    });
  });

  group('isValidPhotoBytes — magic-byte gate', () {
    Uint8List padded(List<int> head, {int len = 256}) {
      final b = Uint8List(len);
      for (var i = 0; i < head.length; i++) {
        b[i] = head[i];
      }
      return b;
    }

    test('accepts real image signatures', () {
      expect(isValidPhotoBytes(padded([0xFF, 0xD8, 0xFF])), isTrue); // JPEG
      expect(
        isValidPhotoBytes(
            padded([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])),
        isTrue, // PNG
      );
      expect(isValidPhotoBytes(padded([0x47, 0x49, 0x46, 0x38])), isTrue); // GIF
    });

    test('rejects non-images, empties, and oversize', () {
      expect(isValidPhotoBytes(Uint8List(0)), isFalse);
      expect(isValidPhotoBytes(Uint8List(8)), isFalse); // below min size
      // An executable / script masquerading as a photo.
      expect(isValidPhotoBytes(padded([0x4D, 0x5A])), isFalse); // MZ (exe)
      expect(
        isValidPhotoBytes(padded([0x3C, 0x73, 0x76, 0x67])), // "<svg"
        isFalse,
      );
      // Oversize is refused.
      expect(isValidPhotoBytes(Uint8List(kMaxPhotoBytes + 1)), isFalse);
    });
  });
}
