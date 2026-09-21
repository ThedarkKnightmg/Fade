import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;

import '../../../core/ai/ai_config.dart';
import '../../../core/ai/face_analyzer.dart';
import '../../../core/ai/gemini_hair_service.dart';
import '../../../core/ai/hair_ai_service.dart';
import '../../../core/ai/hair_mask.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/demo_faces.dart';
import '../../../data/hair_data.dart';
import '../../../data/models/hairstyle.dart';
import '../../../data/mock_data.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../booking/booking_flow_screen.dart';
import '../style/hair_overlay.dart';
import 'camera_screen.dart';
import 'face_scan.dart';

enum _Phase { intro, scanning, result }

/// A vivid, model-friendly description of the chosen cut so the AI renders the
/// *actual* style picked (not a generic "haircut"). Used for both the free
/// worker and Gemini so the request matches the swatch the user selected.
String _aiHairDescription(Hairstyle style, String color) {
  final c = color.toLowerCase();
  final desc = switch (style.silhouette) {
    HairSilhouette.buzz =>
      'a buzz cut, very short even clipper-shaved hair all over the head',
    HairSilhouette.crew =>
      'a crew cut, short tapered back and sides with a little length on top',
    HairSilhouette.caesar =>
      'a Caesar cut, short even length with a short straight forehead fringe',
    HairSilhouette.crop =>
      'a textured French crop, faded sides with a short blunt fringe',
    HairSilhouette.taper =>
      'a taper fade, short faded back and sides with a longer textured top',
    HairSilhouette.sidePart =>
      'a classic side part, neatly combed to one side with faded sides',
    HairSilhouette.pompadour =>
      'a voluminous pompadour swept up and back, height on top, short sides',
    HairSilhouette.quiff =>
      'a modern quiff, lifted volume at the front with short sides',
    HairSilhouette.slick =>
      'a slicked-back hairstyle combed straight back with a glossy finish',
    HairSilhouette.curtains =>
      'a middle-parted curtains cut with a soft fringe split to both sides',
    // Named curl pattern and the tight sides both matter: without "short
    // sides" the model tends to render an all-over afro, and without the
    // explicit curl words it returns wavy rather than curly hair.
    HairSilhouette.curly =>
      'a curly top haircut, defined springy natural curls left long on top, '
          'short tapered sides and back, voluminous curl pattern',
  };
  // Reads as: "<style>, <colour> hair, photoreal…" — and we nudge the model to
  // keep the same person (the mask is what truly protects the face).
  //
  // The detail terms matter: Workers AI caps num_steps at 20, so we can't buy
  // sharpness with more steps — the prompt is the only lever left. Naming the
  // strand-level texture and the lighting is what stops the output reading as a
  // soft blurry wig.
  return '$desc, $c hair, photorealistic portrait photograph, '
      'individual hair strands, sharp fine detail, realistic hair texture, '
      'clean defined hairline, natural scalp, soft studio lighting, '
      'high detail, 4k, same person, same face, unchanged facial features';
}

/// Caps the longest edge of [photo] at 768px (aspect-ratio preserved) before
/// an AI upload. The free worker route already normalises via
/// [preparePhotoSquare]; Gemini gets this so it never receives a full-res
/// selfie. 768 is a hard ceiling — SD-1.5 inpainting returns all-black output
/// above it. Returns the original bytes unchanged if it's already small enough
/// or can't be decoded.
Uint8List _downscaleForAi(Uint8List photo, {int maxEdge = 768}) {
  try {
    final decoded = img.decodeImage(photo);
    if (decoded == null) return photo;
    final longest =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (longest <= maxEdge) return photo;
    final resized = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxEdge)
        : img.copyResize(decoded, height: maxEdge);
    return img.encodeJpg(resized, quality: 90);
  } catch (_) {
    return photo;
  }
}

/// AI Hair Studio — take a selfie, watch the AI "read" your face, then see
/// your hair re-rendered. Real photo-realistic output comes from a connected
/// AI service ([AiConfig]); without a key it shows a clearly-labelled
/// stylised preview and how to switch the real engine on.
class AiHairScreen extends StatefulWidget {
  const AiHairScreen({super.key});

