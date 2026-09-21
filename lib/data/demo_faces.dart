/// Pre-rendered try-on photos for the demo face.
///
/// The Style Studio has two ways to show a haircut. On a real selfie it paints
/// a hair silhouette over the photo — cheap, instant, and obviously a drawing.
/// For the DEMO face we can do far better: one photograph of a person, plus a
/// render of that same person, same pose, same light, with only the hair
/// changed. Flipping between them looks like the haircut actually happening,
/// which is the whole promise of the feature.
///
/// ALL SIX catalogue styles now have a render, so the demo face never calls the
/// AI: it answers instantly, offline, and at no cost, with a picture that beats
/// what SD-1.5 inpainting produces from the same source. The fallbacks below
/// (painted silhouette, AI path) are kept for a style added later whose render
/// has not been produced yet — a missing file degrades instead of breaking.
///
/// Assets are produced by `tool/prep_faces.dart`, which crops each source
/// render to the hero's 3:4 portrait and compresses it (~1.5MB PNG → ~140KB
/// JPEG). The crop is identical for every image so the face stays pinned in
/// place; if it drifted, switching styles would look like different people.
class DemoFaces {
  DemoFaces._();

  /// The untouched demo face, shown before any style is chosen.
  static const String base = 'assets/faces/base.jpg';

  /// Hairstyle ids (see [HairData]) that have a real rendered photo.
  static const Set<String> _rendered = {
    'h_crop', // Textured Crop
    'h_buzz', // Buzz Cut
    'h_slick', // Slick Back
    'h_taper', // Classic Taper
    'h_pomp', // Pompadour
    'h_curly', // Curly Top
  };

  /// Hair-colour indices (into `HairColor.options`) that have renders.
  ///
  /// Recolouring a photo at runtime was the alternative and it fails in the
  /// direction that matters: brown to black is easy, brown to BLONDE needs
  /// lightening rather than a hue shift and comes out muddy, with a halo at the
  /// hairline. So the colours that exist are photographed, and the ones that do
  /// not are hidden rather than faked.
  ///
  /// 0 Black · 1 Brown · 2 Chestnut · 3 Blonde · 4 Ash
  static const Set<int> renderedColors = {
    1, // Brown — the base set of six
  };

  /// Filename suffix per colour. Brown is the original set, so it has none.
  static const Map<int, String> _colorSuffix = {
    0: '_black',
    1: '',
    3: '_blonde',
  };

  /// The colour used when none is specified — Brown, matching the shipped set.
  static const int defaultColor = 1;

  /// True when [styleId] in [colorIndex] can be shown as a photograph.
  static bool hasRender(String? styleId, {int colorIndex = defaultColor}) =>
      styleId != null &&
      _rendered.contains(styleId) &&
      renderedColors.contains(colorIndex) &&
      _colorSuffix.containsKey(colorIndex);

  /// The image for [styleId] in [colorIndex] — its render if one exists,
  /// otherwise the plain base face.
  static String assetFor(String? styleId, {int colorIndex = defaultColor}) =>
      hasRender(styleId, colorIndex: colorIndex)
          ? 'assets/faces/$styleId${_colorSuffix[colorIndex]}.jpg'
          : base;

  /// Colours the demo face can actually show, so the picker can hide swatches
  /// that would do nothing — a dead swatch reads as a broken feature.
  static bool colorAvailable(int colorIndex) =>
      renderedColors.contains(colorIndex);
}
