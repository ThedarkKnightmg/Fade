import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import 'barber_dashboard_screen.dart';
import 'barber_messages_screen.dart';
import 'barber_profile_screen.dart';
import 'barber_requests_screen.dart';
import 'barber_schedule_screen.dart';
import 'incoming_request_sheet.dart';

/// The barber side of the app — a separate bottom-nav shell shown when the
/// user switches to Barber mode. Tabs: Today, Requests, Schedule, Profile.
class BarberShell extends StatefulWidget {
  const BarberShell({super.key});

  @override
  State<BarberShell> createState() => _BarberShellState();
}

class _BarberShellState extends State<BarberShell> {
  int _index = 0;
  final Set<int> _built = {0};

  // Armed only once per app session — switching client->barber re-creates this
  // State and would otherwise schedule a fresh demo timer (and pop a new sheet)
  // on every re-entry.
  static bool _demoArmed = false;

  Timer? _demoTimer;
  bool _popupShowing = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onState);
    // Simulate a client booking arriving a few seconds after the barber first
    // opens the app, so the live request pop-up is demoable. (In production this
    // is driven by a realtime Supabase booking insert.)
    if (!_demoArmed) {
      _demoArmed = true;
      _demoTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) AppState.instance.simulateIncomingRequest();
      });
    }
  }

  @override
  void dispose() {
    _demoTimer?.cancel();
    AppState.instance.removeListener(_onState);
    super.dispose();
  }

  void _onState() {
    final req = AppState.instance.incomingPopup;
    if (req != null && !_popupShowing && mounted) {
      _popupShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showIncomingRequestSheet(context, req).whenComplete(() {
          _popupShowing = false;
          AppState.instance.clearIncomingPopup();
        });
      });
    }
  }

  void _go(int i) {
    if (_index == i) return;
    setState(() {
      _index = i;
      _built.add(i);
    });
  }

  Widget _bodyFor(int i) => switch (i) {
        0 => BarberDashboardScreen(
            onGoToRequests: () => _go(1),
            onGoToSchedule: () => _go(2),
            onOpenMessages: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const BarberMessagesScreen(),
              ),
            ),
          ),
        1 => const BarberRequestsScreen(),
        2 => const BarberScheduleScreen(),
        _ => const BarberProfileScreen(),
      };

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      extendBody: true,
      body: Stack(
        children: [
          for (int i = 0; i < 4; i++)
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
      bottomNavigationBar: _BarberNav(index: _index, onTap: _go),
    );
  }
}

class _BarberNav extends StatelessWidget {
  const _BarberNav({required this.index, required this.onTap});

  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Clean clay pill, same as the client bar — icons with a glowing active-dot
    // underneath, no per-tab circles. The badge stays on Requests.
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final pending = AppState.instance.incomingRequests.length;
        return Container(
          height: 68,
          margin: EdgeInsets.fromLTRB(
              16, 0, 16, 12 + MediaQuery.of(context).padding.bottom),
          decoration: clayDecoration(p, radius: 26),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                  icon: Icons.today_rounded,
                  selected: index == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.inbox_rounded,
                  selected: index == 1,
                  badge: pending,
                  onTap: () => onTap(1)),
              _NavItem(
                  icon: Icons.calendar_month_rounded,
                  selected: index == 2,
                  onTap: () => onTap(2)),
              _NavItem(
                  icon: Icons.person_rounded,
                  selected: index == 3,
                  onTap: () => onTap(3)),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // Clean tab: just the glyph (with the Requests badge), and a glowing accent
    // dot that grows in underneath the selected one. No circular slot.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 54,
        height: 68,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.18 : 1.0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    size: 25,
                    color: selected ? AppColors.accent : p.textTertiary,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: const BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badge',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            // A glowing dot slides/grows in under the selected tab.
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOut,
              width: selected ? 6 : 0,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                boxShadow: selected
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
