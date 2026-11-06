import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/conversation_view.dart' show ChatAvatar;
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'checkin_poster_screen.dart';

/// Today's visits and closing the day.
///
/// Clients check themselves in by scanning the barber's poster; the barber
/// never scans. Each booking shows whether its client checked in, and at
/// closing time the barber marks who came. [AppState.closeDay] compares the
/// two accounts: came + checked in is a verified visit, came without a
/// check-in still counts but earns no VIP streak, checked in but "didn't
/// come" is a dispute (no fee), and neither is a no-show.
class BarberDayScreen extends StatefulWidget {
  const BarberDayScreen({super.key});

  @override
  State<BarberDayScreen> createState() => _BarberDayScreenState();
}

class _BarberDayScreenState extends State<BarberDayScreen> {
  /// The barber's answer per booking id (null = not marked yet).
  final Map<String, bool> _came = {};

  bool _due(Booking b) => !b.dateTime.isAfter(DateTime.now());

  void _close(List<Booking> open) {
    HapticFeedback.heavyImpact();
    final counts = AppState.instance.closeDay({
      for (final b in open) b.id: _came[b.id]!,
    });
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ClosedSheet(counts: counts),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: AppState.instance,
          builder: (context, _) {
            final all = AppState.instance.bookingsToClose(DateTime.now());
            // Pre-fill: a client who checked in is presumed to have come.
            for (final b in all) {
              if (b.hasArrived) _came.putIfAbsent(b.id, () => true);
            }
            final open = all
                .where((b) => b.status != BookingStatus.completed && _due(b))
                .toList();
            final ready = open.isNotEmpty && open.every((b) => _came[b.id] != null);
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    children: [
                      Row(
                        children: [
                          CircleBtn(
                            icon: Icons.arrow_back_rounded,
                            size: 42,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(L.dayTitle,
                                style: AppTypography.h2(context)),
                          ),
                          CircleBtn(
                            icon: Icons.qr_code_2_rounded,
                            size: 42,
                            onTap: () => Navigator.of(context).push(
                              FadeThroughPageRoute(
                                  child: const CheckinPosterScreen()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(L.dayHint, style: AppTypography.bodySmall(context)),
                      const SizedBox(height: 16),
                      if (all.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Center(
                            child: Text(L.dayNothing,
                                style: AppTypography.bodySmall(context)),
                          ),
                        ),
                      for (final b in all) ...[
                        _VisitRow(
                          booking: b,
                          came: _came[b.id],
                          due: _due(b),
                          onChanged: (v) => setState(() => _came[b.id] = v),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                if (open.isNotEmpty)
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(
                      color: p.card,
                      border: Border(top: BorderSide(color: p.border)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!ready)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(L.dayMarkAll,
                                style: AppTypography.caption(context)),
                          ),
                        PrimaryButton(
                          label: L.dayClose,
                          icon: Icons.task_alt_rounded,
                          height: 54,
                          onPressed: ready ? () => _close(open) : null,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  const _VisitRow({
    required this.booking,
    required this.came,
    required this.due,
    required this.onChanged,
  });

  final Booking booking;
  final bool? came;
  final bool due;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final name = b.clientName ?? '—';
    final done = b.status == BookingStatus.completed;
    final hhmm = DateFormat('HH:mm');

    // The client's side of the story.
    final (IconData icon, Color color, String label) = b.hasArrived
        ? (b.arrivedNearShop == false
            ? (Icons.location_off_rounded, const Color(0xFFD99A2E), L.dayScannedFar)
            : (Icons.verified_rounded, AppColors.green, L.dayScannedAt(hhmm.format(b.arrivedAt!))))
        : (Icons.qr_code_2_rounded, p.textTertiary, L.dayNoScan);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: clayDecoration(p, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ChatAvatar(name: name, size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h4(context)),
                    Text('${hhmm.format(b.dateTime)} · ${L.tr(b.service.name)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodySmall(context)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (done)
            _Tag(text: L.dayDone, color: AppColors.green)
          else if (!due)
            _Tag(text: L.dayLater, color: p.textTertiary)
          else
            Row(
              children: [
                Expanded(
                  child: _Choice(
                    label: L.dayCame,
                    icon: Icons.check_rounded,
                    selected: came == true,
                    color: AppColors.green,
                    onTap: () => onChanged(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Choice(
                    label: L.dayDidntCome,
                    icon: Icons.close_rounded,
                    selected: came == false,
                    color: AppColors.red,
                    onTap: () => onChanged(false),
                  ),
                ),
              ],
            ),
          // What closing will do with this answer, before it's final.
          if (!done && due && came != null) ...[
            const SizedBox(height: 8),
            _OutcomeLine(
                outcome: AppState.dayOutcome(scanned: b.hasArrived, came: came!)),
          ],
        ],
      ),
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.14) : p.cardAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? color : Colors.transparent, width: 1.6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: selected ? color : p.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: selected ? color : p.textSecondary,
                )),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(text,
          style: GoogleFonts.nunito(
              fontSize: 12.5, fontWeight: FontWeight.w900, color: color)),
    );
  }
}

(String, Color) _outcomeStyle(DayOutcome o) => switch (o) {
      DayOutcome.verified => (L.dayVerified, AppColors.green),
      DayOutcome.unverified => (L.dayUnverified, const Color(0xFFD99A2E)),
      DayOutcome.disputed => (L.dayDisputed, AppColors.accent),
      DayOutcome.noShow => (L.dayNoShow, AppColors.red),
    };

class _OutcomeLine extends StatelessWidget {
  const _OutcomeLine({required this.outcome});
  final DayOutcome outcome;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _outcomeStyle(outcome);
    return Row(
      children: [
        Icon(Icons.arrow_forward_rounded, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }
}

/// The result of closing the day: how many visits landed in each outcome.
class _ClosedSheet extends StatelessWidget {
  const _ClosedSheet({required this.counts});
  final Map<DayOutcome, int> counts;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded, color: AppColors.green, size: 26),
                const SizedBox(width: 10),
                Text(L.dayClosedTitle, style: AppTypography.h3(context)),
              ],
            ),
            const SizedBox(height: 14),
            for (final o in DayOutcome.values)
              if ((counts[o] ?? 0) > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _outcomeStyle(o).$2,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_outcomeStyle(o).$1,
                            style: AppTypography.body(context)),
                      ),
                      Text('${counts[o]}',
                          style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: p.text)),
                    ],
                  ),
                ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: L.okGotIt,
              height: 50,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
