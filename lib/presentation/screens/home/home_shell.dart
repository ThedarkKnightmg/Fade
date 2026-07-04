import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/animations/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../ai/ai_hair_screen.dart';
import '../bookings/my_bookings_screen.dart';
import '../chat/messages_screen.dart';
import '../map/shops_map_screen.dart';
import '../profile/profile_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';

/// Top-level shell — dark "Homies" bottom bar with a bright AI button in the
/// centre that opens the AI Hair Studio with a circular-reveal animation.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  int _prevIndex = 0;
  // Tabs are built lazily on first visit, then kept alive — re-opening a tab
  // (especially the map) is instant instead of rebuilding from scratch.
  final Set<int> _built = {0};

  // Drives the cross-dissolve + settle-scale when switching tabs. Starts settled
  // (value 1) so the first tab is fully visible with no entrance flash.
  late final AnimationController _tabCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 340),
    value: 1,
  );

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _go(int i) {
    if (_index == i) return;
    HapticFeedback.selectionClick();
    setState(() {
      _prevIndex = _index;
      _index = i;
      _built.add(i);
    });
    _tabCtrl.forward(from: 0);
  }

  /// One kept-alive tab layer. The structure is identical every build (only its
  /// parameters change) so each tab's State — and the map's camera — survive
  /// switches. Active + outgoing cross-dissolve; the incoming one settles up
  /// from 0.98 scale. Everything else is offstage (mounted, not painted).
  Widget _tabLayer(int i, double t, bool animating) {
    final isActive = i == _index;
    final isPrev = i == _prevIndex && _prevIndex != _index;
    final show = isActive || (isPrev && animating);
    final opacity =
        (isActive ? (animating ? t : 1.0) : (isPrev ? 1 - t : 0.0))
            .clamp(0.0, 1.0);
    final scale = isActive && animating ? (0.98 + 0.02 * t) : 1.0;
    return Offstage(
      offstage: !show,
      child: IgnorePointer(
        ignoring: !isActive,
        child: Opacity(
          opacity: opacity,
          child: Transform.scale(
            scale: scale,
            child: TickerMode(enabled: isActive, child: _bodyFor(i)),
          ),
        ),
      ),
    );
  }

  Widget _bodyFor(int i) {
    switch (i) {
      case 0:
        return HomeScreen(
          onSearchTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExploreScreen()),
          ),
          onOpenBookings: () => _go(1),
          onOpenProfile: () => _go(3),
          onOpenAi: _openAi,
        );
      case 1:
        return MyBookingsScreen(
          onExplore: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ExploreScreen()),
          ),
        );
      case 2:
        return const MessagesScreen();
      case 3:
        return const ProfileScreen();
      case 4:
        return const ShopsMapScreen(embedded: true);
      default:
        return const SizedBox.shrink();
    }
  }

  void _openAi() {
    final size = MediaQuery.of(context).size;
    // Reveal from the AI button (bottom-centre of the screen).
    final center = Offset(size.width / 2, size.height - 52);
    Navigator.of(context).push(
      _CircularRevealRoute(
        page: const AiHairScreen(),
        center: center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      extendBody: true,
      // Keep visited tabs mounted (instant switching + preserved scroll/map
      // state); pause off-screen tabs' tickers so they cost nothing. Switching
      // cross-dissolves the outgoing tab into the incoming one.
      body: AnimatedBuilder(
        animation: _tabCtrl,
        builder: (context, _) {
          final t = Curves.easeOutCubic.transform(_tabCtrl.value);
          final animating = _tabCtrl.isAnimating && _prevIndex != _index;
          return Stack(
            children: [
              for (int i = 0; i < 5; i++)
                if (_built.contains(i))
                  Positioned.fill(
                    key: ValueKey(i),
                    child: _tabLayer(i, t, animating),
                  ),
            ],
          );
        },
      ),
      bottomNavigationBar: _HomiesNav(
        index: _index,
        onTap: _go,
        onAi: _openAi,
      ),
    );
  }
}

// ============================================================
// The Homies bottom bar.
// ============================================================

class _HomiesNav extends StatelessWidget {
  const _HomiesNav({
    required this.index,
    required this.onTap,
    required this.onAi,
  });

