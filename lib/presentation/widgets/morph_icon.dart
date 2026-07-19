import 'package:flutter/material.dart';

/// An icon that MORPHS between two states when toggled — a Flutter take on the
/// Skiper UI "Animated Icons" micro-interaction (skiper99). The outgoing glyph
/// spins down and fades while the incoming one springs in with a slight
/// over-shoot, so a state change reads as a tactile little flip rather than an
/// instant swap.
///
/// Drive it off any boolean state (dark mode, a toggle, a like) and give it the
/// two glyphs for off/on.
class MorphIcon extends StatelessWidget {
  const MorphIcon({
    super.key,
    required this.active,
    required this.iconOff,
    required this.iconOn,
    this.size = 20,
    this.color,
  });

  final bool active;
  final IconData iconOff;
  final IconData iconOn;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final icon = active ? iconOn : iconOff;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutBack, // the spring-in overshoot
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.45, end: 1).animate(anim),
          child: RotationTransition(
            turns: Tween<double>(begin: -0.22, end: 0).animate(anim),
            child: child,
          ),
        ),
      ),
      // Keyed on the glyph so a change triggers the in/out transition.
      child: Icon(icon, key: ValueKey<IconData>(icon), size: size, color: color),
    );
  }
}
