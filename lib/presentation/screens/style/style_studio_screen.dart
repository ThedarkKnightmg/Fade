import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/ai/face_analyzer.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/hair_data.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/hairstyle.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../ai/camera_screen.dart';
import '../booking/booking_flow_screen.dart';
import 'hair_overlay.dart';

enum _Phase { empty, analysing, tryOn }

/// Snap a selfie → see each cut drawn on your own photo → swipe between
/// styles and adjust the fit → book the look. No ML backend: the preview is
/// a clean, stylised hair overlay you position over your head.
class StyleStudioScreen extends StatefulWidget {
  const StyleStudioScreen({super.key});

  @override
  State<StyleStudioScreen> createState() => _StyleStudioScreenState();
}

class _StyleStudioScreenState extends State<StyleStudioScreen> {
  _Phase _phase = _Phase.empty;
  Uint8List? _photo; // null = demo (use the placeholder face)
  StyleAnalysis? _analysis;
  String? _selectedId;

  // Try-on fit controls.
  int _colorIndex = 1; // Brown by default
  Offset _hairOffset = Offset.zero; // fractional nudge of the overlay
  double _hairScale = 1.0;

  Future<void> _capture({required bool camera}) async {
    Uint8List? bytes;
    if (camera) {
      if (kIsWeb) {
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
    if (bytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No photo selected — try "demo selfie" to preview.'),
        ),
      );
      return;
    }
    _runAnalysis(bytes);
  }

  void _useDemo() {
    final seed = DateTime.now().microsecondsSinceEpoch & 0x7fffffff;
    final bytes = Uint8List(1024);
    var x = seed == 0 ? 1 : seed;
    for (var i = 0; i < bytes.length; i++) {
      x = (x * 1103515245 + 12345) & 0x7fffffff;
      bytes[i] = (x >> 16) & 0xff;
    }
    _runAnalysis(bytes, display: false);
  }