  @override
  State<AiHairScreen> createState() => _AiHairScreenState();
}

class _AiHairScreenState extends State<AiHairScreen> {
  final HairAiService _ai = HairAiService();
  final GeminiHairService _gemini = GeminiHairService();

  _Phase _phase = _Phase.intro;
  Uint8List? _photo; // null = demo face
  String _styleId = HairData.styles.first.id;
  int _colorIndex = 1;

  bool _generating = false;
  HairAiResult? _result;
  StyleAnalysis? _analysis; // real face read (shape + reason)

  @override
  void dispose() {
    _ai.dispose();
    _gemini.dispose();
    super.dispose();
  }

  Future<void> _capture({required bool camera}) async {
    Uint8List? bytes;
    if (camera) {
      if (kIsWeb) {
        // Web: live getUserMedia camera screen (returns the captured frame).
        bytes = await Navigator.of(context).push<Uint8List>(
          MaterialPageRoute(builder: (_) => const CameraScreen()),
        );
      } else {
        // Native: open the real device camera via image_picker.
        try {
          bytes = await capturePhoto(camera: true);
        } catch (_) {
          bytes = null;
        }
      }
    } else {
      try {
        bytes = await capturePhoto(camera: false);
      } catch (_) {
        bytes = null;
      }
    }
    if (!mounted) return;
    if (bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.noPhotoSelected)),
      );
      return;
    }
    _startScan(bytes, display: true);
  }

  void _useDemo() {
    final seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    final bytes = Uint8List(1024);
    var x = seed == 0 ? 1 : seed;
    for (var i = 0; i < bytes.length; i++) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      bytes[i] = (x >> 16) & 0xff;
    }
    _startScan(bytes, display: false);
  }

  Future<void> _startScan(Uint8List bytes, {required bool display}) async {
    setState(() {
      _photo = display ? bytes : null;
      _phase = _Phase.scanning;
      _result = null;
      _analysis = null;
    });
    // Real analysis runs while the scan animation plays (~2.6s of cover).
    final analysis = await FaceAnalyzer.analyse(bytes);
    if (!mounted) return;
    setState(() {
      _analysis = analysis;
      _styleId = analysis.recommended.id;
      // The AI read your hair colour from the photo — preselect that swatch.
      if (analysis.suggestedColorIndex != null) {
        _colorIndex = analysis.suggestedColorIndex!;
      }
    });
  }

  void _onScanDone() {
    if (!mounted) return;
    setState(() => _phase = _Phase.result);
    _generate();
  }

  /// One-time consent before the first selfie upload. Returns true if the user
  /// agreed to send the photo to the AI service.
  Future<bool?> _askAiConsent() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.aiConsentTitle),
        content: Text(L.aiConsentBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L.notNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L.aiConsentAccept),
          ),
        ],
      ),
    );
  }

  /// The bundled demo photo's bytes, loaded once and cached.
  ///
  /// Kept separate from [_photo] on purpose: `_photo == null` is what marks
  /// "this is the demo face" throughout this screen (it drives which image is
  /// shown and suppresses the drawn hair overlay). Stuffing the demo bytes in
  /// there would silently turn the demo into a "real selfie" everywhere.
  Uint8List? _demoBytesCache;

  /// The pre-rendered photo of the demo face wearing [styleId].
  Future<Uint8List?> _renderedStyleBytes(String styleId) async {
    try {
      final data = await rootBundle.load(DemoFaces.assetFor(styleId));
      return data.buffer.asUint8List();
    } catch (_) {
      return null; // asset missing → fall through to the AI path
    }
  }

  Future<Uint8List?> _demoFaceBytes() async {
    if (_demoBytesCache != null) return _demoBytesCache;
    try {
      final data = await rootBundle.load(DemoFaces.base);
      return _demoBytesCache = data.buffer.asUint8List();
    } catch (_) {
      return null; // asset missing → fall back to the preview UI
    }
  }

  Future<void> _generate() async {
    final style = HairData.byId(_styleId);
    final color = HairColorName.from(_colorIndex);
    // THE DEMO FACE DOES NOT USE THE AI.
    //
    // Every style on this face has a hand-made render of that exact person —
    // same pose, same light, only the hair changed. Those beat SD-1.5
    // inpainting comfortably, and they are instant, free, and work with no
    // signal. Sending the demo face to a model would spend seconds and a
    // network round trip to produce something worse.
    //
    // Styles without a render yet fall through to the AI, so the path still
    // works while the remaining images are produced.
    if (_photo == null && DemoFaces.hasRender(_styleId)) {
      final bytes = await _renderedStyleBytes(_styleId);
      if (bytes != null) {
        setState(() => _result = HairAiResult(HairAiStatus.success, image: bytes));
        return;
      }
    }

    final photo = _photo ?? await _demoFaceBytes();
    if (photo == null) {
      setState(() => _result = const HairAiResult(HairAiStatus.notConfigured));
      return;
    }
    final endpoint = AppState.instance.aiEndpoint;
    final key = AppState.instance.geminiKey;
    // The photo is about to leave the device. If a real engine is connected and
    // the user hasn't agreed yet, ask ONCE before uploading anything.
    final willUpload =
        endpoint.trim().isNotEmpty || key.trim().isNotEmpty;
    if (willUpload && !AppState.instance.aiConsent) {
      final agreed = await _askAiConsent();
      if (agreed != true) return; // declined — nothing is sent
      AppState.instance.grantAiConsent();
    }
    setState(() => _generating = true);
    final HairAiResult res;
    final desc = _aiHairDescription(style, color);
    if (endpoint.trim().isNotEmpty) {
      // Free route — a Cloudflare worker. Normalise to a crisp 768px square
      // (1024 makes SD-1.5 inpainting output black), then mask the hair so
      // only it is repainted.
      final square = await preparePhotoSquare(photo) ?? photo;
      final mask = await buildHairMask(square, silhouette: style.silhouette);
      res = await _ai.generate(
        photo: square,
        hairstyle: style.name,
        color: color,
        prompt: desc,
        endpoint: endpoint,
        mask: mask,
      );
    } else if (key.trim().isNotEmpty) {
      // Premium route — Google Gemini image editing. Downscale first (longest
      // edge ≤ 768px) so we never upload a full-res selfie, mirroring the
      // worker route's normalisation.
      final scaled = _downscaleForAi(photo);
      res = await _gemini.generate(
        photo: scaled,
        apiKey: key,
        prompt: 'Change only the hair to $desc. Keep the exact same face, '
            'skin, identity, expression, lighting and background. '
            'Photorealistic result.',
      );
    } else {
      // Nothing connected → notConfigured → stylised preview.
      res = await _ai.generate(
        photo: photo,
        hairstyle: style.name,
        color: color,
        prompt: desc,
      );
    }
    if (!mounted) return;
    setState(() {
      _result = res;
      _generating = false;
    });
  }

  /// Connect a real AI engine: a free worker URL (Cloudflare) or a Gemini key.
  Future<void> _enterKey() async {
    final urlCtrl = TextEditingController(text: AppState.instance.aiEndpoint);
    final keyCtrl = TextEditingController(text: AppState.instance.geminiKey);
    final p = Paper.of(context);

    InputDecoration deco(String hint) => InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: p.cardAlt,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
        );

    final bool? saved;
    try {
      saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: p.card,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.connectAi, style: AppTypography.h3(context)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.bolt_rounded,
                          size: 16, color: AppColors.green),
                      const SizedBox(width: 6),
                      Text(L.stFreeWorkerUrl, style: AppTypography.h4(context)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    maxLines: 1,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700, color: p.text),
                    decoration: deco('https://barber-ai.<you>.workers.dev'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    L.stFreeWorkerHint,
                    style: AppTypography.caption(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.workspace_premium_rounded,
                          size: 16, color: p.textSecondary),
                      const SizedBox(width: 6),
                      Text(L.stPremiumGeminiKey,
                          style: AppTypography.h4(context)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: keyCtrl,
                    maxLines: 1,
                    style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w700, color: p.text),
                    decoration: deco('AIza…  ${L.stNeedsBilling}'),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: PrimaryButton(
                          label: L.cancel,
                          height: 48,
                          style: PrimaryButtonStyle.ghost,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: PrimaryButton(
                          label: L.stSave,
                          height: 48,
                          onPressed: () {
                            AppState.instance.setAiEndpoint(urlCtrl.text);
                            AppState.instance.setGeminiKey(keyCtrl.text);
                            Navigator.pop(ctx, true);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      urlCtrl.dispose();
      keyCtrl.dispose();
    }
    if (saved == true && mounted && _photo != null) _generate();
  }

  void _retake() {
    setState(() {
      _phase = _Phase.intro;
      _photo = null;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.bgGradientTop, p.bg],
            stops: const [0, 0.35],
          ),
        ),
        child: SafeArea(
          child: switch (_phase) {
            _Phase.intro => _IntroView(
                onTakePhoto: () => _capture(camera: true),
                onUpload: () => _capture(camera: false),
                onDemo: _useDemo,
                onClose: () => Navigator.of(context).maybePop(),
              ),
            _Phase.scanning => FaceScanView(
                photo: _photo,
                onDone: _onScanDone,
              ),
            _Phase.result => _ResultView(
                photo: _photo,
                demoBytes: _demoBytesCache,
                styleId: _styleId,
                colorIndex: _colorIndex,
                generating: _generating,
                result: _result,
                analysis: _analysis,
                onPickStyle: (id) {
                  setState(() => _styleId = id);
                  _generate();
                },
                onPickColor: (i) {
                  setState(() => _colorIndex = i);
                  _generate();
                },
                onRetake: _retake,
                onConnect: _enterKey,
                onClose: () => Navigator.of(context).maybePop(),
              ),
          },
        ),
      ),
    );
  }
}

