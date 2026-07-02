import 'package:flutter/material.dart';

/// Centralized animation tokens — durations and curves used across the app.
class AppDurations {
  AppDurations._();

  // Tightened for a snappier, more responsive feel — transitions land fast
  // without feeling abrupt.
  static const Duration instant = Duration(milliseconds: 90);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 460);
  static const Duration slower = Duration(milliseconds: 680);
  static const Duration page = Duration(milliseconds: 260);
}

class AppCurves {
  AppCurves._();

  static const Curve easeOutQuart = Cubic(0.25, 1, 0.5, 1);
  static const Curve easeOutBack = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve spring = Cubic(0.5, 1.5, 0.5, 1);
  static const Curve smooth = Curves.easeInOutCubic;
}

/// Counts a number up to [value] on first build, and re-tweens from the current
/// value whenever it changes (balances, stats, progress). GPU-cheap — it just
/// rebuilds whatever [builder] returns.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({
    super.key,
    required this.value,
    required this.builder,
    this.duration = const Duration(milliseconds: 900),
    this.curve = AppCurves.easeOutQuart,
  });

  final double value;
  final Widget Function(BuildContext context, double value) builder;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return builder(context, value);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: curve,
      builder: (context, v, _) => builder(context, v),
    );
  }
}

/// A gentle forever-loop that eases a value 0→1→0 — for ambient "breathing"
/// on hero surfaces (a slow drifting sheen, a pulsing glow). Pass [builder] a
/// 0..1 value. Pauseable via reduced-motion.
class Breathe extends StatefulWidget {
  const Breathe({
    super.key,
    required this.builder,
    this.period = const Duration(milliseconds: 4200),
  });

  final Widget Function(BuildContext context, double t) builder;
  final Duration period;

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe>
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
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return widget.builder(context, 0.5);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        // Triangle 0→1→0, eased, so it drifts rather than ticks.
        final raw = _c.value;
        final tri = raw < 0.5 ? raw * 2 : (1 - raw) * 2;
        return widget.builder(context, Curves.easeInOut.transform(tri));
      },
    );
  }
}

/// A widget that fades + slides children into view with a stagger.
/// Wrap a column/list child to animate its entrance.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 600),
    this.offset = const Offset(0, 0.15),
    this.curve = AppCurves.easeOutQuart,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: widget.curve);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Scale-in entry animation, useful for icons, cards, and modal content.
class ScaleIn extends StatefulWidget {
  const ScaleIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 500),
    this.curve = AppCurves.easeOutBack,
    this.from = 0.85,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Curve curve;
  final double from;

  @override
  State<ScaleIn> createState() => _ScaleInState();
}

class _ScaleInState extends State<ScaleIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: widget.from,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

  late final Animation<double> _fade =
      CurvedAnimation(parent: _controller, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

/// Custom page route with a smooth shared-axis transition.
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  FadeThroughPageRoute({required this.child})
      : super(
          transitionDuration: AppDurations.page,
          reverseTransitionDuration: AppDurations.page,
          pageBuilder: (_, __, ___) => child,
          transitionsBuilder: (_, animation, __, child) {
            final fade = CurvedAnimation(
              parent: animation,
              curve: AppCurves.easeOutQuart,
            );
            final slide = Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(fade);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );

  final Widget child;
}

/// A simple shimmer loading container.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height = 16,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(-1.0 + 2 * t, 0),
              end: Alignment(1.0 + 2 * t, 0),
              colors: const [
                Color(0xFFEAE5DB),
                Color(0xFFF5F0E5),
                Color(0xFFEAE5DB),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Reveals its child as it scrolls into view — fade + slide-up + a subtle
/// scale, scrubbed to the scroll position so a list cascades in smoothly as
/// you go. Resolves the enclosing [PrimaryScrollController]; falls back to
/// showing the child statically when motion is reduced or no controller is
/// found. Uses only opacity + transform (GPU-friendly), so it stays at 60fps.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({
    super.key,
    required this.child,
    this.shift = 26,
    this.scaleFrom = 0.97,
  });

  final Widget child;
  final double shift;
  final double scaleFrom;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal> {
  ScrollController? _controller;

  @override
  void initState() {
    super.initState();
    // Recompute once after first layout so below-fold items start hidden.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = PrimaryScrollController.maybeOf(context);
  }

  /// 0 = just entering from the bottom of the viewport, 1 = comfortably in.
  double _progress() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return 1;
    final h = MediaQuery.of(context).size.height;
    final topY = box.localToGlobal(Offset.zero).dy;
    const start = 0.97, end = 0.74;
    return ((start * h - topY) / ((start - end) * h)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final ctrl = _controller;
    if (reduce || ctrl == null) return widget.child;
    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, child) {
        final p = Curves.easeOutCubic.transform(_progress());
        return Opacity(
          opacity: p,
          child: Transform.translate(
            offset: Offset(0, (1 - p) * widget.shift),
            child: Transform.scale(
              scale: widget.scaleFrom + (1 - widget.scaleFrom) * p,
              child: child,
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
