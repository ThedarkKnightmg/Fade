import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../legal/consent_screen.dart';
import 'role_choice_screen.dart';

/// The first thing anyone sees. One page, one message, one button — carried by
/// a single signature animation rather than scattered effects.
///
/// The hero moment is literal: the scissors snip, and hair clippings fall away
/// from the blades and drift down the screen. It is the app's actual subject
/// rendered as motion, which is what makes it memorable instead of decorative.
///
/// Everything loops on transform/opacity only (GPU-cheap), the clippings are a
/// single CustomPainter rather than N widgets, and every continuous animation
/// freezes when the platform asks for reduced motion.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  /// One controller drives the whole ambient layer (clippings + drift), so the
  /// scene costs a single ticker no matter how many particles are on screen.
  late final AnimationController _amb = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void initState() {
    super.initState();
    // Started in didChangeDependencies once we can read the reduced-motion flag.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _amb.value = 0.35; // a still, composed frame
    } else if (!_amb.isAnimating) {
      _amb.repeat();
    }
  }

  @override
  void dispose() {
    _amb.dispose();
    super.dispose();
  }

  /// Onboarding sells the app; the legal consent gate comes next (once), then
  /// the role choice. Consent is asked BEFORE any account exists or any
  /// personal data is collected — and only while it's still outstanding.
  void _finish(BuildContext context) {
    Navigator.of(context).pushReplacement(
      FadeThroughPageRoute(
        child: AppState.instance.needsLegalConsent
            ? const ConsentScreen(next: RoleChoiceScreen())
            : const RoleChoiceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final reduced = MediaQuery.of(context).disableAnimations;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          // Ambient: falling hair clippings across the whole canvas, behind the
          // content. Painted once per frame from one controller.
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _amb,
                  builder: (context, _) => CustomPaint(
                    painter: _ClippingsPainter(
                      t: _amb.value,
                      color: p.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FadeSlideIn(child: BarberLogo(size: 34)),
                  const Spacer(flex: 2),
                  Center(
                    child: ScaleIn(
                      delay: const Duration(milliseconds: 120),
                      duration: const Duration(milliseconds: 640),
                      from: 0.6,
                      child: _OnboardingHero(reduced: reduced),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Headline reveals word by word, so the promise lands as a
                  // sentence being spoken rather than a block appearing.
                  _StaggeredHeadline(reduced: reduced),
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 620),
                    child: Text(
                      L.onboardingSub,
                      style: AppTypography.bodySmall(context),
                    ),
                  ),
                  const Spacer(flex: 3),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 720),
                    child: PrimaryButton(
                      label: L.getStarted,
                      height: 62,
                      onPressed: () => _finish(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The headline, revealed one word at a time on a short cascade. Uses the same
/// marker-box treatment as before for the emphasised tail ("in seconds").
class _StaggeredHeadline extends StatelessWidget {
  const _StaggeredHeadline({required this.reduced});

  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.display(context);
    final words = L.bookYourBarberLine.trim().split(' ');
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (i, w) in words.indexed)
          FadeSlideIn(
            // 70ms apart: fast enough to feel like one gesture, slow enough to
            // read as a cascade.
            delay: Duration(milliseconds: reduced ? 0 : 220 + i * 70),
            offset: const Offset(0, 0.35),
            child: Text('$w ', style: style),
          ),
        FadeSlideIn(
          delay: Duration(
              milliseconds: reduced ? 0 : 220 + words.length * 70),
          offset: const Offset(0, 0.35),
          child: Text.rich(
            TextSpan(children: [markerBoxSpan(L.inSeconds, style)]),
          ),
        ),
      ],
    );
  }
}

/// The welcome hero: a gradient scissor mark that floats and tilts inside two
/// breathing aura rings, with the blades doing a periodic snip.
class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({required this.reduced});

  final bool reduced;

  Widget _aura(double size, double alpha, double scale) => Transform.scale(
        scale: scale,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accent.withValues(alpha: alpha),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer + inner aura rings, half a cycle out of phase so they pulse
          // in a gentle ripple rather than in lockstep.
          Breathe(
            period: const Duration(milliseconds: 3600),
            builder: (context, t) {
              final phase = (math.sin(t * 2 * math.pi) + 1) / 2;
              return _aura(150, 0.05 + 0.06 * (1 - phase), 0.9 + 0.32 * phase);
            },
          ),
          Breathe(
            period: const Duration(milliseconds: 3600),
            builder: (context, t) {
              final phase = (math.sin((t + 0.5) * 2 * math.pi) + 1) / 2;
              return _aura(126, 0.05 + 0.06 * (1 - phase), 0.9 + 0.26 * phase);
            },
          ),
          // The floating, tilting mark.
          Breathe(
            period: const Duration(milliseconds: 4000),
            builder: (context, t) {
              final osc = math.sin(t * 2 * math.pi);
              return Transform.translate(
                offset: Offset(0, osc * 7),
                child: Transform.rotate(angle: osc * 0.05, child: _tile()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _tile() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4AA3FF), AppColors.accentDeep],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.42),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      // The snip: blades squeeze closed briefly at the top of each cycle, with
      // a tiny counter-rotation so it reads as a cut, not just a pulse.
      child: Breathe(
        period: const Duration(milliseconds: 2000),
        builder: (context, t) {
          final snip = t < 0.16 ? math.sin(t / 0.16 * math.pi) : 0.0;
          return Transform.rotate(
            angle: -0.12 * snip,
            child: Transform.scale(
              scale: 1 - 0.10 * snip,
              child: const Icon(Icons.content_cut_rounded,
                  size: 42, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}

/// Falling hair clippings — the ambient layer that makes the screen feel like a
/// barber's chair rather than a form. Each clipping's position is a pure
/// function of (index, t), so there is no per-particle state to update: the
/// painter just draws where each one *would* be at time t.
class _ClippingsPainter extends CustomPainter {
  _ClippingsPainter({required this.t, required this.color});

  final double t;
  final Color color;

  static const int _count = 18;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < _count; i++) {
      // Deterministic per-clipping constants — a cheap hash of the index keeps
      // them scattered without a Random() and without storing anything.
      final seed = (i * 9301 + 49297) % 233280 / 233280.0;
      final seed2 = (i * 4703 + 7919) % 104729 / 104729.0;

      // Staggered fall: each clipping runs its own loop, offset by its seed.
      final phase = (t + seed) % 1.0;

      // Fall from just above the hero down past the bottom edge.
      final y = -30 + phase * (size.height + 60);
      // Sideways sway, so they drift like real hair instead of dropping.
      final sway = math.sin(phase * 2 * math.pi + seed2 * 6.28) * 26;
      final x = seed * size.width + sway;

      // Fade in at the top, out at the bottom — never pop in or out.
      final fade = phase < 0.12
          ? phase / 0.12
          : phase > 0.82
              ? (1 - phase) / 0.18
              : 1.0;
      // Kept faint: this is atmosphere, and it sits behind live text.
      paint.color = color.withValues(alpha: 0.16 * fade.clamp(0.0, 1.0));
      paint.strokeWidth = 1.4 + seed2 * 1.1;

      // A short curved stroke — a clipping, not a line.
      final len = 9 + seed2 * 9;
      final angle = phase * 4 + seed * 6.28; // tumbles as it falls
      final dx = math.cos(angle) * len / 2;
      final dy = math.sin(angle) * len / 2;
      final path = Path()
        ..moveTo(x - dx, y - dy)
        ..quadraticBezierTo(x, y, x + dx, y + dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_ClippingsPainter old) =>
      old.t != t || old.color != color;
}