  final int index;
  final ValueChanged<int> onTap;
  final VoidCallback onAi;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        // One-time entrance: the bar rises + fades in on first mount (it keeps
        // its position across tab changes, so this plays once, not every switch).
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 560),
          curve: Curves.easeOutCubic,
          builder: (context, v, child) => Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * 30),
              child: child,
            ),
          ),
          // Reference layout — a minimal floating pill with each tab in its own
          // circular slot and the AI orb inline — but THEME-coloured (light
          // card on the light theme), not black.
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: p.border),
              boxShadow: [
                BoxShadow(
                  color: p.shadow,
                  blurRadius: 24,
                  spreadRadius: -4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            // Bookings lives on the Home card now; the bar is
            // Home + Map · AI (centre) · Chat + Profile.
            child: Row(
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.home_rounded,
                      active: index == 0,
                      onTap: () => onTap(0),
                    ),
                    _NavItem(
                      icon: Icons.explore_rounded,
                      active: index == 4,
                      onTap: () => onTap(4),
                    ),
                  ],
                ),
              ),
              _AiButton(onTap: onAi),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _NavItem(
                      icon: Icons.forum_rounded,
                      active: index == 2,
                      onTap: () => onTap(2),
                    ),
                    _NavItem(
                      icon: Icons.face_rounded,
                      active: index == 3,
                      onTap: () => onTap(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.active, required this.onTap});

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Reference look, theme-coloured: every tab sits in its own circular slot.
    // Inactive = faint grey circle + grey glyph; active = accent-tinted circle
    // + accent glyph. Nothing else — no ring, no glow, no under-dot.
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.85,
      child: SizedBox(
        width: 56,
        height: 72,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : p.textTertiary.withValues(alpha: 0.08),
            ),
            child: AnimatedScale(
              scale: active ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Icon(
                  icon,
                  key: ValueKey(active),
                  size: 24,
                  color: active ? AppColors.accent : p.textTertiary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The bright AI button — breathes a soft glow to draw the eye, dips on press.
class _AiButton extends StatefulWidget {
  const _AiButton({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AiButton> createState() => _AiButtonState();
}

class _AiButtonState extends State<_AiButton>
    with TickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);
  late final Animation<double> _breathe =
      CurvedAnimation(parent: _glow, curve: Curves.easeInOut);
  // A slow, continuous spin so the sparkle feels alive without demanding notice.
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  )..repeat();

  @override
  void dispose() {
    _glow.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap,
      pressedScale: 0.9,
      child: AnimatedBuilder(
        animation: Listenable.merge([_breathe, _spin]),
        builder: (_, __) => Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // A lit sphere: bright highlight top-left → deep blue bottom-right.
            gradient: const RadialGradient(
              center: Alignment(-0.3, -0.4),
              radius: 0.95,
              colors: [Color(0xFF8CC6FF), Color(0xFF3E8DF0), Color(0xFF1E6FE0)],
              stops: [0.0, 0.55, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent
                    .withValues(alpha: 0.35 + _breathe.value * 0.35),
                blurRadius: 14 + _breathe.value * 10,
                spreadRadius: _breathe.value * 2,
              ),
            ],
          ),
          // The sparkle slowly rotates and twinkles (scale pulse) with the glow.
          child: Center(
            child: Transform.rotate(
              angle: _spin.value * 2 * math.pi,
              child: Transform.scale(
                scale: 0.9 + _breathe.value * 0.14,
                child: const CustomPaint(
                  size: Size(26, 26),
                  painter: _FourPointStarPainter(Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A clean single 4-point star (sparkle) — there is no crisp 4-point glyph in
/// Material Icons, so the AI orb paints its own: 4 sharp arms on the axes with
/// concave sides, filled white over a faint bloom.
class _FourPointStarPainter extends CustomPainter {
  const _FourPointStarPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final rIn = r * 0.30;
    final path = Path();
    for (int k = 0; k < 8; k++) {
      final angle = -math.pi / 2 + k * math.pi / 4;
      final rad = k.isEven ? r : rIn;
      final x = cx + rad * math.cos(angle);
      final y = cy + rad * math.sin(angle);
      if (k == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_FourPointStarPainter old) => old.color != color;
}

// ============================================================
// Circular-reveal route for the AI Studio.
// ============================================================

class _CircularRevealRoute<T> extends PageRouteBuilder<T> {
  _CircularRevealRoute({required this.page, required this.center})
      : super(
          opaque: false,
          transitionDuration: const Duration(milliseconds: 520),
          reverseTransitionDuration: const Duration(milliseconds: 360),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (context, animation, _, child) {
            final curved =
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
            return AnimatedBuilder(
              animation: curved,
              builder: (_, __) => ClipPath(
                clipper: _RevealClipper(center, curved.value),
                child: child,
              ),
            );
          },
        );

  final Widget page;
  final Offset center;
}

class _RevealClipper extends CustomClipper<Path> {
  _RevealClipper(this.center, this.fraction);
  final Offset center;
  final double fraction;

  @override
  Path getClip(Size size) {
    // Max radius = distance to the farthest corner.
    final maxR = [
      center.distance,
      (center - Offset(size.width, 0)).distance,
      (center - Offset(0, size.height)).distance,
      (center - Offset(size.width, size.height)).distance,
    ].reduce((a, b) => a > b ? a : b);
    return Path()
      ..addOval(Rect.fromCircle(center: center, radius: maxR * fraction));
  }

  @override
  bool shouldReclip(_RevealClipper old) => old.fraction != fraction;
}
