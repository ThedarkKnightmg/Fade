import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';

/// A premium, orchestrated launch intro (Yandex-Go-slick): an energy glow
/// bursts, the Fade scissors badge tilts + scales in with a metallic glint
/// sweeping across it, the wordmark wipes in left-to-right under a drawing
/// accent line, then the whole lockup confidently zooms away into the app.
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
    duration: const Duration(milliseconds: 2300),
  );
  bool _done = false;

  // Refined easings — no bounce/elastic.
  static const _expo = Cubic(0.16, 1, 0.3, 1);
  static const _quart = Cubic(0.25, 1, 0.5, 1);

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
        final glow = _seg(t, 0.08, 0.58);
        final badge = _expo.transform(_seg(t, 0.10, 0.54));
        final ping = _seg(t, 0.22, 0.68);
        final shimmer = _seg(t, 0.40, 0.66);
        final word = _quart.transform(_seg(t, 0.48, 0.80));
        final line = _quart.transform(_seg(t, 0.60, 0.88));
        final tag = _seg(t, 0.70, 0.92);
        final outT = _quart.transform(_seg(t, 0.88, 1.0));

        // Energy glow swells then settles (triangle peak in the middle).
        final glowOpacity = (1 - (2 * glow - 1).abs()) * 0.5;
        // Badge tilts upright as it scales in.
        final rot = (1 - badge) * -0.12;

        return Opacity(
          opacity: (1 - outT).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 1 + 0.08 * outT, // confident zoom-into-app on exit
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.16),
                  radius: 1.0,
                  colors: [Color(0xFFFFFFFF), Color(0xFFE7EFFB)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 200,
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Energy glow burst behind the badge.
                          Opacity(
                            opacity: glowOpacity.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.4 + 1.0 * glow,
                              child: Container(
                                width: 210,
                                height: 210,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      AppColors.accent.withValues(alpha: 0.35),
                                      AppColors.accent.withValues(alpha: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Single clean ping ring.
                          Opacity(
                            opacity: (0.4 * (1 - ping)).clamp(0.0, 1.0),
                            child: Container(
                              width: 104 + 78 * ping,
                              height: 104 + 78 * ping,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: AppColors.accent, width: 2),
                              ),
                            ),
                          ),
                          // The badge — tilt + scale in, with a glint sweep.
                          Opacity(
                            opacity: badge,
                            child: Transform.rotate(
                              angle: rot,
                              child: Transform.scale(
                                scale: 0.55 + 0.45 * badge,
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16294B),
                                    borderRadius: BorderRadius.circular(30),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.accent
                                            .withValues(alpha: 0.34),
                                        blurRadius: 36,
                                        offset: const Offset(0, 16),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        const Center(
                                          child: Icon(
                                            Icons.content_cut_rounded,
                                            size: 50,
                                            color: Color(0xFF2E8BFF),
                                          ),
                                        ),
                                        // Metallic glint sweeping across.
                                        DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment(
                                                  -1.6 + 3.0 * shimmer, -0.9),
                                              end: Alignment(
                                                  -0.7 + 3.0 * shimmer, 0.9),
                                              colors: [
                                                Colors.white.withValues(alpha: 0),
                                                Colors.white
                                                    .withValues(alpha: 0.55),
                                                Colors.white.withValues(alpha: 0),
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
                    const SizedBox(height: 22),
                    // Wordmark wipes in left-to-right.
                    ClipRect(
                      clipper: _WipeClipper(word),
                      child: Opacity(
                        opacity: (word * 1.6).clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 10 * (1 - word)),
                          child: Text(
                            'FADE',
                            style: GoogleFonts.nunito(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 7 - 3 * word,
                              color: const Color(0xFF0B1422),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Accent line draws across.
                    Container(
                      width: 132 * line,
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
                          letterSpacing: 0.5,
                          color: const Color(0xFF0B1422).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Reveals its child from the left edge to [fraction] of its width.
class _WipeClipper extends CustomClipper<Rect> {
  _WipeClipper(this.fraction);
  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_WipeClipper old) => old.fraction != fraction;
}
