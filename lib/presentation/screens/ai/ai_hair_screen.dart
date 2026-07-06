import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  };
  // Reads as: "<style>, <colour> hair, photoreal…" — and we nudge the model to
  // keep the same person (the mask is what truly protects the face).
  return '$desc, $c hair, photorealistic, sharp detail, natural hair texture, '
      'same person, same face, unchanged facial features';
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

  Future<void> _generate() async {
    final photo = _photo;
    final style = HairData.byId(_styleId);
    final color = HairColorName.from(_colorIndex);
    if (photo == null) {
      // Demo face — no real image to send; show the not-configured/preview UI.
      setState(() => _result = const HairAiResult(HairAiStatus.notConfigured));
      return;
    }
    final endpoint = AppState.instance.aiEndpoint;
    final key = AppState.instance.geminiKey;
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
      // Premium route — Google Gemini image editing.
      res = await _gemini.generate(
        photo: photo,
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

    final saved = await showDialog<bool>(
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
                    Text(L.stFreeWorkerUrl,
                        style: AppTypography.h4(context)),
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
    const names = ['Black', 'Brown', 'Chestnut', 'Blonde', 'Ash'];
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
          style: AppTypography.bodyLarge(context)
              .copyWith(color: p.textSecondary),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline_rounded, size: 14, color: p.textTertiary),
            const SizedBox(width: 5),
            Text(L.photoPrivacy,
                style: AppTypography.caption(context)),
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
    final color = HairColor.options[colorIndex];
    final realistic = result?.ok == true;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
      children: [
        Row(
          children: [
            Text(L.yourAiPreview, style: AppTypography.h2(context)),
            const Spacer(),
            CircleBtn(icon: Icons.close_rounded, size: 42, onTap: onClose),
          ],
        ),
        const SizedBox(height: 14),
        // The result image area.
        ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: AspectRatio(
            aspectRatio: 3 / 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (realistic)
                  Image.memory(result!.image!,
                      fit: BoxFit.cover, gaplessPlayback: true)
                else ...[
                  // Base photo (or demo face) + stylised preview overlay.
                  if (photo == null)
                    const CustomPaint(
                      painter: FacePlaceholderPainter(
                        skin: Color(0xFFE7C9A9),
                        bg: Color(0xFF16243B),
                      ),
                    )
                  else
                    Image.memory(photo!,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, __, ___) =>
                            const ColoredBox(color: Color(0xFF16243B))),
                  Center(
                    child: FractionallySizedBox(
                      widthFactor: 0.72,
                      heightFactor: 0.66,
                      alignment: const Alignment(0, -0.5),
                      child: CustomPaint(
                        painter: HairOverlayPainter(
                          silhouette: style.silhouette,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                ],
                if (generating)
                  Container(
                    color: AppColors.navy.withValues(alpha: 0.55),
                    child: const Center(
                      child: SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      ),
                    ),
                  ),
                // Badge: realistic vs preview.
                Positioned(
                  left: 12,
                  top: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: realistic
                          ? AppColors.accent
                          : AppColors.navy.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          realistic
                              ? Icons.auto_awesome_rounded
                              : Icons.brush_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          realistic ? L.stAiRender : L.stStylisedPreview,
                          style: GoogleFonts.nunito(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Connect-AI banner when there's no realistic engine yet.
        if (!realistic && !generating)
          _ConnectAiBanner(onConnect: onConnect, message: result?.message),
        // Real face read — shape, confidence and why the top cut suits it.
        if (analysis != null) ...[
          const SizedBox(height: 10),
          _FaceReadCard(analysis: analysis!),
        ],
        const SizedBox(height: 14),
        Text(L.pickACut, style: AppTypography.h3(context)),
        const SizedBox(height: 10),
        _StyleStrip(
          selectedId: styleId,
          onPick: onPickStyle,
          recommendedId: analysis?.recommended.id,
        ),
        const SizedBox(height: 16),
        Text(L.hairColour, style: AppTypography.h3(context)),
        const SizedBox(height: 10),
        _ColorStrip(selected: colorIndex, onPick: onPickColor),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: PrimaryButton(
                label: L.newPhoto,
                icon: Icons.cameraswitch_rounded,
                height: 54,
                style: PrimaryButtonStyle.ghost,
                onPressed: onRetake,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PrimaryButton(
                label: L.bookThisLook,
                height: 54,
                onPressed: () {
                  AppState.instance.setDesiredStyle(style.id);
                  final my = AppState.instance.myBarber;
                  final shop = my?.shop ?? MockData.barbershops.first;
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
            ),
          ],
        ),
      ],
    );
  }
}

/// Shows the *measured* face read: detected shape, a confidence chip, and the
/// one-line reason the recommended cut fits. Makes the recommendation feel
/// earned rather than random.
class _FaceReadCard extends StatelessWidget {
  const _FaceReadCard({required this.analysis});

  final StyleAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final pct = (analysis.confidence * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: clayDecoration(p, color: p.cardAlt, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.face_retouching_natural_rounded,
                  size: 18, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('${L.faceShapeLabel}: ${analysis.shape.label}',
                  style: AppTypography.h4(context)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('$pct% ${L.matchWord}',
                    style: GoogleFonts.nunito(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentDeep)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(analysis.reason, style: AppTypography.bodySmall(context)),
          if (analysis.alsoGood.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '${L.alsoGreatOnYou}: '
              '${analysis.alsoGood.map((s) => s.name).join(', ')}',
              style: AppTypography.caption(context),
            ),
          ],
        ],
      ),
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
    final body = message ??
        (hasKey ? L.stTapCheckKey : L.stStylisedPreviewTapAddKey);
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
                            child: CustomPaint(
                              size: Size.infinite,
                              painter: StyleGlyphPainter(
                                silhouette: s.silhouette,
                                ink: sel ? AppColors.accent : p.text,
                                bust: p.textSecondary.withValues(alpha: 0.22),
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
                    s.name,
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
  const _ColorStrip({required this.selected, required this.onPick});

  final int selected;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        for (var i = 0; i < HairColor.options.length; i++)
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
