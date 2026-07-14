import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
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
          // Reference look: a flat rounded bar — glyph above an always-visible
          // label on every tab, the active one in accent with a short
          // indicator bar at the bottom edge. AI rides as a uniform middle
          // tab (no raised orb).
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(22),
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
            child: Row(
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  label: L.navHome,
                  active: index == 0,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  icon: Icons.search_rounded,
                  activeIcon: Icons.search_rounded,
                  label: L.navExplore,
                  active: index == 4,
                  onTap: () => onTap(4),
                ),
                _NavItem(
                  icon: Icons.auto_awesome_outlined,
                  activeIcon: Icons.auto_awesome,
                  label: 'AI',
                  active: false,
                  onTap: onAi,
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline_rounded,
                  activeIcon: Icons.chat_bubble_rounded,
                  label: L.navChats,
                  active: index == 2,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: L.navProfile,
                  active: index == 3,
                  onTap: () => onTap(3),
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
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Reference look: outlined glyph above a small always-visible label; the
    // active tab turns accent (filled glyph) and a short indicator bar slides
    // in at the bottom edge.
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                active ? activeIcon : icon,
                key: ValueKey(active),
                size: 23,
                color: active ? AppColors.accent : p.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: active ? AppColors.accent : p.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            // The short accent bar under the active tab (reference style).
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: active ? 26 : 0,
              height: 3.5,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
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
