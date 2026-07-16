import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../data/app_state.dart';
import '../onboarding/barber_registration_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../root_shell.dart';
import 'scissors_intro.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  /// Called when the scissors finish cutting the screen.
  ///
  /// Branches on the single [AuthStage] — it no longer *repairs* a missing
  /// session by calling signIn(), which was why identity could never block
  /// entry: the one code path that could deny access healed itself instead.
  void _navigateNext() {
    if (!mounted) return;
    final state = AppState.instance;
    final Widget next;
    switch (state.authStage) {
      case AuthStage.anonymous:
        next = const OnboardingScreen();
      case AuthStage.identified:
        // A barber who proved who they are but never finished picking a chair.
        // Resume the setup instead of stranding them in a half-built app.
        assert(state.activeRole == AppRole.barber,
            'only barbers should rest at AuthStage.identified');
        next = const BarberRegistrationScreen();
      case AuthStage.ready:
        next = const RootShell();
    }
    Navigator.of(context).pushReplacement(FadeThroughPageRoute(child: next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Deep space — the intro opens with a hyperspace jump, so the very first
      // frame must be near-black (not the navy stage) to avoid a colour flash.
      backgroundColor: const Color(0xFF03060E),
      body: ScissorsCutIntro(onDone: _navigateNext),
    );
  }
}
