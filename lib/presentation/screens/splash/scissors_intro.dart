import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';

/// A cinematic launch intro. It opens in DEEP SPACE and jumps to light-speed —
/// stars streak into long radial lines (a Star-Wars hyperspace jump) — then
/// punches through a bright arrival flash out of which the Fade badge bursts,
/// flowing into the brand reveal (wordmark + accent line + tagline) and finally
/// a circular reveal that OPENS into the app underneath.
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
    duration: const Duration(milliseconds: 3800),
  );
  bool _done = false;

  // The starfield for the hyperspace jump — generated once (seeded so it's
  // stable across rebuilds).
  final List<_Star> _stars = _makeStars();

  // Brand stage colours.
  static const _navy = Color(0xFF13233F);
  static const _navyDeep = Color(0xFF0C1729);
  static const _space = Color(0xFF03060E); // near-black deep space

  // Refined easings — no bounce/elastic.
  static const _expo = Cubic(0.16, 1, 0.3, 1);
  static const _quart = Cubic(0.25, 1, 0.5, 1);
  static const _inOut = Cubic(0.65, 0, 0.35, 1);

  static List<_Star> _makeStars() {
    final rnd = math.Random(7);
    return List.generate(200, (i) {
      return _Star(
        angle: rnd.nextDouble() * math.pi * 2,
        r0: rnd.nextDouble() * 0.14, // start clustered near the vanishing point
        speed: 0.75 + rnd.nextDouble() * 0.95, // 0.75 – 1.70
        bright: 0.45 + rnd.nextDouble() * 0.55,
        blue: rnd.nextDouble() < 0.28, // a few Fade-blue stars
      );
    });
  }

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
      // Reduced motion: skip the hyperspace jump + flash, straight to the brand.
      _c.forward(from: reduce ? 0.60 : 0.0);
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

        // ── Hyperspace jump ──────────────────────────────────────────────
        final warp = _seg(t, 0.0, 0.44); // 0→1 across the jump
        // The deep-space blackout covers the navy stage during the jump, then
        // dissolves to reveal the brand stage as we "drop out" of light-speed.
        final space = 1 - _seg(t, 0.44, 0.62);
        // Arrival flash — punch of white/blue as we exit the jump.
        final flash = _seg(t, 0.40, 0.50);
        final flashOut = _seg(t, 0.46, 0.60);
        final flashOp = (flash * (1 - flashOut)).clamp(0.0, 1.0);

        // ── Brand reveal (remapped to play AFTER the jump) ────────────────
        final glow = _seg(t, 0.46, 0.72);
        final badge = _expo.transform(_seg(t, 0.46, 0.64));
        final ping = _seg(t, 0.50, 0.74);
        final shimmer = _seg(t, 0.58, 0.74);
        final word = _quart.transform(_seg(t, 0.66, 0.80));
        final line = _quart.transform(_seg(t, 0.72, 0.86));
        final tag = _seg(t, 0.80, 0.92);
        // Exit: the app colour opens from the logo in a circular reveal.
        final exit = _inOut.transform(_seg(t, 0.88, 1.0));

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
              // Deep-space blackout (fades to reveal the navy stage).
              if (space > 0.001)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: space.clamp(0.0, 1.0),
                      child: const ColoredBox(color: _space),
                    ),
                  ),
                ),
              // The hyperspace streaks.
              if (warp > 0 && space > 0.02)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _HyperspacePainter(warp: warp, stars: _stars),
                    ),
                  ),
                ),
              // Arrival flash.
              if (flashOp > 0.001)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: flashOp,
                      child: const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0, -0.10),
                            radius: 1.0,
                            colors: [
                              Colors.white,
                              Color(0x8C2E8BFF),
                              Color(0x002E8BFF),
                            ],
                            stops: [0.0, 0.35, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // The whole lockup — nudges up + fades a touch as the app opens.
              // (Everything inside is opacity-0 during the jump, so it only
              // appears once the badge starts to emerge.)
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

/// One star in the hyperspace field: a fixed [angle] from the vanishing point,
/// a small starting radius, and a per-star [speed] so they don't all streak in
/// lockstep. [blue] tints a few of them Fade-blue.
class _Star {
  const _Star({
    required this.angle,
    required this.r0,
    required this.speed,
    required this.bright,
    required this.blue,
  });
  final double angle;
  final double r0;
  final double speed;
  final double bright;
  final bool blue;
}

/// Paints the jump-to-light-speed streaks: each star accelerates OUT from the
/// centre (ease-in, so it leaps to speed) and stretches from a dot into a long
/// radial line with a comet-tail fade. The whole field fades in at the start
/// and washes out into the arrival flash at the end.
class _HyperspacePainter extends CustomPainter {
  _HyperspacePainter({required this.warp, required this.stars});
  final double warp; // 0 → 1 across the jump
  final List<_Star> stars;

  @override
  void paint(Canvas canvas, Size size) {
    if (warp <= 0) return;
    final cx = size.width / 2, cy = size.height / 2;
    final maxR = math.sqrt(cx * cx + cy * cy) * 1.15;

    // Accelerate to light-speed (ease-in); streaks grow from dots to lines.
    final accel = math.pow(warp, 2.3).toDouble();
    final streakF = math.pow(warp, 1.7).toDouble();
    // Fade the field in quickly, then out into the flash near the end.
    final fadeIn = (warp / 0.12).clamp(0.0, 1.0);
    final fadeOut = warp > 0.86 ? (1 - (warp - 0.86) / 0.14).clamp(0.0, 1.0) : 1.0;
    final field = fadeIn * fadeOut;
    if (field <= 0) return;

    for (final s in stars) {
      final lead = (s.r0 + accel * s.speed) * maxR;
      if (lead > maxR * 1.28) continue; // already shot off-screen
      final streak = (streakF * s.speed * 0.55 * maxR).clamp(0.0, lead);
      final dx = math.cos(s.angle), dy = math.sin(s.angle);
      final p1 = Offset(cx + dx * (lead - streak), cy + dy * (lead - streak));
      final p2 = Offset(cx + dx * lead, cy + dy * lead);
      final base = s.blue ? const Color(0xFF8CC6FF) : Colors.white;
      final op = (s.bright * field).clamp(0.0, 1.0);
      final paint = Paint()
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 1.1 + s.bright * 1.7
        ..shader = ui.Gradient.linear(p1, p2, [
          base.withValues(alpha: 0),
          base.withValues(alpha: op),
        ]);
      canvas.drawLine(p1, p2, paint);
    }
  }

  @override
  bool shouldRepaint(_HyperspacePainter old) =>
      old.warp != warp || old.stars != stars;
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
