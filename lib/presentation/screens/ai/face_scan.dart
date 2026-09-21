import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/demo_faces.dart';
import '../style/hair_overlay.dart';

/// Full-screen "AI reading your face" animation: the photo with a sweeping
/// scan line, a face mesh that lights up, and cycling status text. Calls
/// [onDone] when the scan finishes (~2.6s).
class FaceScanView extends StatefulWidget {
  const FaceScanView({super.key, required this.photo, required this.onDone});

  final Uint8List? photo;
  final VoidCallback onDone;

  @override
  State<FaceScanView> createState() => _FaceScanViewState();
}

class _FaceScanViewState extends State<FaceScanView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  List<String> get _steps => [
        L.stFaceStatus1,
        L.stFaceStatus2,
        L.stFaceStatus3,
        L.stFaceStatus4,
      ];

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onDone();
    });
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 16, color: AppColors.accent),
              const SizedBox(width: 6),
              Text(L.stAiAnalysing,
                  style: AppTypography.h4(context)
                      .copyWith(color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: AspectRatio(
                  aspectRatio: 3 / 4,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Scanning a real face, not a cartoon one: this screen
                      // claims to be measuring facial proportions, and a drawn
                      // oval makes that claim obviously theatre.
                      if (widget.photo == null)
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
                        Image.memory(widget.photo!,
                            fit: BoxFit.cover, gaplessPlayback: true),
                      AnimatedBuilder(
                        animation: _c,
                        builder: (_, __) =>
                            CustomPaint(painter: _ScanPainter(_c.value)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Status text + progress bar.
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final i = (_c.value * _steps.length)
                  .floor()
                  .clamp(0, _steps.length - 1);
              return Column(
                children: [
                  Text(_steps[i],
                      style: AppTypography.bodyLarge(context)
                          .copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: _c.value,
                      minHeight: 6,
                      backgroundColor: p.cardAlt,
                      valueColor:
                          const AlwaysStoppedAnimation(AppColors.accent),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  _ScanPainter(this.t);
  final double t; // 0..1

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final cyFace = h * 0.42;

    // Dim veil that lifts as the scan completes.
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.navy.withValues(alpha: 0.28 * (1 - t)),
    );

    // Corner brackets framing the face.
    final bracket = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const m = 24.0, len = 34.0;
    void corner(double x, double y, int sx, int sy) {
      canvas.drawLine(Offset(x, y), Offset(x + len * sx, y), bracket);
      canvas.drawLine(Offset(x, y), Offset(x, y + len * sy), bracket);
    }

    corner(m, m, 1, 1);
    corner(w - m, m, -1, 1);
    corner(m, h - m, 1, -1);
    corner(w - m, h - m, -1, -1);

    // Face oval guide.
    final ovalRect = Rect.fromCenter(
        center: Offset(cx, cyFace), width: w * 0.56, height: h * 0.5);
    canvas.drawOval(
      ovalRect,
      Paint()
        ..color = AppColors.accent.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Mesh points lighting up across the face.
    final rnd = math.Random(7);
    final dot = Paint()..color = AppColors.accent;
    const total = 46;
    final shown = (total * (t * 1.4).clamp(0.0, 1.0)).floor();
    for (var i = 0; i < shown; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final r = rnd.nextDouble();
      final px = cx + math.cos(a) * (w * 0.27) * r;
      final py = cyFace + math.sin(a) * (h * 0.24) * r;
      canvas.drawCircle(Offset(px, py), 1.8, dot);
    }

    // Sweeping scan line (bounces).
    final tri = t < 0.5 ? t * 2 : 2 - t * 2;
    final y = h * 0.12 + tri * h * 0.72;
    final glow = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: 0),
          AppColors.accent.withValues(alpha: 0.35),
          AppColors.accent.withValues(alpha: 0),
        ],
      ).createShader(Rect.fromLTWH(0, y - 24, w, 48));
    canvas.drawRect(Rect.fromLTWH(0, y - 24, w, 48), glow);
    canvas.drawLine(
      Offset(0, y),
      Offset(w, y),
      Paint()
        ..color = AppColors.accent
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_ScanPainter old) => old.t != t;
}
