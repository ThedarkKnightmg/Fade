import 'package:flutter/material.dart';

import '../../core/animations/app_animations.dart';
import '../../data/app_state.dart';
import 'barber/barber_shell.dart';
import 'home/home_shell.dart';
import 'onboarding/onboarding_screen.dart';

/// Picks the client or barber experience based on the active role, and
/// cross-fades between them when the user switches sides.
///
/// Also THE auth chokepoint. Because it rebuilds on every AppState change, an
/// unauthenticated state renders the gate no matter which of the many
/// `pushAndRemoveUntil(RootShell())` call sites got us here — so auth is
/// enforced in one place instead of trusted at eleven. A signOut() anywhere
/// now returns to onboarding with no navigation call at all.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        if (AppState.instance.authStage != AuthStage.ready) {
          return const OnboardingScreen();
        }
        final barber = AppState.instance.isBarberMode;
        return AnimatedSwitcher(
          duration: AppDurations.normal,
          child: barber
              ? const BarberShell(key: ValueKey('barber'))
              : const HomeShell(key: ValueKey('client')),
        );
      },
    );
  }
}
