import 'package:flutter/material.dart';

/// The face shapes the "stylist AI" can detect from a photo.
enum FaceShape {
  oval('Oval'),
  round('Round'),
  square('Square'),
  heart('Heart'),
  oblong('Oblong'),
  diamond('Diamond');

  const FaceShape(this.label);
  final String label;

  /// A short, friendly description of the shape.
  String get blurb => switch (this) {
        FaceShape.oval =>
          'Balanced proportions — almost any cut works on you.',
        FaceShape.round =>
          'Soft, even width and height — height on top adds definition.',
        FaceShape.square =>
          'Strong jaw and forehead — sharp, structured cuts suit you.',
        FaceShape.heart =>
          'Wider forehead, narrower chin — softer, fuller sides balance it.',
        FaceShape.oblong =>
          'Longer than wide — shorter sides and low volume keep it even.',
        FaceShape.diamond =>
          'Wide cheekbones — fuller tops and fringes flatter the angles.',
      };
}

/// The drawn shape used to preview a cut on the user's photo. One per style.
enum HairSilhouette {
  buzz, // very short, hugs the scalp
  crew, // short and neat
  caesar, // short with a straight forehead fringe
  crop, // textured top, fringe forward
  taper, // medium top, faded sides
  sidePart, // parted to one side, comb-over
  pompadour, // tall volume swept up at the front
  quiff, // lifted front, medium volume
  slick, // smooth, swept straight back
  curtains, // grown out, parted down the middle
}

/// A hairstyle the user can browse, get recommended, try on, and book.
class Hairstyle {
  const Hairstyle({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.silhouette,
    required this.suits,
    required this.lengthLabel,
    required this.upkeep,
  });

  final String id;
  final String name;
  final String description;
  final IconData icon;

  /// The shape drawn over the photo when previewing this cut.
  final HairSilhouette silhouette;

  /// Face shapes this cut flatters most.
  final List<FaceShape> suits;

  /// e.g. "Short", "Medium".
  final String lengthLabel;

  /// e.g. "Low", "Medium", "High" maintenance.
  final String upkeep;
}
