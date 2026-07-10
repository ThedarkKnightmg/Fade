import 'package:flutter/material.dart';

import '../../../core/animations/app_animations.dart';
import '../../../data/app_state.dart';
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
  void _navigateNext() {
    if (!mounted) return;
    final state = AppState.instance;
    final next = !state.hasCompletedOnboarding
        ? const OnboardingScreen()
        : const RootShell();
    if (state.hasCompletedOnboarding && !state.isAuthenticated) {
      state.signIn(); // demo shortcut — no backend yet
    }
    Navigator.of(context).pushReplacement(FadeThroughPageRoute(child: next));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13233F),
      body: ScissorsCutIntro(onDone: _navigateNext),
    );
  }
}