/// Maps the colour index to a readable name for the AI prompt.
class HairColorName {
  static String from(int i) {
    // These strings go straight into the image prompt, so they are written the
    // way a colourist would describe the dye — "vivid purple" alone tends to
    // produce a flat cartoon wig.
    const names = [
      'Black',
      'Brown',
      'Chestnut',
      'Blonde',
      'Ash',
      'vivid violet purple dyed',
      'emerald green dyed',
    ];
    return names[i % names.length];
  }
}

// ============================================================
// Intro
// ============================================================

class _IntroView extends StatelessWidget {
  const _IntroView({
    required this.onTakePhoto,
    required this.onUpload,
    required this.onDemo,
    required this.onClose,
  });

  final VoidCallback onTakePhoto;
  final VoidCallback onUpload;
  final VoidCallback onDemo;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
      children: [
        Row(
          children: [
            _GlowChip(),
            const Spacer(),
            CircleBtn(
              icon: Icons.close_rounded,
              size: 42,
              onTap: onClose,
            ),
          ],
        ),
        const SizedBox(height: 26),
        Text(L.aiHairStudio, style: AppTypography.display(context)),
        const SizedBox(height: 8),
        Text(
          L.stAiHairIntro,
          style:
              AppTypography.bodyLarge(context).copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: 28),
        // Glowing hero orb, gently floating.
        Center(
          child: Floaty(
            dy: 10,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3D9BFF), Color(0xFF1E6FE0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.5),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.auto_awesome_rounded,
                  size: 64, color: Colors.white),
            ),
          ),
        ),

        const SizedBox(height: 34),
        PrimaryButton(
          label: L.takeSelfie,
          icon: Icons.photo_camera_rounded,
          height: 58,
          onPressed: onTakePhoto,
        ),
        const SizedBox(height: 12),
        PrimaryButton(
          label: L.uploadPhoto,
          icon: Icons.image_outlined,
          height: 58,
          style: PrimaryButtonStyle.ghost,
          onPressed: onUpload,
        ),
        const SizedBox(height: 14),
        Center(
          child: GestureDetector(
            onTap: onDemo,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                L.stTryDemoFace,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // The privacy note is now a full sentence (honest AI-upload
        // disclosure), so the text must be allowed to WRAP — as a bare Row
        // child it overflowed ~294px off the right edge.
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(Icons.lock_outline_rounded,
                  size: 14, color: p.textTertiary),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                L.photoPrivacy,
                style: AppTypography.caption(context),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlowChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3D9BFF), Color(0xFF1E6FE0)],
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text('AI',
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1)),
        ],
      ),
    );
  }
}

