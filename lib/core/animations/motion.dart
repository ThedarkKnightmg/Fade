import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

// ============================================================
// Reusable motion toolkit — cool, purposeful animations.
// ============================================================

/// Springy press feedback: the child dips when held, pops back on release.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    // A whisper-light tick the instant a press lands — makes taps feel
    // immediate and tactile across the whole app.
    if (v && !_down) HapticFeedback.selectionClick();
    setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Animated integer that tweens up to [value] (and re-animates on change).
class CountUp extends StatelessWidget {
  const CountUp(
    this.value, {
    super.key,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
    this.prefix = '',
    this.suffix = '',
    this.formatter,
  });

  final int value;
  final TextStyle style;
  final Duration duration;

  /// Optional fixed text rendered before/after the number (e.g. '\$', 'k').
  final String prefix;
  final String suffix;

  /// Optional custom formatter for the rounded value (e.g. thousands
  /// grouping). When set, [prefix]/[suffix] are ignored.
  final String Function(int)? formatter;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) {
        final n = v.round();
        final text = formatter != null ? formatter!(n) : '$prefix$n$suffix';
        return Text(text, style: style);
      },
    );
  }
}

/// A slow diagonal light sweep across a card (glossy "shine").
class SheenSweep extends StatefulWidget {
  const SheenSweep({
    super.key,
    required this.child,
    this.radius = 28,
    this.period = const Duration(milliseconds: 4200),
  });

  final Widget child;
  final double radius;
  final Duration period;

  @override
  State<SheenSweep> createState() => _SheenSweepState();
}

class _SheenSweepState extends State<SheenSweep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  // Sweep travels left→right, with a long dark gap between.
                  final t = _c.value;
                  final x = -1.4 + t * 2.8;
                  return FractionallySizedBox(
                    widthFactor: 0.4,
                    alignment: Alignment(x, 0),
                    child: Transform.rotate(
                      angle: 0.35,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.16),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expanding radar rings behind a child — great for a "locating" icon.
class RadarPulse extends StatefulWidget {
  const RadarPulse({
    super.key,
    required this.child,
    this.color = AppColors.accent,
    this.maxRadius = 46,
  });

  final Widget child;
  final Color color;
  final double maxRadius;

  @override
  State<RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    // Honor "reduce motion": don't run the perpetual repeat — render a single
    // resting frame with the rings at rest instead.
    if (reduce) {
      if (_c.isAnimating) _c.stop();
      return CustomPaint(
        painter: _RingsPainter(0, widget.color, widget.maxRadius),
        child: widget.child,
      );
    }
    if (!_c.isAnimating) _c.repeat();
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => CustomPaint(
        painter: _RingsPainter(_c.value, widget.color, widget.maxRadius),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.t, this.color, this.maxR);
  final double t;
  final Color color;
  final double maxR;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    for (var i = 0; i < 2; i++) {
      final p = (t + i * 0.5) % 1.0;
      // Ease the expansion so rings glide out and fade gently.
      final eased = Curves.easeOut.transform(p);
      final r = (size.width / 2) + eased * maxR;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color.withValues(alpha: (1 - p) * (1 - p) * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t;
}

/// A gentle up-and-down float (hero icons, orbs).
class Floaty extends StatefulWidget {
  const Floaty({
    super.key,
    required this.child,
    this.dy = 8,
    this.period = const Duration(milliseconds: 3400),
  });

  final Widget child;
  final double dy;
  final Duration period;

  @override
  State<Floaty> createState() => _FloatyState();
}

class _FloatyState extends State<Floaty> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: widget.period)
        ..repeat(reverse: true);
  late final Animation<double> _a =
      CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -widget.dy * _a.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// One-shot confetti burst overlay (plays on mount, then idles).
class ConfettiBurst extends StatefulWidget {
  const ConfettiBurst({super.key, this.count = 60});
  final int count;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..forward();

  late final List<_Confetto> _bits;

  static const _palette = [
    AppColors.accent,
    Color(0xFF55A8FF),
    Color(0xFF8AD3FF),
    Colors.white,
    Color(0xFFFFC857),
  ];

  @override
  void initState() {
    super.initState();
    final rnd = math.Random(42);
    _bits = List.generate(widget.count, (_) {
      final ang = -math.pi / 2 + (rnd.nextDouble() - 0.5) * 1.6;
      final speed = 0.6 + rnd.nextDouble() * 0.9;
      return _Confetto(
        angle: ang,
        speed: speed,
        color: _palette[rnd.nextInt(_palette.length)],
        size: 5 + rnd.nextDouble() * 7,
        spin: (rnd.nextDouble() - 0.5) * 12,
        drift: (rnd.nextDouble() - 0.5) * 0.5,
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => CustomPaint(
          painter: _ConfettiPainter(_bits, _c.value),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Confetto {
  _Confetto({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.spin,
    required this.drift,
  });
  final double angle, speed, size, spin, drift;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.bits, this.t);
  final List<_Confetto> bits;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final origin = Offset(size.width / 2, size.height * 0.34);
    for (final b in bits) {
      final dist = b.speed * size.height * 0.9 * t;
      final gravity = 0.5 * 900 * t * t * 0.4;
      final x = origin.dx + math.cos(b.angle) * dist + b.drift * dist;
      final y = origin.dy + math.sin(b.angle) * dist + gravity;
      final opacity = (1 - t).clamp(0.0, 1.0);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(b.spin * t);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * 0.5),
          const Radius.circular(1.5),
        ),
        Paint()..color = b.color.withValues(alpha: opacity),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
