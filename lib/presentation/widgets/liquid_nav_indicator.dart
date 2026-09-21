import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// The liquid tab indicator: it doesn't slide between tabs, it *stretches*
/// across and pulls itself back together.
///
/// How the melt is done — the same trick as the CSS "gooey" filter, which is
/// blur-then-threshold. Shapes are drawn, blurred so their soft edges overlap,
/// then run through a colour matrix that slams alpha back to hard edges. Two
/// blurred shapes whose halos touch come out of that threshold as ONE shape
/// with a smooth neck between them — no tangent maths, no hand-solved sockets,
/// and it can never crease, because the union is computed per-pixel rather
/// than constructed as a path.
///
/// The motion is what sells it: the leading edge runs ahead on an ease-OUT
/// curve while the trailing edge lags on an ease-IN one. The blob is therefore
/// longest exactly halfway through the trip and snaps closed on arrival, which
/// is what reads as surface tension rather than a moving pill.
class LiquidNavIndicator extends StatefulWidget {
  const LiquidNavIndicator({
    super.key,
    required this.slotCount,
    required this.activeSlot,
    required this.color,
    this.blobWidth = 46,
    this.blobHeight = 42,
  });

  /// How many equal-width slots the bar is divided into (one per tab).
  final int slotCount;

  /// Which slot is lit. Changing this animates the melt.
  final int activeSlot;

  final Color color;
  final double blobWidth;
  final double blobHeight;

  @override
  State<LiquidNavIndicator> createState() => _LiquidNavIndicatorState();
}

class _LiquidNavIndicatorState extends State<LiquidNavIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..value = 1;

  late int _from = widget.activeSlot;
  late int _to = widget.activeSlot;

  @override
  void didUpdateWidget(covariant LiquidNavIndicator old) {
    super.didUpdateWidget(old);
    if (old.activeSlot != widget.activeSlot) {
      // Start from wherever the blob currently *is*, not from the last target,
      // so interrupting a trip mid-flight doesn't teleport it.
      _from = _c.isAnimating ? _visualSlot() : _to;
      _to = widget.activeSlot;
      _c.forward(from: 0);
    }
  }

  /// The slot the blob is visually occupying right now, used when a tap
  /// interrupts an in-flight melt.
  int _visualSlot() {
    final t = Curves.easeInOut.transform(_c.value);
    return (_from + (_to - _from) * t).round();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final slotW = box.maxWidth / widget.slotCount;
          double centreOf(int slot) => (slot + 0.5) * slotW;

          return AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final t = _c.value;
              // Leading edge sprints, trailing edge drags. Their gap IS the
              // stretch, and it closes on its own at t = 1.
              final lead = ui.lerpDouble(
                centreOf(_from),
                centreOf(_to),
                Curves.easeOutCubic.transform(t),
              )!;
              final trail = ui.lerpDouble(
                centreOf(_from),
                centreOf(_to),
                Curves.easeInCubic.transform(t),
              )!;

              return ColorFiltered(
                // Threshold pass: multiply alpha hard and pull it back down, so
                // the blurred halos below resolve into one crisp liquid edge.
                colorFilter: const ColorFilter.matrix(<double>[
                  1, 0, 0, 0, 0, //
                  0, 1, 0, 0, 0, //
                  0, 0, 1, 0, 0, //
                  0, 0, 0, 22, -2805, //
                ]),
                child: ImageFiltered(
                  imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
                  child: CustomPaint(
                    size: Size(box.maxWidth, box.maxHeight),
                    painter: _LiquidPainter(
                      lead: lead,
                      trail: trail,
                      width: widget.blobWidth,
                      height: widget.blobHeight,
                      color: widget.color,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  const _LiquidPainter({
    required this.lead,
    required this.trail,
    required this.width,
    required this.height,
    required this.color,
  });

  final double lead;
  final double trail;
  final double width;
  final double height;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final cy = size.height / 2;
    final half = width / 2;
    final r = height / 2;

    final left = math.min(lead, trail) - half;
    final right = math.max(lead, trail) + half;

    // The spanning body...
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(left, cy - height / 2, right, cy + height / 2),
        Radius.circular(r),
      ),
      paint,
    );
    // ...plus a bulb at each end. While the blob is stretched these read as the
    // two ends of a drip; once it closes they sit inside the body and vanish.
    canvas.drawCircle(Offset(trail, cy), r * 0.92, paint);
    canvas.drawCircle(Offset(lead, cy), r * 0.92, paint);
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter old) =>
      old.lead != lead || old.trail != trail || old.color != color;
}
