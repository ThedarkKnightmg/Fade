import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../auth/login_screen.dart';

/// "How will you use Fade?" — pick the client or barber side at sign-up.
class RoleChoiceScreen extends StatelessWidget {
  const RoleChoiceScreen({super.key});

  // Both sides go through the SAME gate — identity first, details after. The
  // role rides along as an argument and is only committed to AppState once a
  // provider has vouched for the person, so backing out leaves nothing behind.
  //
  // The client path used to push ClientRegistrationScreen ("Ismingiz nima?"),
  // which took a typed name and walked straight into the app. That screen is
  // deleted: Telegram already returns the name AND a verified phone, so the
  // form had nothing left to ask.
  void _client(BuildContext context) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: const LoginScreen(role: AppRole.client)),
    );
  }

  void _barber(BuildContext context) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: const LoginScreen(role: AppRole.barber)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(child: BarberLogo(size: 32)),
              const SizedBox(height: 32),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text(L.howUseFade,
                    style: AppTypography.display(context)),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Text(L.pickYourSide,
                    style: AppTypography.bodySmall(context)),
              ),
              const SizedBox(height: 30),
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: _RoleCard(
                  icon: Icons.person_rounded,
                  title: L.imAClient,
                  sub: L.clientRoleSub,
                  onTap: () => _client(context),
                ),
              ),
              const SizedBox(height: 14),
              FadeSlideIn(
                delay: const Duration(milliseconds: 260),
                child: _RoleCard(
                  icon: Icons.content_cut_rounded,
                  title: L.imABarber,
                  sub: L.barberRoleSub,
                  accent: true,
                  onTap: () => _barber(context),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.sub,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String sub;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: accent ? AppColors.accent : p.card,
          borderRadius: BorderRadius.circular(24),
          border: accent ? null : Border.all(color: p.border),
          boxShadow: accent
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon,
                  size: 28, color: accent ? Colors.white : AppColors.accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.h3(context)
                        .copyWith(color: accent ? Colors.white : null),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    style: AppTypography.bodySmall(context).copyWith(
                        color: accent
                            ? Colors.white.withValues(alpha: 0.85)
                            : null),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded,
                color: accent ? Colors.white : p.textTertiary),
          ],
        ),
      ),
    );
  }
}
