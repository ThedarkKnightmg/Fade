import 'package:flutter/material.dart';

import '../../core/animations/app_animations.dart';
import '../../data/app_state.dart';
import 'barber/barber_shell.dart';
import 'home/home_shell.dart';

/// Picks the client or barber experience based on the active role, and
/// cross-fades between them when the user switches sides.
class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
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
