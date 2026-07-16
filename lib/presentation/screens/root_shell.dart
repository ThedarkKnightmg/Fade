import 'package:flutter/material.dart';

import '../../core/animations/app_animations.dart';
import '../../core/theme/app_colors.dart';
import '../../data/app_state.dart';
import 'barber/barber_shell.dart';
import 'home/home_shell.dart';

/// Picks the client or barber experience based on the active role, and
/// cross-fades between them when the user switches sides.
///
/// Also THE auth chokepoint: it never renders app content unless the identity
/// is [AuthStage.ready], so a session can't leak through whichever of the many
/// `pushAndRemoveUntil(RootShell())` call sites got us here, and a signOut()
/// anywhere blanks the app immediately, with no navigation call at all.
///
/// The guard is a BARRIER, not a screen. Rendering OnboardingScreen here
/// instead looks tempting and is wrong: it is a route-level screen that pushes
/// onto the very Navigator this widget sits at the base of, so you'd get
/// RootShell→Onboarding underneath the RoleChoice/Login routes it pushed, the
/// base swapping to HomeShell mid-sign-in while a route is still on top, and
/// then a *second* RootShell from the gate's pushAndRemoveUntil. Routing
/// belongs to the splash (cold start) and to the sign-out handlers — both of
/// which navigate in the same frame they clear auth, so this shows for at most
/// one frame.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        if (AppState.instance.authStage != AuthStage.ready) {
          return const _AuthBarrier();
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

/// Shown for the single frame between auth clearing and the sign-out handler's
/// navigation landing. Deliberately inert — const colours, no theme lookup, no
/// navigation, no tickers — so it can never take part in the teardown it is
/// rendered during. Matches the intro's first frame, so if it ever did linger
/// it reads as loading rather than as a bug.
class _AuthBarrier extends StatelessWidget {
  const _AuthBarrier();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFF03060E),
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
