import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';

/// A bold, immersive launch intro (Booksy-premium): the whole screen is the
/// brand colour — a deep navy stage. A crisp white logo badge reveals with a
/// soft glow + a metallic glint, the wordmark and accent line settle in clean,
/// then the navy stage OPENS in a circular reveal into the app underneath.
class ScissorsCutIntro extends StatefulWidget {
  const ScissorsCutIntro({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<ScissorsCutIntro> createState() => _ScissorsCutIntroState();
}

class _ScissorsCutIntroState extends State<ScissorsCutIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  bool _done = false;

  // Brand stage colours.
  static const _navy = Color(0xFF13233F);
  static const _navyDeep = Color(0xFF0C1729);

  // Refined easings — no bounce/elastic.
  static const _expo = Cubic(0.16, 1, 0.3, 1);
  static const _quart = Cubic(0.25, 1, 0.5, 1);
  static const _inOut = Cubic(0.65, 0, 0.35, 1);

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed && !_done) {
        _done = true;
        widget.onDone();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      _c.forward(from: reduce ? 0.86 : 0.0);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _seg(double t, double a, double b) =>
      ((t - a) / (b - a)).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final glow = _seg(t, 0.04, 0.52);
        final badge = _expo.transform(_seg(t, 0.06, 0.44));
        final ping = _seg(t, 0.16, 0.58);
        final shimmer = _seg(t, 0.34, 0.62);
        final word = _quart.transform(_seg(t, 0.40, 0.72));
        final line = _quart.transform(_seg(t, 0.54, 0.82));
        final tag = _seg(t, 0.66, 0.88);
        // Exit: the navy stage opens into the app with a circular reveal.
        final exit = _inOut.transform(_seg(t, 0.80, 1.0));

        // Energy glow swells then settles (triangle peak in the middle).
        final glowOpacity = (1 - (2 * glow - 1).abs()) * 0.55;
        // Badge tilts upright as it scales in.
        final rot = (1 - badge) * -0.10;

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.22),
              radius: 1.1,
              colors: [_navy, _navyDeep],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The whole lockup — nudges up + fades a touch as the app opens.
              Opacity(
                opacity: (1 - exit * 0.6).clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -26 * exit),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 220,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Soft energy glow behind the badge.
                              Opacity(
                                opacity: glowOpacity.clamp(0.0, 1.0),
                                child: Transform.scale(
                                  scale: 0.4 + 1.05 * glow,
                                  child: Container(
                                    width: 230,
                                    height: 230,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          AppColors.accent
                                              .withValues(alpha: 0.55),
                                          AppColors.accent.withValues(alpha: 0),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Single clean ping ring.
                              Opacity(
                                opacity: (0.5 * (1 - ping)).clamp(0.0, 1.0),
                                child: Container(
                                  width: 112 + 84 * ping,
                                  height: 112 + 84 * ping,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.7),
                                        width: 2),
                                  ),
                                ),
                              ),
                              // The badge — crisp white tile, blue scissors,
                              // tilt + scale in, with a glint sweeping across.
                              Opacity(
                                opacity: badge,
                                child: Transform.rotate(
                                  angle: rot,
                                  child: Transform.scale(
                                    scale: 0.58 + 0.42 * badge,
                                    child: Container(
                                      width: 112,
                                      height: 112,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(32),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.accent
                                                .withValues(alpha: 0.45),
                                            blurRadius: 44,
                                            offset: const Offset(0, 18),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(32),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            const Center(
                                              child: Icon(
                                                Icons.content_cut_rounded,
                                                size: 54,
                                                color: AppColors.accent,
                                              ),
                                            ),
                                            // Metallic glint sweeping across.
                                            DecoratedBox(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment(
                                                      -1.6 + 3.0 * shimmer,
                                                      -0.9),
                                                  end: Alignment(
                                                      -0.7 + 3.0 * shimmer, 0.9),
                                                  colors: [
                                                    Colors.white
                                                        .withValues(alpha: 0),
                                                    Colors.white
                                                        .withValues(alpha: 0.7),
                                                    Colors.white
                                                        .withValues(alpha: 0),
                                                  ],
                                                  stops: const [0.40, 0.5, 0.60],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Wordmark — clean fade + rise (white on navy).
                        Opacity(
                          opacity: word.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1 - word)),
                            child: Text(
                              'FADE',
                              style: GoogleFonts.nunito(
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Accent line draws across.
                        Container(
                          width: 140 * line,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: tag.clamp(0.0, 1.0),
                          child: Text(
                            L.pfBookYourBarber,
                            style: GoogleFonts.nunito(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6,
                              color: Colors.white.withValues(alpha: 0.62),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // The circular reveal — the app colour opens from the logo and
              // grows to fill the screen, so the splash "opens into" the app.
              if (exit > 0)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _RevealPainter(exit, const Color(0xFFFFFFFF)),
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

/// Paints an expanding circle of [color] from a point just above centre,
/// growing to cover the whole screen as [progress] goes 0 → 1.
class _RevealPainter extends CustomPainter {
  _RevealPainter(this.progress, this.color);
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = Offset(size.width / 2, size.height * 0.42);
    final maxR = math.sqrt(
      math.pow(math.max(center.dx, size.width - center.dx), 2) +
          math.pow(math.max(center.dy, size.height - center.dy), 2),
    );
    canvas.drawCircle(
        center, progress * maxR * 1.03, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RevealPainter old) =>
      old.progress != progress || old.color != color;
}