// ============================================================
// Result
// ============================================================

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.photo,
    this.demoBytes,
    required this.styleId,
    required this.colorIndex,
    required this.generating,
    required this.result,
    required this.analysis,
    required this.onPickStyle,
    required this.onPickColor,
    required this.onRetake,
    required this.onConnect,
    required this.onClose,
  });

  final Uint8List? photo;

  /// The bundled demo photo, supplied when [photo] is null so the before/after
  /// comparison still has a "before" to show on the demo face.
  final Uint8List? demoBytes;
  final String styleId;
  final int colorIndex;
  final bool generating;
  final HairAiResult? result;
  final StyleAnalysis? analysis;
  final ValueChanged<String> onPickStyle;
  final ValueChanged<int> onPickColor;
  final VoidCallback onRetake;
  final VoidCallback onConnect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final style = HairData.byId(styleId);
    final realistic = result?.ok == true;

    final p = Paper.of(context);
    // Hero-first layout: the look you're trying on fills the screen, and the
    // controls sit in a panel beneath it. The old layout put the photo inside a
    // scrolling form, so your own face scrolled away the moment you reached for
    // a style — the one thing you actually came to look at.
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── The look ──────────────────────────────────────────────
              if (realistic && (photo ?? demoBytes) != null)
                // A real render AND the original → let them drag between the
                // two. Seeing the change IS the product. The demo face gets
                // this as well, using the bundled photo as the "before".
                _CompareView(
                    before: (photo ?? demoBytes)!, after: result!.image!)
              else if (realistic)
                Image.memory(result!.image!,
                    fit: BoxFit.cover, gaplessPlayback: true)
              else ...[
                if (photo == null)
                  Image.asset(
                    DemoFaces.base,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, __, ___) => const CustomPaint(
                      painter: FacePlaceholderPainter(
                        skin: Color(0xFFE7C9A9),
                        bg: Color(0xFF16243B),
                      ),
                    ),
                  )
                else
                  Image.memory(photo!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) =>
                          const ColoredBox(color: Color(0xFF16243B))),
                // The drawn hair overlay is GONE from this screen entirely —
                // demo face and real selfie alike. Its geometry was built for
                // the old cartoon placeholder head, so on any photograph it
                // lands across the eyes, and it was painting hair on top of
                // hair that is already in the picture. The demo face has real
                // renders for every style, and a real selfie has the AI; a
                // drawn blob helps neither.
              ],

              // ── Top scrim so the controls stay readable on any photo ──
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 130,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                top: 10,
                child: Row(
                  children: [
                    _GlassBadge(
                      icon: realistic
                          ? Icons.auto_awesome_rounded
                          : Icons.brush_rounded,
                      label: realistic ? L.stAiRender : L.stStylisedPreview,
                      accent: realistic,
                    ),
                    const Spacer(),
                    _GlassIconBtn(
                        icon: Icons.close_rounded, onTap: onClose),
                  ],
                ),
              ),

              // ── Working state: a scanning sweep, not a bare spinner ───
              if (generating) _GeneratingOverlay(),
            ],
          ),
        ),

        // ── Controls panel ──────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // One compact line instead of two stacked cards: what the AI
                // read in your face, and the cut it suggests.
                if (analysis != null) ...[
                  _FaceReadLine(analysis: analysis!),
                  const SizedBox(height: 12),
                ],
                if (!realistic && !generating) ...[
                  _ConnectAiBanner(
                      onConnect: onConnect, message: result?.message),
                  const SizedBox(height: 12),
                ],
                _StyleStrip(
                  selectedId: styleId,
                  onPick: onPickStyle,
                  recommendedId: analysis?.recommended.id,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _ColorStrip(
                        selected: colorIndex,
                        onPick: onPickColor,
                        // Demo face = photographed colours only; a real selfie
                        // goes through the AI, which can do any of them.
                        limitToRendered: photo == null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _GhostSquare(
                        icon: Icons.cameraswitch_rounded, onTap: onRetake),
                  ],
                ),
                const SizedBox(height: 12),
                PrimaryButton(
                  label: L.bookThisLook,
                  height: 54,
                  onPressed: () {
                    AppState.instance.setDesiredStyle(style.id);
                    final my = AppState.instance.myBarber;
                    final shop = my?.shop ??
                        (MockData.barbershops.isEmpty
                            ? null
                            : MockData.barbershops.first);
                    if (shop == null) return; // empty catalogue → nothing to book
                    Navigator.of(context).push(
                      FadeThroughPageRoute(
                        child: BookingFlowScreen(
                          shop: shop,
                          preselectedBarberId: my?.barber.id,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Before/after comparison — drag the handle to wipe between the original photo
/// and the AI render. This is the payoff of the whole feature: a single result
/// image tells you nothing about what actually changed.
class _CompareView extends StatefulWidget {
  const _CompareView({required this.before, required this.after});

  final Uint8List before;
  final Uint8List after;

  @override
  State<_CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<_CompareView> {
  double _split = 0.55; // fraction of width showing the "after"

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        void setFromDx(double dx) =>
            setState(() => _split = (dx / c.maxWidth).clamp(0.06, 0.94));
        return GestureDetector(
          onHorizontalDragUpdate: (d) => setFromDx(d.localPosition.dx),
          onTapDown: (d) => setFromDx(d.localPosition.dx),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // BEFORE fills the frame…
              Image.memory(widget.before,
                  fit: BoxFit.cover, gaplessPlayback: true),
              // …and AFTER is revealed from the left up to the split.
              ClipRect(
                clipper: _LeftClipper(_split),
                child: Image.memory(widget.after,
                    fit: BoxFit.cover, gaplessPlayback: true),
              ),
              // Labels on each side of the divider.
              Positioned(
                left: 14,
                bottom: 16,
                child: _GlassBadge(label: L.afterWord, accent: true),
              ),
              Positioned(
                right: 14,
                bottom: 16,
                child: _GlassBadge(label: L.beforeWord),
              ),
              // The divider + grab handle.
              Positioned(
                left: c.maxWidth * _split - 1,
                top: 0,
                bottom: 0,
                width: 2,
                child: const ColoredBox(color: Colors.white),
              ),
              Positioned(
                left: c.maxWidth * _split - 20,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.28),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.code_rounded,
                        size: 20, color: AppColors.accentDeep),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Clips a child to the left [fraction] of the available width.
class _LeftClipper extends CustomClipper<Rect> {
  _LeftClipper(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftClipper old) => old.fraction != fraction;
}

/// A translucent pill that stays legible over any photo.
class _GlassBadge extends StatelessWidget {
  const _GlassBadge({this.icon, required this.label, this.accent = false});

  final IconData? icon;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 12 : 9, 6, 12, 6),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.accent.withValues(alpha: 0.92)
            : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassIconBtn extends StatelessWidget {
  const _GlassIconBtn({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 21, color: Colors.white),
      ),
    );
  }
}

class _GhostSquare extends StatelessWidget {
  const _GhostSquare({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: p.cardAlt,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: p.border),
        ),
        child: Icon(icon, size: 21, color: p.textSecondary),
      ),
    );
  }
}

/// While the model runs: a soft sweep across the photo, so it reads as the AI
/// working on YOUR image rather than a generic spinner on a grey wash.
class _GeneratingOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.navy.withValues(alpha: 0.45),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Breathe(
            period: const Duration(milliseconds: 1500),
            builder: (context, t) => Align(
              alignment: Alignment(0, -1 + 2 * t),
              child: Container(
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0),
                      Colors.white.withValues(alpha: 0.20),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  L.aiWorking,
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The face read as ONE compact line (shape · confidence · why), replacing the
/// old card so the panel keeps its room for the controls.
class _FaceReadLine extends StatelessWidget {
  const _FaceReadLine({required this.analysis});

  final StyleAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final pct = (analysis.confidence * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.face_retouching_natural_rounded,
                size: 16, color: AppColors.accent),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                '${analysis.shape.label} · ${L.tr(analysis.recommended.name)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: p.text,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('$pct% ${L.matchWord}',
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accentDeep)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        // The "why" — what makes the recommendation feel earned rather than
        // random. One line, so it informs without eating the panel.
        Text(
          analysis.reason,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption(context),
        ),
      ],
    );
  }
}

