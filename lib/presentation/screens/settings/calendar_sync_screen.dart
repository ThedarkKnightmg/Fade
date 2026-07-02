import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';

/// "Connect Google/Apple Calendar" — explains two-way sync and stubs the
/// connect action (real OAuth is backend). The busy-block engine (walk-ins)
/// already works offline, which the note makes explicit.
class CalendarSyncScreen extends StatelessWidget {
  const CalendarSyncScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Text(L.calendarSyncLabel, style: AppTypography.h2(context)),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: clayDecoration(p, radius: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(Icons.sync_rounded,
                                color: AppColors.accent, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(L.calendarSyncTitle,
                                style: AppTypography.h3(context)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(L.calendarSyncBody,
                          style: AppTypography.bodySmall(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _CalRow(
                  label: L.connectGoogleCal,
                  icon: Icons.event_rounded,
                  connected: s.googleCalConnected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    s.setCalendarConnected(google: !s.googleCalConnected);
                    if (s.googleCalConnected) _toast(context);
                  },
                ),
                const SizedBox(height: 10),
                _CalRow(
                  label: L.connectAppleCal,
                  icon: Icons.calendar_month_rounded,
                  connected: s.appleCalConnected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    s.setCalendarConnected(apple: !s.appleCalConnected);
                    if (s.appleCalConnected) _toast(context);
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 15, color: p.textTertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(L.calBackendNote,
                          style: AppTypography.caption(context)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _toast(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.calConnectedToast),
        behavior: SnackBarBehavior.floating,
      ));
  }
}

class _CalRow extends StatelessWidget {
  const _CalRow({
    required this.label,
    required this.icon,
    required this.connected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: clayDecoration(
          p,
          radius: 16,
          borderColor: connected ? AppColors.green : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: p.text),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: connected
                    ? AppColors.green.withValues(alpha: 0.14)
                    : p.bg,
                borderRadius: BorderRadius.circular(999),
                border: connected
                    ? null
                    : Border.all(color: p.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (connected) ...[
                    const Icon(Icons.check_rounded,
                        size: 14, color: AppColors.green),
                    const SizedBox(width: 4),
                  ],
                  Text(connected ? L.calConnected : L.calNotConnected,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: connected ? AppColors.green : p.textSecondary,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
