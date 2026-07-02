import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../widgets/paper_kit.dart';
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

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  // Tabs are built lazily on first visit, then kept alive — re-opening a tab
  // (especially the map) is instant instead of rebuilding from scratch.
  final Set<int> _built = {0};

  void _go(int i) {
    if (_index == i) return;
    setState(() {
      _index = i;
      _built.add(i);
    });
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
      // state); pause off-screen tabs' tickers so they cost nothing.
      body: Stack(
        children: [
          for (int i = 0; i < 5; i++)
            if (_built.contains(i))
              Positioned.fill(
                child: Offstage(
                  offstage: _index != i,
                  child: TickerMode(
                    enabled: _index == i,
                    child: _bodyFor(i),
                  ),
                ),
              ),
        ],
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
        child: Container(
          height: 68,
          decoration: clayDecoration(p, radius: 26),
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
                      icon: Icons.map_rounded,
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
                      icon: Icons.chat_bubble_rounded,
                      active: index == 2,
                      onTap: () => onTap(2),
                    ),
                    _NavItem(
                      icon: Icons.person_rounded,
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
    return PressableScale(
      onTap: onTap,
      pressedScale: 0.85,
      child: SizedBox(
        width: 50,
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: active ? 1.18 : 1.0,
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                child: Icon(
                  icon,
                  key: ValueKey(active),
                  size: 25,
                  color: active ? AppColors.accent : p.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 5),
            // A glowing dot slides/grows in under the active tab.
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              width: active ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.7),
                          blurRadius: 8,
                        )
                      ]
                    : null,
              ),
            ),
          ],
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
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..repeat(reverse: true);
  late final Animation<double> _breathe =
      CurvedAnimation(parent: _glow, curve: Curves.easeInOut);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: widget.onTap,
      pressedScale: 0.9,
      child: AnimatedBuilder(
        animation: _breathe,
        builder: (_, child) => Container(
          width: 58,
          height: 58,
          transform: Matrix4.translationValues(0, -6, 0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF55A8FF), Color(0xFF1E6FE0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent
                    .withValues(alpha: 0.4 + _breathe.value * 0.4),
                blurRadius: 16 + _breathe.value * 12,
                spreadRadius: 1 + _breathe.value * 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_awesome_rounded, size: 22, color: Colors.white),
            Text('AI',
                style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1,
                    height: 1)),
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