class _ConnectAiBanner extends StatelessWidget {
  const _ConnectAiBanner({required this.onConnect, this.message});

  final VoidCallback onConnect;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final hasKey = AppState.instance.hasAiKey;
    final title = hasKey ? L.aiRenderFailed : L.connectAiForHair;
    final body =
        message ?? (hasKey ? L.stTapCheckKey : L.stStylisedPreviewTapAddKey);
    return GestureDetector(
      onTap: onConnect,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: clayDecoration(
          p,
          color: AppColors.accentSoft,
          radius: 18,
          borderColor: AppColors.accent.withValues(alpha: 0.5),
        ),
        child: Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.accent, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h4(context)),
                  const SizedBox(height: 2),
                  Text(body, style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _StyleStrip extends StatelessWidget {
  const _StyleStrip({
    required this.selectedId,
    required this.onPick,
    this.recommendedId,
  });

  final String selectedId;
  final ValueChanged<String> onPick;

  /// The AI's pick — gets a star so the recommendation stays visible even when
  /// the user is browsing other cuts.
  final String? recommendedId;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: HairData.styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final s = HairData.styles[i];
          final sel = s.id == selectedId;
          final isRec = s.id == recommendedId;
          return GestureDetector(
            onTap: () => onPick(s.id),
            child: SizedBox(
              width: 82,
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: p.cardAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: sel ? AppColors.accent : p.border,
                                width: sel ? 2.4 : 1,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            // The real photograph of this exact cut, not a
                            // schematic glyph. A drawn icon shows the SHAPE of
                            // a haircut; only a photo shows the fade line, the
                            // texture and the curl pattern — which is what a
                            // client is actually choosing between. Framed on
                            // the head, since the thumbnail is small and the
                            // hair is the only part that matters here.
                            child: DemoFaces.hasRender(s.id)
                                ? Image.asset(
                                    DemoFaces.assetFor(s.id),
                                    fit: BoxFit.cover,
                                    alignment: const Alignment(0, -0.72),
                                    errorBuilder: (_, __, ___) => CustomPaint(
                                      size: Size.infinite,
                                      painter: StyleGlyphPainter(
                                        silhouette: s.silhouette,
                                        ink: sel ? AppColors.accent : p.text,
                                        bust: p.textSecondary
                                            .withValues(alpha: 0.22),
                                      ),
                                    ),
                                  )
                                : CustomPaint(
                                    size: Size.infinite,
                                    painter: StyleGlyphPainter(
                                      silhouette: s.silhouette,
                                      ink: sel ? AppColors.accent : p.text,
                                      bust: p.textSecondary
                                          .withValues(alpha: 0.22),
                                    ),
                                  ),
                          ),
                        ),
                        if (isRec)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.accent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded,
                                  size: 12, color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    L.tr(s.name),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: sel ? p.text : p.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ColorStrip extends StatelessWidget {
  const _ColorStrip({
    required this.selected,
    required this.onPick,
    this.limitToRendered = false,
  });

  final int selected;
  final ValueChanged<int> onPick;

  /// On the DEMO face only the photographed colours can actually be shown, so
  /// the rest are hidden. A swatch that visibly does nothing when tapped reads
  /// as a broken feature, which is worse than a shorter row.
  final bool limitToRendered;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        for (var i = 0; i < HairColor.options.length; i++)
          if (!limitToRendered || DemoFaces.colorAvailable(i))
          GestureDetector(
            onTap: () => onPick(i),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: HairColor.options[i].hair,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == i ? AppColors.accent : p.border,
                  width: selected == i ? 3 : 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
