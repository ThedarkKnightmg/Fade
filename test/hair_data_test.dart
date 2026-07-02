import 'package:barber_app/data/hair_data.dart';
import 'package:barber_app/data/models/hairstyle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HairData.forShape — recommendation from a measured face shape', () {
    test('recommends a cut that actually suits every detected shape', () {
      for (final shape in FaceShape.values) {
        final a = HairData.forShape(shape, confidence: 0.8);
        expect(
          a.recommended.suits.contains(shape),
          isTrue,
          reason: '${shape.label} got ${a.recommended.name}, '
              'which does not flatter it',
        );
      }
    });

    test('is deterministic — same shape always gives the same result', () {
      final a = HairData.forShape(FaceShape.oval, confidence: 0.8);
      final b = HairData.forShape(FaceShape.oval, confidence: 0.8);
      expect(a.shape, b.shape);
      expect(a.recommended.id, b.recommended.id);
      expect(a.reason, b.reason);
    });

    test('passes confidence through and clamps it', () {
      expect(HairData.forShape(FaceShape.round, confidence: 0.85).confidence,
          0.85);
      expect(HairData.forShape(FaceShape.round, confidence: 2.0).confidence,
          lessThanOrEqualTo(0.99));
      expect(HairData.forShape(FaceShape.round, confidence: -1.0).confidence,
          greaterThanOrEqualTo(0.0));
    });

    test('gives a non-empty, human reason', () {
      final a = HairData.forShape(FaceShape.oblong, confidence: 0.8);
      expect(a.reason, isNotEmpty);
      expect(a.reason, contains(a.recommended.name));
    });

    test('offers a few distinct runner-up cuts', () {
      final a = HairData.forShape(FaceShape.heart, confidence: 0.8);
      expect(a.alsoGood, isNotEmpty);
      expect(a.alsoGood.map((s) => s.id), isNot(contains(a.recommended.id)));
    });

    test('different shapes can surface different recommendations', () {
      final ids = {
        for (final shape in FaceShape.values)
          HairData.forShape(shape, confidence: 0.8).recommended.id,
      };
      // A real mapping spreads across the catalogue, not one hard-coded cut.
      expect(ids.length, greaterThan(2));
    });

    test('every catalogue style flatters at least one face shape', () {
      for (final style in HairData.styles) {
        expect(style.suits, isNotEmpty, reason: '${style.name} suits nobody');
      }
    });

    test('every face shape is flattered by at least one style', () {
      for (final shape in FaceShape.values) {
        expect(
          HairData.styles.any((s) => s.suits.contains(shape)),
          isTrue,
          reason: 'no cut flatters ${shape.label}',
        );
      }
    });

    test('byId resolves known ids and falls back safely', () {
      expect(HairData.byId('h_buzz').name, 'Buzz Cut');
      expect(HairData.byId('does_not_exist'), HairData.styles.first);
    });
  });
}
