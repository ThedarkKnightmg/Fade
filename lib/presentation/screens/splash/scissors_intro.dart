import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';

/// A cinematic launch intro — a proper Star-Wars hyperspace jump:
///
///  1. Deep space. A scattered starfield twinkles, holding still (the pause
///     before the jump).
///  2. PUNCH — every star stretches into a long radial light-speed streak.
///     Near stars whip past long/bright/thick, far ones stay short and dim
///     (parallax); everything blue-shifts as speed builds, a tunnel bloom
///     swells at the vanishing point and the camera rumbles.
///  3. Arrival flash — a white/blue punch as we drop out of light-speed…
///  4. …and the Fade badge bursts out of it: glow + glint, the FADE wordmark,
///     accent line and tagline settle in, then a circular reveal OPENS into
///     the app underneath.
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
    duration: const Duration(milliseconds: 5600),
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
    return List.generate(420, (i) {
      return _Star(
        angle: rnd.nextDouble() * math.pi * 2,
        // Area-uniform spread across the whole sky, so the hold phase reads
        // as a real starfield (not a cluster at the vanishing point).
        r0: math.sqrt(rnd.nextDouble()) * 0.95,
        speed: 0.6 + rnd.nextDouble() * 1.1,
        depth: rnd.nextDouble(), // 0 = far … 1 = near (parallax layer)
        bright: 0.35 + rnd.nextDouble() * 0.65,
        blue: rnd.nextDouble() < 0.30, // some Fade-blue stars
        tw: rnd.nextDouble() * math.pi * 2,
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
      _c.forward(from: reduce ? 0.62 : 0.0);
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
        final warp = _seg(t, 0.0, 0.46); // 0→1 across the jump
        // How hard the drive is pushing (0 during the starfield hold, ramps
        // to 1 at full light-speed) — drives the rumble + camera zoom.
        final drive = math.pow(_seg(warp, 0.20, 1.0), 1.5).toDouble();
        // The deep-space blackout covers the navy stage during the jump, then
        // dissolves to reveal the brand stage as we drop out of light-speed.
        final space = 1 - _seg(t, 0.46, 0.64);
        // Arrival flash — punch of white/blue as we exit the jump.
        final flash = _seg(t, 0.42, 0.52);
        final flashOut = _seg(t, 0.48, 0.62);
        final flashOp = (flash * (1 - flashOut)).clamp(0.0, 1.0);
        // Camera rumble while the drive spools up; dies with the flash.
        final rumble = 3.0 * drive * (1 - flashOut);
        final rx = rumble * math.sin(t * 230);
        final ry = rumble * math.cos(t * 181);

        // ── Brand reveal (plays AFTER the jump) ───────────────────────────
        final glow = _seg(t, 0.48, 0.74);
        final badge = _expo.transform(_seg(t, 0.48, 0.66));
        final shimmer = _seg(t, 0.60, 0.76);
        final word = _quart.transform(_seg(t, 0.68, 0.82));
        final line = _quart.transform(_seg(t, 0.75, 0.88));
        final tag = _seg(t, 0.82, 0.93);
        // Exit: the app colour opens from the logo in a circular reveal.
        final exit = _inOut.transform(_seg(t, 0.90, 1.0));

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
              // The hyperspace starfield → streaks, with rumble + a slight
              // camera pull-in as the drive engages.
              if (warp > 0 && space > 0.02)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Transform.translate(
                      offset: Offset(rx, ry),
                      child: Transform.scale(
                        scale: 1 + 0.07 * drive,
                        child: CustomPaint(
                          painter:
                              _HyperspacePainter(warp: warp, stars: _stars),
                        ),
                      ),
                    ),
                  ),
                ),
              // Arrival flash — a clean full-screen white punch (no radial
              // shape, so nothing reads as a circle).
              if (flashOp > 0.001)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: flashOp,
                      child: const ColoredBox(color: Colors.white),
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

/// One star in the hyperspace field.
class _Star {
  const _Star({
    required this.angle,
    required this.r0,
    required this.speed,
    required this.depth,
    required this.bright,
    required this.blue,
    required this.tw,
  });

  final double angle;
  final double r0; // starting radius, fraction of maxR
  final double speed;
  final double depth; // 0 far … 1 near — parallax layer
  final double bright;
  final bool blue;
  final double tw; // twinkle phase
}

/// Paints the jump: stars hold as twinkling dots (~first 20% of the warp),
/// then every one of them stretches into a radial light-speed streak. Near
/// stars (depth→1) streak longer/brighter/thicker; a tunnel bloom builds at
/// the vanishing point; streaks blue-shift with speed, get a white-hot leading
/// tip, and wrap around so fresh streaks keep pouring out of the tunnel — a
/// sustained jump, not a single burst. The field fades in fast and washes out
/// into the arrival flash.
class _HyperspacePainter extends CustomPainter {
  _HyperspacePainter({required this.warp, required this.stars});
  final double warp; // 0 → 1 across the jump
  final List<_Star> stars;

  static const _blue = Color(0xFF8CC6FF);

  @override
  void paint(Canvas canvas, Size size) {
    if (warp <= 0) return;
    final cx = size.width / 2, cy = size.height * 0.44;
    final maxR = math.sqrt(cx * cx +
            math.max(cy, size.height - cy) * math.max(cy, size.height - cy)) *
        1.06;

    // Hold as dots first, then launch (ease-in, so it LEAPS to speed).
    const launch = 0.20;
    final driveT = ((warp - launch) / (1 - launch)).clamp(0.0, 1.0);
    final accel = math.pow(driveT, 2.1).toDouble();
    final streakF = math.pow(driveT, 1.5).toDouble();

    // Field fades in quickly, then washes out into the flash near the end.
    final fadeIn = (warp / 0.08).clamp(0.0, 1.0);
    final fadeOut =
        warp > 0.88 ? (1 - (warp - 0.88) / 0.12).clamp(0.0, 1.0) : 1.0;
    final field = fadeIn * fadeOut;
    if (field <= 0) return;

    // No tunnel-bloom disc — it read as a big circle behind the streaks.
    // The jump is pure star-lines on deep space.
    final isHold = driveT <= 0.001;
    // Final lunge — right before the flash, every streak stretches extra long
    // while the field washes out (the classic last surge into light-speed).
    final lunge = 1 + 2.4 * ((warp - 0.86) / 0.14).clamp(0.0, 1.0);

    for (final s in stars) {
      final sp = s.speed * (0.5 + 0.9 * s.depth);
      // Wrap so streaks keep flowing out of the tunnel (sustained travel).
      final total = s.r0 + accel * sp * 2.4;
      final wrapped = total >= 1.3; // re-entered at the tunnel mouth
      final lead = (total % 1.3) * maxR;
      final frac = (lead / maxR).clamp(0.0, 1.0);
      final streak = (streakF * sp * (0.28 + 0.62 * s.depth) * maxR * lunge)
          .clamp(0.0, lead * 0.92);
      final dx = math.cos(s.angle), dy = math.sin(s.angle);
      final p2 = Offset(cx + dx * lead, cy + dy * lead);

      // Blue-shift as speed builds. Perspective: deep in the tunnel = dim +
      // hairline-thin; whipping past the edges = bright + bold.
      final shifted = Color.lerp(Colors.white, _blue, 0.30 * driveT)!;
      final base = s.blue ? _blue : shifted;
      final centerDim = (0.30 + 0.70 * frac).clamp(0.0, 1.0);
      var op = (s.bright * field * centerDim).clamp(0.0, 1.0);
      final w = (0.9 + s.bright * 1.5) *
          (0.6 + 0.55 * s.depth) *
          (0.4 + 0.9 * frac);

      if (isHold) {
        // The pause before the jump — a calm starfield, gently twinkling.
        // This is the ONLY place dots are drawn.
        final twinkle = 0.72 + 0.28 * math.sin(warp * 90 + s.tw);
        canvas.drawCircle(p2, 0.9 + s.bright * 1.2,
            Paint()..color = base.withValues(alpha: op * twinkle));
        continue;
      }

      if (wrapped) {
        // A recycled streak pouring back out of the tunnel mouth: fade it in
        // smoothly as it emerges and NEVER draw stubs — the centre shows
        // moving lines only, no flickering dots.
        final emerge = ((frac - 0.05) / 0.12).clamp(0.0, 1.0);
        if (emerge <= 0 || streak < 6) continue;
        op = (op * emerge).clamp(0.0, 1.0);
      } else if (streak < 1.5) {
        // Original star still spooling up — keep it as a steady point so the
        // launch is seamless (only exists in the first beats of the jump).
        canvas.drawCircle(p2, 0.9 + s.bright * 1.2,
            Paint()..color = base.withValues(alpha: op));
        continue;
      }

      final p1 = Offset(cx + dx * (lead - streak), cy + dy * (lead - streak));
      // Comet streak: transparent tail → body → hot head, all inside a single
      // stroke — no separate tip circles (those read as stray dots). Near
      // (deep) streaks burn whiter at the head.
      final head = Color.lerp(base, Colors.white, s.depth > 0.8 ? 0.75 : 0.55)!;
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeCap = StrokeCap.round
          ..strokeWidth = w
          ..shader = ui.Gradient.linear(p1, p2, [
            base.withValues(alpha: 0),
            base.withValues(alpha: op),
            head.withValues(alpha: op),
          ], const [
            0.0,
            0.72,
            1.0,
          ]),
      );
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
