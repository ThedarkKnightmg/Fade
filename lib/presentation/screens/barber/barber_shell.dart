import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/app_state.dart';
import 'barber_dashboard_screen.dart';
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

  Timer? _demoTimer;
  bool _popupShowing = false;

  @override
  void initState() {
    super.initState();
    AppState.instance.addListener(_onState);
    // Simulate a client booking arriving a few seconds after the barber opens
    // the app, so the live request pop-up is demoable. (In production this is
    // driven by a realtime Supabase booking insert.)
    _demoTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) AppState.instance.simulateIncomingRequest();
    });
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
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final pending = AppState.instance.incomingRequests.length;
        return Container(
          margin: EdgeInsets.fromLTRB(
              16, 0, 16, 12 + MediaQuery.of(context).padding.bottom),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? 0.3 : 0.08),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                  icon: Icons.today_rounded,
                  label: L.today,
                  selected: index == 0,
                  onTap: () => onTap(0)),
              _NavItem(
                  icon: Icons.inbox_rounded,
                  label: L.requestsTitle,
                  selected: index == 1,
                  badge: pending,
                  onTap: () => onTap(1)),
              _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: L.scheduleTitle,
                  selected: index == 2,
                  onTap: () => onTap(2)),
              _NavItem(
                  icon: Icons.person_rounded,
                  label: L.profileTab,
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
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final color = selected ? AppColors.accent : p.textTertiary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 22, color: color),
                if (badge > 0)
                  Positioned(
                    right: -8,
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
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
