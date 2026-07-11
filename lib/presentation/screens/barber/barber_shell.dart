import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/app_state.dart';
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
    // Reference layout, same as the client bar — a minimal floating pill with
    // circular slots, no labels — but THEME-coloured, not black. The badge
    // stays on Requests.
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final pending = AppState.instance.incomingRequests.length;
        return Container(
          height: 72,
          margin: EdgeInsets.fromLTRB(
              16, 0, 16, 12 + MediaQuery.of(context).padding.bottom),
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
    // Same slot treatment as the client bar: a circle that lights up with the
    // accent when selected, grey glyph otherwise. Minimal — no label.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.14)
                  : p.textTertiary.withValues(alpha: 0.08),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    icon,
                    size: 24,
                    color: selected ? AppColors.accent : p.textTertiary,
                  ),
                ),
                if (badge > 0)
                  Positioned(
                    right: 4,
                    top: 6,
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
          ),
        ),
      ),
    );
  }
}