  Future<void> _runAnalysis(Uint8List bytes, {bool display = true}) async {
    if (!mounted) return;
    setState(() {
      _photo = display ? bytes : null;
      _phase = _Phase.analysing;
      _analysis = null;
      _hairOffset = Offset.zero;
      _hairScale = 1.0;
    });
    final result = await FaceAnalyzer.analyse(bytes);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {
      _analysis = result;
      _selectedId = result.recommended.id;
      _phase = _Phase.tryOn;
    });
  }

  void _retake() {
    setState(() {
      _phase = _Phase.empty;
      _photo = null;
      _analysis = null;
    });
  }

  void _onHairPan(Offset deltaFraction) {
    setState(() {
      _hairOffset = Offset(
        (_hairOffset.dx + deltaFraction.dx).clamp(-0.25, 0.25),
        (_hairOffset.dy + deltaFraction.dy).clamp(-0.18, 0.30),
      );
    });
  }

  void _bookLook() {
    final id = _selectedId;
    if (id == null) return;
    AppState.instance.setDesiredStyle(id);
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
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final selected = _selectedId == null ? null : HairData.byId(_selectedId!);
    final color = HairColor.options[_colorIndex];

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: _phase == _Phase.tryOn
            ? _buildTryOn(context, selected!, color)
            : _buildIntro(context),
      ),
      bottomNavigationBar: _phase == _Phase.tryOn && selected != null
          ? _BookBar(style: selected, onBook: _bookLook)
          : null,
    );
  }

  // ---- Intro (empty + analysing) --------------------------------------

  Widget _buildIntro(BuildContext context) {
    final p = Paper.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 40),
      children: [
        Row(
          children: [
            CircleBtn(
              icon: Icons.arrow_back_rounded,
              size: 42,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            const MiniPill('TRY-ON'),
          ],
        ),
        const SizedBox(height: 14),
        FadeSlideIn(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Try a new ', style: AppTypography.h1(context)),
                markerBoxSpan('look', AppTypography.h1(context)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        FadeSlideIn(
          delay: const Duration(milliseconds: 50),
          child: Text(
            'Add your photo and see each cut on your own face.',
            style: AppTypography.bodySmall(context),
          ),
        ),
        const SizedBox(height: 16),
        if (_phase == _Phase.analysing)
          _AnalysingCard(photo: _photo)
        else
          _AddPhotoCard(
            onTakePhoto: () => _capture(camera: true),
            onUpload: () => _capture(camera: false),
            onDemo: _useDemo,
          ),
        const SizedBox(height: 18),
        FadeSlideIn(
          delay: const Duration(milliseconds: 150),
          child: Row(
            children: [
              Icon(Icons.lock_outline_rounded, size: 14, color: p.textTertiary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Your photo stays on your device — nothing is uploaded.',
                  style: AppTypography.caption(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Try-on ----------------------------------------------------------

  Widget _buildTryOn(BuildContext context, Hairstyle selected, HairColor color) {
    final p = Paper.of(context);
    final analysis = _analysis!;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
      children: [
        Row(
          children: [
            CircleBtn(
              icon: Icons.arrow_back_rounded,
              size: 42,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            GestureDetector(
              onTap: _retake,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cameraswitch_rounded,
                      size: 18, color: AppColors.accentDeep),
                  const SizedBox(width: 5),
                  Text(L.newPhoto,
                      style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentDeep)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // The live preview.
        _TryOnHero(
          photo: _photo,
          silhouette: selected.silhouette,
          color: color,
          offset: _hairOffset,
          scale: _hairScale,
          faceLabel: '${analysis.shape.label} face',
          onPan: _onHairPan,
        ),
        const SizedBox(height: 12),
        // Fit controls: size + hair colour.
        Row(
          children: [
            Icon(Icons.height_rounded, size: 18, color: p.textSecondary),
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.accentDeep,
                  inactiveTrackColor: p.border,
                  thumbColor: AppColors.accentDeep,
                  overlayColor: AppColors.accent.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _hairScale,
                  min: 0.75,
                  max: 1.35,
                  onChanged: (v) => setState(() => _hairScale = v),
                ),
              ),
            ),
            Text(L.fitWord, style: AppTypography.caption(context)),
          ],
        ),
        const SizedBox(height: 4),
        _ColorRow(
          selected: _colorIndex,
          onSelect: (i) => setState(() => _colorIndex = i),
        ),
        const SizedBox(height: 18),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'We think ',
                style: AppTypography.body(context)
                    .copyWith(color: p.textSecondary),
              ),
              TextSpan(
                text: analysis.recommended.name,
                style: AppTypography.body(context)
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              TextSpan(
                text:
                    ' suits your ${analysis.shape.label.toLowerCase()} face — but try them all:',
                style: AppTypography.body(context)
                    .copyWith(color: p.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // The swipeable cut picker.
        _CutSelector(
          selectedId: _selectedId,
          recommendedId: analysis.recommended.id,
          color: color,
          onSelect: (id) => setState(() => _selectedId = id),
        ),
        const SizedBox(height: 18),
        // Details of the selected cut.
        _CutDetails(style: selected, shape: analysis.shape),
      ],
    );
  }
}

// ============================================================
// Intro states.
// ============================================================

class _AddPhotoCard extends StatelessWidget {
  const _AddPhotoCard({
    required this.onTakePhoto,
    required this.onUpload,
    required this.onDemo,
  });

  final VoidCallback onTakePhoto;
  final VoidCallback onUpload;
  final VoidCallback onDemo;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.accentDeep,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.face_retouching_natural_rounded,
                  size: 34, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(L.addYourPhoto, style: AppTypography.h3(context)),
            const SizedBox(height: 4),
            Text(
              'Face the camera, good light, hair off your forehead.',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(context),
            ),
            const SizedBox(height: 18),
            PrimaryButton(
              label: 'Take a selfie',
              icon: Icons.photo_camera_rounded,
              height: 54,
              onPressed: onTakePhoto,
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Upload a photo',
              icon: Icons.image_outlined,
              height: 54,
              style: PrimaryButtonStyle.ghost,
              onPressed: onUpload,
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onDemo,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  L.tryDemoFace,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentDeep,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accent,
                    decorationThickness: 2.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysingCard extends StatelessWidget {
  const _AnalysingCard({required this.photo});

  final Uint8List? photo;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      radius: 28,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 76,
              height: 92,
              child: photo == null
                  ? const CustomPaint(
                      painter: FacePlaceholderPainter(
                        skin: Color(0xFFE7C9A9),
                        bg: Color(0xFFDDE7F5),
                      ),
                    )
                  : Image.memory(photo!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFDDE7F5))),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.accentDeep),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(L.readingFace,
                          style: AppTypography.h4(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Finding the cut that frames you best.',
                  style: AppTypography.bodySmall(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// The live try-on hero.
// ============================================================

class _TryOnHero extends StatelessWidget {
  const _TryOnHero({
    required this.photo,
    required this.silhouette,
    required this.color,
    required this.offset,
    required this.scale,
    required this.faceLabel,
    required this.onPan,
  });

  final Uint8List? photo;
  final HairSilhouette silhouette;
  final HairColor color;
  final Offset offset;
  final double scale;
  final String faceLabel;
  final ValueChanged<Offset> onPan;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            // The hair box, nudged by the user.
            final boxW = w * 0.72 * scale;
            final boxH = h * 0.66 * scale;
            final left = (w - boxW) / 2 + offset.dx * w;
            final top = h * 0.02 + offset.dy * h;

            return GestureDetector(
              onPanUpdate: (d) =>
                  onPan(Offset(d.delta.dx / w, d.delta.dy / h)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo or placeholder face.
                  if (photo == null)
                    const CustomPaint(
                      painter: FacePlaceholderPainter(
                        skin: Color(0xFFE7C9A9),
                        bg: Color(0xFFDDE7F5),
                      ),
                    )
                  else
                    Image.memory(
                      photo!,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                      errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFFDDE7F5)),
                    ),
                  // The hair overlay.
                  Positioned(
                    left: left,
                    top: top,
                    width: boxW,
                    height: boxH,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: HairOverlayPainter(
                          silhouette: silhouette,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  // Face-shape chip.
                  Positioned(
                    left: 12,
                    top: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.ink.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.auto_awesome_rounded,
                              size: 12, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            faceLabel,
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
                  // Drag hint.
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.card.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.open_with_rounded,
                              size: 12, color: p.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            L.dragToFit,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: p.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================
// Hair colour picker.
// ============================================================

class _ColorRow extends StatelessWidget {
  const _ColorRow({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        Text(L.colourWord, style: AppTypography.caption(context)),
        const SizedBox(width: 12),
        for (var i = 0; i < HairColor.options.length; i++) ...[
          GestureDetector(
            onTap: () => onSelect(i),
            child: Container(
              width: 30,
              height: 30,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: HairColor.options[i].hair,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected == i ? AppColors.accentDeep : p.border,
                  width: selected == i ? 2.6 : 1,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================
// The swipeable cut selector — each chip previews the cut on a head.
// ============================================================

class _CutSelector extends StatelessWidget {
  const _CutSelector({
    required this.selectedId,
    required this.recommendedId,
    required this.color,
    required this.onSelect,
  });

  final String? selectedId;
  final String recommendedId;
  final HairColor color;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: HairData.styles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final style = HairData.styles[i];
          return _CutThumb(
            style: style,
            color: color,
            selected: selectedId == style.id,
            recommended: recommendedId == style.id,
            onTap: () => onSelect(style.id),
          );
        },
      ),
    );
  }
}

class _CutThumb extends StatelessWidget {
  const _CutThumb({
    required this.style,
    required this.color,
    required this.selected,
    required this.recommended,
    required this.onTap,
  });

  final Hairstyle style;
  final HairColor color;
  final bool selected;
  final bool recommended;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? AppColors.accentDeep : p.border,
                    width: selected ? 2.4 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Mini face + this cut.
                    const CustomPaint(
                      painter: FacePlaceholderPainter(
                        skin: Color(0xFFE7C9A9),
                        bg: Color(0xFFEAF0FA),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: CustomPaint(
                        painter: HairOverlayPainter(
                          silhouette: style.silhouette,
                          color: color,
                        ),
                      ),
                    ),
                    if (recommended)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.star_rounded,
                              size: 12, color: AppColors.ink),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              style.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? p.text : p.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// Selected-cut detail card.
// ============================================================

class _CutDetails extends StatelessWidget {
  const _CutDetails({required this.style, required this.shape});

  final Hairstyle style;
  final FaceShape shape;

  @override
  Widget build(BuildContext context) {
    final fits = style.suits.contains(shape);
    return PaperCard(
      radius: 24,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(style.name, style: AppTypography.h3(context))),
              MiniPill(
                fits ? 'GREAT FIT' : 'WORTH A TRY',
                style: fits ? MiniPillStyle.accent : MiniPillStyle.ghost,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(style.description, style: AppTypography.bodySmall(context)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              MiniPill(style.lengthLabel, style: MiniPillStyle.ghost),
              MiniPill(style.upkeep, style: MiniPillStyle.ghost),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// Sticky "Book this look" bar.
// ============================================================

class _BookBar extends StatelessWidget {
  const _BookBar({required this.style, required this.onBook});

  final Hairstyle style;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.yourLook, style: AppTypography.caption(context)),
                  const SizedBox(height: 1),
                  Text(
                    style.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h4(context),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            PrimaryButton(
              label: L.bookThisLook,
              expanded: false,
              height: 54,
              onPressed: onBook,
            ),
          ],
        ),
      ),
    );
  }
}
