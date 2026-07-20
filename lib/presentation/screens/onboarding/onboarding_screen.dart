import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'role_choice_screen.dart';

/// One page, one message, one button.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  void _finish(BuildContext context) {
    Navigator.of(context).pushReplacement(
      FadeThroughPageRoute(child: const RoleChoiceScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(child: BarberLogo(size: 34)),
              const Spacer(flex: 2),
              // The hero moment — a floating gradient mark with a breathing
              // aura and a live scissor snip, springing in on entry. Replaces
              // the flat static icon that made the first screen feel dead.
              const Center(
                child: ScaleIn(
                  delay: Duration(milliseconds: 120),
                  duration: Duration(milliseconds: 640),
                  from: 0.6,
                  child: _OnboardingHero(),
                ),
              ),
              const SizedBox(height: 30),
              FadeSlideIn(
                delay: const Duration(milliseconds: 180),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: L.bookYourBarberLine,
                        style: AppTypography.display(context),
                      ),
                      markerBoxSpan(
                          L.inSeconds, AppTypography.display(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: Text(
                  L.onboardingSub,
                  style: AppTypography.bodySmall(context),
                ),
              ),
              const Spacer(flex: 3),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
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
    );
  }
}

/// The welcome hero: a gradient scissor mark that floats and tilts, wrapped in
/// two staggered breathing aura rings, with the blades doing a soft periodic
/// snip. All loops are GPU-cheap transform/opacity and freeze under
/// `prefers-reduced-motion` (Breathe hands back its mid-point).
class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero();

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
      // A quick periodic "snip": a short scale pulse on the blades.
      child: Breathe(
        period: const Duration(milliseconds: 2000),
        builder: (context, t) {
          // Snap closed briefly near the top of each cycle, otherwise rest.
          final snip = t < 0.16 ? math.sin(t / 0.16 * math.pi) : 0.0;
          return Transform.scale(
            scale: 1 - 0.10 * snip,
            child: const Icon(Icons.content_cut_rounded,
                size: 42, color: Colors.white),
          );
        },
      ),
    );
  }
}
