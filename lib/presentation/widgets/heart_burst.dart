import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import 'paper_kit.dart';

/// The favourite heart, with a reason to tap it.
///
/// Saving a shop pops the heart (a quick dip, then a slight overshoot that
/// settles) and throws a ring of sparks out from it, once. Un-saving just
/// dips. It used to swap icons instantly, so saving felt like nothing
/// happened. Reduced motion: the icon simply changes.
class HeartBurstButton extends StatefulWidget {
  const HeartBurstButton({
    super.key,
    required this.saved,
    required this.onTap,
    this.size = 42,
  });

  final bool saved;
  final VoidCallback onTap;
  final double size;

  @override
  State<HeartBurstButton> createState() => _HeartBurstButtonState();
}

class _HeartBurstButtonState extends State<HeartBurstButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  bool _burst = false;

  // 1 -> 0.78 (press) -> 1.16 (pop) -> 1 (settle), no bounce curve.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.78)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 16),
    TweenSequenceItem(
        tween: Tween(begin: 0.78, end: 1.16)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 34),
    TweenSequenceItem(
        tween: Tween(begin: 1.16, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 50),
  ]).animate(_c);

  @override
  void didUpdateWidget(HeartBurstButton old) {
    super.didUpdateWidget(old);
    if (old.saved == widget.saved) return;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) return;
    _burst = widget.saved; // sparks only when saving
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_burst)
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) => CustomPaint(
                    painter: _SparksPainter(_c.value),
                  ),
                ),
              ),
            ),
          ScaleTransition(
            scale: _scale,
            child: CircleBtn(
              icon: widget.saved
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              size: widget.size,
              iconColor: widget.saved ? AppColors.red : p.text,
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onTap();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Eight short sparks flying out of the heart's centre and fading.
class _SparksPainter extends CustomPainter {
  _SparksPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    // Sparks start as the heart pops, not on the press.
    final v = ((t - 0.14) / 0.86).clamp(0.0, 1.0);
    if (v == 0) return;
    final eased = Curves.easeOutCubic.transform(v);
    final c = size.center(Offset.zero);
    final r0 = size.width * 0.42;
    final r1 = size.width * 0.86;
    final fade = 1 - Curves.easeInCubic.transform(v);
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final dir = Offset(math.cos(a), math.sin(a));
      // Each spark is a short streak whose tail catches up as it travels.
      final head = c + dir * (r0 + (r1 - r0) * eased);
      final tail = c + dir * (r0 + (r1 - r0) * eased * 0.72);
      final paint = Paint()
        ..color = (i.isEven ? AppColors.red : AppColors.accent)
            .withValues(alpha: fade)
        ..strokeWidth = 2.6 * (1 - v * 0.5)
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(tail, head, paint);
    }
  }

  @override
  bool shouldRepaint(_SparksPainter old) => old.t != t;
}
