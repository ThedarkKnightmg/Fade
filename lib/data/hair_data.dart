import 'package:flutter/material.dart';

import 'models/hairstyle.dart';

/// The result of analysing a selfie.
class StyleAnalysis {
  const StyleAnalysis({
    required this.shape,
    required this.confidence,
    required this.recommended,
    required this.alsoGood,
    required this.reason,
    this.suggestedColorIndex,
  });

  final FaceShape shape;

  /// 0..1 — shown as a percentage.
  final double confidence;

  /// The single best match.
  final Hairstyle recommended;

  /// A couple of strong runner-up cuts.
  final List<Hairstyle> alsoGood;

  /// A short, human reason the cut suits this face — shown under the result.
  final String reason;

  /// Hair colour read from the photo (index into HairColor.options), or null
  /// when it couldn't be told confidently — then the UI keeps its default.
  final int? suggestedColorIndex;
}

/// Static catalogue + the mock "stylist AI". No real ML — the analysis is
/// derived deterministically from the photo bytes so the same picture always
/// gives the same answer (it feels like real detection, and it's testable).
class HairData {
  HairData._();

  static const List<Hairstyle> styles = [
    Hairstyle(
      id: 'h_taper',
      name: 'Classic Taper',
      description:
          'Clean, gradual fade on the sides with length kept on top. Timeless and office-friendly.',
      icon: Icons.cut_rounded,
      silhouette: HairSilhouette.taper,
      suits: [FaceShape.oval, FaceShape.square, FaceShape.heart],
      lengthLabel: 'Short sides',
      upkeep: 'Low upkeep',
    ),
    Hairstyle(
      id: 'h_crop',
      name: 'Textured Crop',
      description:
          'Choppy, textured top with a faded back and sides. Adds movement and hides thinning.',
      icon: Icons.grass_rounded,
      silhouette: HairSilhouette.crop,
      suits: [FaceShape.round, FaceShape.oval, FaceShape.square],
      lengthLabel: 'Short',
      upkeep: 'Low upkeep',
    ),
    Hairstyle(
      id: 'h_pomp',
      name: 'Pompadour',
      description:
          'Volume swept up and back from the forehead. Bold, retro, and full of height.',
      icon: Icons.waves_rounded,
      silhouette: HairSilhouette.pompadour,
      suits: [FaceShape.oval, FaceShape.round, FaceShape.diamond],
      lengthLabel: 'Medium',
      upkeep: 'High upkeep',
    ),
    Hairstyle(
      id: 'h_buzz',
      name: 'Buzz Cut',
      description:
          'Uniform short clipper cut. Fuss-free, sharp, and lets a strong jaw do the talking.',
      icon: Icons.blur_on_rounded,
      silhouette: HairSilhouette.buzz,
      suits: [FaceShape.oval, FaceShape.square, FaceShape.diamond],
      lengthLabel: 'Very short',
      upkeep: 'No upkeep',
    ),
    Hairstyle(
      id: 'h_slick',
      name: 'Slick Back',
      description:
          'Everything combed straight back with a glossy finish. Confident and grown-up.',
      icon: Icons.east_rounded,
      silhouette: HairSilhouette.slick,
      suits: [FaceShape.oval, FaceShape.oblong, FaceShape.diamond],
      lengthLabel: 'Medium / long',
      upkeep: 'Medium upkeep',
    ),
  ];

  static Hairstyle byId(String id) =>
      styles.firstWhere((s) => s.id == id, orElse: () => styles.first);

  /// Build the recommendation for a *measured* face shape (the real geometry
  /// comes from [FaceAnalyzer]). Cuts that flatter this shape rank first, in a
  /// stable order, so the same face always gets the same, explainable answer.
  static StyleAnalysis forShape(
    FaceShape shape, {
    required double confidence,
    int? colorIndex,
  }) {
    final suited = styles.where((s) => s.suits.contains(shape)).toList();
    final rest = styles.where((s) => !s.suits.contains(shape)).toList();
    final ranked = [...suited, ...rest];
    final recommended = ranked.first;
    return StyleAnalysis(
      shape: shape,
      confidence: confidence.clamp(0.0, 0.99),
      recommended: recommended,
      alsoGood: ranked.skip(1).take(2).toList(),
      reason: _reasonFor(shape, recommended),
      suggestedColorIndex: colorIndex,
    );
  }

  /// One readable sentence on why the top cut fits the detected shape.
  static String _reasonFor(FaceShape shape, Hairstyle rec) {
    final why = switch (shape) {
      FaceShape.oval =>
        'your balanced proportions let it sit cleanly without fighting your features',
      FaceShape.round =>
        'its height on top lengthens a softer, rounder face',
      FaceShape.square =>
        'it works with a strong jaw instead of squaring it off further',
      FaceShape.heart =>
        'fuller sides balance a wider forehead and narrower chin',
      FaceShape.oblong =>
        'shorter sides and low volume stop a longer face reading even longer',
      FaceShape.diamond =>
        'volume and a fringe up top soften prominent cheekbones',
    };
    return '${rec.name} suits you because $why.';
  }
}
