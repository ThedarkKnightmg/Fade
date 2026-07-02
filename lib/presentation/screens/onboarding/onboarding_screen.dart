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
              FadeSlideIn(
                delay: const Duration(milliseconds: 100),
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.content_cut_rounded,
                    size: 34,
                    color: AppColors.accentDeep,
                  ),
                ),
              ),
              const SizedBox(height: 28),
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
