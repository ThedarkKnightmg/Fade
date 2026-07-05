import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/mock_data.dart';
import '../../../data/models/barber_break.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'incoming_request_sheet.dart';
import 'walk_in_sheet.dart';

/// The barber's calendar — a real time-grid day view. Pick a day on the strip,
/// then read the whole day as 30-minute rows with every booking drawn as a
/// block on the timeline (empty rows = free slots).
class BarberScheduleScreen extends StatefulWidget {
  const BarberScheduleScreen({super.key});

  @override
  State<BarberScheduleScreen> createState() => _BarberScheduleScreenState();
}

class _BarberScheduleScreenState extends State<BarberScheduleScreen> {
  late DateTime _selected;
  late final List<DateTime> _days;
  late final ScrollController _strip;
  final ScrollController _grid = ScrollController();

  // Date-strip cell metrics.
  static const double _cell = 56;
  static const double _gap = 8;

  // Time-grid metrics.
  static const double _slotH = 60; // height of one 30-minute row
  static const double _gutter = 52; // left time-label column
  static const double _topPad = 10; // breathing room above the first line

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    _selected = today;
    _days = List.generate(38, (i) => today.add(Duration(days: i - 3)));
    _strip = ScrollController(initialScrollOffset: 3 * (_cell + _gap) - 18);
    _autoScroll();
  }

  @override
  void dispose() {
    _strip.dispose();
    _grid.dispose();
    super.dispose();
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }

  DateTime _end(Booking b) =>
      b.dateTime.add(Duration(minutes: b.service.durationMinutes));

  /// Open/close hours for the selected day — defaults to 09:00–21:00 but
  /// stretches to fit any booking or break outside those hours.
  (int, int) _hours(List<Booking> day, List<BarberBreak> breaks) {
    final s = AppState.instance;
    int open = s.workStartHour, close = s.workEndHour;
    for (final b in day) {
      final s = b.dateTime;
      final e = _end(b);
      open = math.min(open, s.hour);
      final endHour = e.minute > 0 ? e.hour + 1 : e.hour;
      close = math.max(close, endHour);
    }
    for (final br in breaks) {
      open = math.min(open, br.startMinutes ~/ 60);
      final endH = (br.endMinutes / 60).ceil();
      close = math.max(close, endH);
    }
    return (open, math.min(close, 24));
  }

  double _topFor(DateTime dt, int open) =>
      _topPad + ((dt.hour - open) * 60 + dt.minute) / 30 * _slotH;

  /// Jump the grid to something useful: the first booking, or "now" on today.
  void _autoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_grid.hasClients) return;
      final day = AppState.instance.barberBookingsOn(_selected);
      final (open, _) =
          _hours(day, AppState.instance.barberBreaksOn(_selected));
      double target;
      if (day.isNotEmpty) {
        target = _topFor(day.first.dateTime, open) - 90;
      } else if (_isToday(_selected)) {
        final n = DateTime.now();
        target = _topPad + ((n.hour - open) * 60 + n.minute) / 30 * _slotH - 130;
      } else {
        target = 0;
      }
      target = target.clamp(0.0, _grid.position.maxScrollExtent);
      _grid.animateTo(target,
          duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    });
  }

  void _pickDay(DateTime d) {
    setState(() => _selected = d);
    _autoScroll();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final dayBookings = s.barberBookingsOn(_selected);
          final dayBreaks = s.barberBreaksOn(_selected);
          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(L.scheduleTitle,
                                style: AppTypography.h1(context)),
                            Text(DateFormat('MMMM yyyy').format(_selected),
                                style: AppTypography.bodySmall(context)),
                          ],
                        ),
                      ),
                      _Pill(label: L.upcomingCountLabel(s.barberAgenda.length)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // ── Date strip ──
                SizedBox(
                  height: 76,
                  child: ListView.separated(
                    controller: _strip,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _days.length,
                    separatorBuilder: (_, __) => const SizedBox(width: _gap),
                    itemBuilder: (_, i) {
                      final d = _days[i];
                      return _DateCell(
                        date: d,
                        count: s.barberActiveCountOn(d),
                        selected: _sameDay(d, _selected),
                        today: _isToday(d),
                        width: _cell,
                        onTap: () => _pickDay(d),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _isToday(_selected)
                              ? L.today
                              : DateFormat('EEEE, d MMM').format(_selected),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h3(context),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dayBookings.isEmpty
                            ? L.freeWord
                            : L.bookingsCount(dayBookings.length),
                        style: AppTypography.bodySmall(context),
                      ),
                      const Spacer(),
                      // Timeline ⇄ booking-style slots — the barber keeps
                      // whichever view he likes (persisted).
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          s.setScheduleSlotsView(!s.scheduleSlotsView);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            s.scheduleSlotsView
                                ? Icons.view_agenda_rounded
                                : Icons.grid_view_rounded,
                            size: 17,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AddBreakButton(
                          onTap: () => _openBreakSheet(context, _selected)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // ── Body: timeline grid, or booking-style slot chips ──
                Expanded(
                  child: s.scheduleSlotsView
                      ? _SlotsView(
                          day: _selected,
                          bookings: dayBookings,
                          breaks: dayBreaks,
                          end: _end,
                          onTapBooking: (b) => _openBooking(context, b),
                        )
                      : _DayGrid(
                          controller: _grid,
                          day: dayBookings,
                          breaks: dayBreaks,
                          selectedDay: _selected,
                          hours: _hours(dayBookings, dayBreaks),
                          isToday: _isToday(_selected),
                          end: _end,
                          topFor: _topFor,
                          onTapBooking: (b) => _openBooking(context, b),
                          onTapBreak: (br) => _confirmRemoveBreak(context, br),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openBooking(BuildContext context, Booking b) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookingSheet(booking: b),
    );
  }

  void _openBreakSheet(BuildContext context, DateTime day) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BreakSheet(day: day),
    );
  }

  void _confirmRemoveBreak(BuildContext context, BarberBreak br) {
    HapticFeedback.selectionClick();
    final p = Paper.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(br.label, style: AppTypography.h3(context)),
        content: Text(L.removeBreakQ, style: AppTypography.body(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(L.cancel,
                style: TextStyle(color: p.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              AppState.instance.removeBreak(br.id);
              Navigator.of(ctx).pop();
            },
            child: Text(L.removeWord,
                style: const TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

// ─────────────────────────────────────────────────────────────────────────
//  The time grid
// ─────────────────────────────────────────────────────────────────────────

class _DayGrid extends StatelessWidget {
  const _DayGrid({
    required this.controller,
    required this.day,
    required this.breaks,
    required this.selectedDay,
    required this.hours,
    required this.isToday,
    required this.end,
    required this.topFor,
    required this.onTapBooking,
    required this.onTapBreak,
  });

  final ScrollController controller;
  final List<Booking> day;
  final List<BarberBreak> breaks;
  final DateTime selectedDay;
  final (int, int) hours;
  final bool isToday;
  final DateTime Function(Booking) end;
  final double Function(DateTime, int) topFor;
  final ValueChanged<Booking> onTapBooking;
  final ValueChanged<BarberBreak> onTapBreak;

  static const double _slotH = _BarberScheduleScreenState._slotH;
  static const double _gutter = _BarberScheduleScreenState._gutter;
  static const double _topPad = _BarberScheduleScreenState._topPad;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final (open, close) = hours;
    final slots = (close - open) * 2; // number of 30-min rows
    final gridHeight = _topPad + slots * _slotH + 16;
    final placed = _layout(day);

    return LayoutBuilder(
      builder: (context, c) {
        final laneW = c.maxWidth - _gutter - 20; // 20 = right padding
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 150),
          child: SizedBox(
            height: gridHeight,
            child: Stack(
              children: [
                // ── Grid lines + time labels (every 30 min) ──
                for (int i = 0; i <= slots; i++)
                  ..._row(context, p, open, i),

                // ── Break/lunch blocks (behind bookings) ──
                for (final br in breaks)
                  _breakBlock(context, p, br, open, laneW),

                // ── Booking blocks ──
                for (final pl in placed)
                  _block(context, p, pl, open, laneW),

                // ── "Now" indicator ──
                if (isToday) _nowLine(context, open, close, laneW),
              ],
            ),
          ),
        );
      },
    );
  }

  /// A break/lunch drawn as a soft gold "blocked" band spanning the lane.
  Widget _breakBlock(BuildContext context, dynamic p, BarberBreak br, int open,
      double laneW) {
    final start = br.startOn(selectedDay);
    final top = topFor(start, open);
    final h = math.max(_slotH * br.durationMinutes / 30, 28.0);
    final end = start.add(Duration(minutes: br.durationMinutes));
    final endLabel =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
    return Positioned(
      top: top + 1.5,
      left: _gutter,
      width: laneW,
      height: h - 3,
      child: GestureDetector(
        onTap: () => onTapBreak(br),
        behavior: HitTestBehavior.opaque,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45), width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            children: [
              Icon(
                br.label.toLowerCase().contains('lunch') ||
                        br.label == L.lunchWord
                    ? Icons.restaurant_rounded
                    : Icons.local_cafe_rounded,
                size: 15,
                color: AppColors.gold,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  br.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: p.text),
                ),
              ),
              const SizedBox(width: 8),
              Text(endLabel,
                  style: GoogleFonts.nunito(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: p.textTertiary)),
              if (br.daily) ...[
                const SizedBox(width: 8),
                Icon(Icons.repeat_rounded,
                    size: 12, color: AppColors.gold.withValues(alpha: 0.8)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _row(
      BuildContext context, dynamic p, int open, int i) {
    final lineTop = _topPad + i * _slotH;
    final totalMin = open * 60 + i * 30;
    final hh = (totalMin ~/ 60) % 24;
    final mm = totalMin % 60;
    final isHour = mm == 0;
    final label =
        '${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}';
    return [
      Positioned(
        top: lineTop - 7,
        left: 0,
        width: _gutter - 10,
        child: Text(
          label,
          textAlign: TextAlign.right,
          style: GoogleFonts.nunito(
            fontSize: isHour ? 12 : 10.5,
            fontWeight: isHour ? FontWeight.w800 : FontWeight.w600,
            color: isHour ? p.textSecondary : p.textTertiary,
          ),
        ),
      ),
      Positioned(
        top: lineTop,
        left: _gutter - 2,
        right: 0,
        child: Container(
          height: 1,
          color: isHour
              ? p.border
              : p.border.withValues(alpha: 0.45),
        ),
      ),
    ];
  }

  Widget _block(BuildContext context, dynamic p, _Placed pl, int open,
      double laneW) {
    final b = pl.booking;
    final top = topFor(b.dateTime, open);
    final h = math.max(
        _slotH * b.service.durationMinutes / 30, 30.0); // min visible height
    final colW = laneW / pl.cols;
    final left = _gutter + pl.col * colW;
    final width = colW - 5;

    // Status visuals.
    late Color bg, fg, sub, bar;
    String tag = '';
    switch (b.status) {
      case BookingStatus.upcoming:
        bg = AppColors.accent;
        fg = Colors.white;
        sub = Colors.white.withValues(alpha: 0.8);
        bar = AppColors.accentDeep;
        break;
      case BookingStatus.requested:
        bg = AppColors.gold.withValues(alpha: 0.18);
        fg = p.text;
        sub = p.textSecondary;
        bar = AppColors.gold;
        tag = L.tagPending;
        break;
      case BookingStatus.completed:
        bg = p.cardAlt;
        fg = p.textSecondary;
        sub = p.textTertiary;
        bar = p.border;
        tag = L.tagDone;
        break;
      case BookingStatus.noShow:
        bg = p.cardAlt;
        fg = p.textTertiary;
        sub = p.textTertiary;
        bar = const Color(0xFFE5484D);
        tag = L.tagNoShow;
        break;
      default:
        bg = p.cardAlt;
        fg = p.textSecondary;
        sub = p.textTertiary;
        bar = p.border;
    }

    final tall = h >= 72;
    return Positioned(
      top: top + 1.5,
      left: left,
      width: width,
      height: h - 3,
      child: GestureDetector(
        onTap: () => onTapBooking(b),
        behavior: HitTestBehavior.opaque,
        child: Container(
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: bar, width: 3.5)),
          ),
          padding: const EdgeInsets.fromLTRB(9, 6, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('HH:mm').format(b.dateTime),
                    style: GoogleFonts.nunito(
                        fontSize: 11.5, fontWeight: FontWeight.w900, color: fg),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      b.clientName ?? L.youWord,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: fg),
                    ),
                  ),
                  if (tag.isNotEmpty && width > 120)
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: bar.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        tag,
                        style: GoogleFonts.nunito(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                            color: bar == AppColors.gold
                                ? AppColors.accentDeep
                                : bar),
                      ),
                    ),
                ],
              ),
              if (tall) ...[
                const SizedBox(height: 2),
                Text(
                  '${b.service.name} · ${b.service.formattedPrice}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 11, fontWeight: FontWeight.w600, color: sub),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _nowLine(BuildContext context, int open, int close, double laneW) {
    final n = DateTime.now();
    if (n.hour < open || n.hour >= close) return const SizedBox.shrink();
    final top = _topPad + ((n.hour - open) * 60 + n.minute) / 30 * _slotH;
    return Positioned(
      top: top - 4,
      left: _gutter - 8,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
                color: Color(0xFFE5484D), shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(height: 2, color: const Color(0xFFE5484D)),
          ),
        ],
      ),
    );
  }

  /// Lay overlapping bookings side-by-side (column packing per overlap cluster).
  List<_Placed> _layout(List<Booking> items) {
    final placed = <_Placed>[];
    int i = 0;
    while (i < items.length) {
      DateTime clusterEnd = end(items[i]);
      int j = i + 1;
      while (j < items.length && items[j].dateTime.isBefore(clusterEnd)) {
        final e = end(items[j]);
        if (e.isAfter(clusterEnd)) clusterEnd = e;
        j++;
      }
      final cluster = items.sublist(i, j);
      final colEnds = <DateTime>[];
      final cols = <int>[];
      for (final b in cluster) {
        int col = -1;
        for (int c = 0; c < colEnds.length; c++) {
          if (!b.dateTime.isBefore(colEnds[c])) {
            col = c;
            break;
          }
        }
        if (col == -1) {
          col = colEnds.length;
          colEnds.add(end(b));
        } else {
          colEnds[col] = end(b);
        }
        cols.add(col);
      }
      for (int k = 0; k < cluster.length; k++) {
        placed.add(_Placed(cluster[k], cols[k], colEnds.length));
      }
      i = j;
    }
    return placed;
  }
}

class _Placed {
  const _Placed(this.booking, this.col, this.cols);
  final Booking booking;
  final int col;
  final int cols;
}

// ─────────────────────────────────────────────────────────────────────────
//  Tap-a-booking detail sheet
// ─────────────────────────────────────────────────────────────────────────

class _BookingSheet extends StatelessWidget {
  const _BookingSheet({required this.booking});
  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final end = b.dateTime.add(Duration(minutes: b.service.durationMinutes));
    final (label, style) = switch (b.status) {
      BookingStatus.requested => (L.stPendingRequest, MiniPillStyle.gold),
      BookingStatus.upcoming => (L.stConfirmed, MiniPillStyle.accent),
      BookingStatus.completed => (L.stCompleted, MiniPillStyle.ink),
      BookingStatus.noShow => (L.stNoShow, MiniPillStyle.ghost),
      BookingStatus.declined => (L.stDeclined, MiniPillStyle.ghost),
      BookingStatus.cancelled => (L.stCancelled, MiniPillStyle.ghost),
    };

    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(b.clientName ?? L.youWord,
                    style: AppTypography.h2(context)),
              ),
              MiniPill(label, style: style),
            ],
          ),
          const SizedBox(height: 14),
          _SheetRow(
            icon: Icons.schedule_rounded,
            text:
                '${DateFormat('EEEE, d MMM').format(b.dateTime)}  ·  ${DateFormat('HH:mm').format(b.dateTime)}–${DateFormat('HH:mm').format(end)}',
          ),
          _SheetRow(
            icon: Icons.content_cut_rounded,
            text:
                '${b.service.name}  ·  ${b.service.formattedDuration}  ·  ${b.service.formattedPrice}',
          ),
          if (b.note != null && b.note!.isNotEmpty)
            _SheetRow(icon: Icons.sticky_note_2_rounded, text: b.note!),
          const SizedBox(height: 18),
          ..._actions(context, b),
        ],
      ),
    );
  }

  List<Widget> _actions(BuildContext context, Booking b) {
    void close() => Navigator.of(context).maybePop();
    switch (b.status) {
      case BookingStatus.requested:
        return [
          Row(
            children: [
              Expanded(
                child: _SheetBtn(
                  label: L.decline,
                  icon: Icons.close_rounded,
                  filled: false,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AppState.instance.declineBooking(b.id);
                    close();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetBtn(
                  label: L.confirmWord,
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    AppState.instance.confirmBooking(b.id);
                    close();
                  },
                ),
              ),
            ],
          ),
        ];
      case BookingStatus.upcoming:
        return [
          Row(
            children: [
              Expanded(
                child: _SheetBtn(
                  label: L.noShowAction,
                  icon: Icons.person_off_rounded,
                  filled: false,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    AppState.instance.markNoShow(b.id);
                    close();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SheetBtn(
                  label: L.markDone,
                  icon: Icons.check_rounded,
                  filled: true,
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    // Verified handshake path — stamps check-in + locks the
                    // commission (idempotent, so no double charge).
                    AppState.instance.verifyAndComplete(b.id);
                    close();
                  },
                ),
              ),
            ],
          ),
        ];
      default:
        return [
          _SheetBtn(
            label: L.closeWord,
            icon: Icons.check_rounded,
            filled: false,
            onTap: close,
          ),
        ];
    }
  }
}

class _SheetRow extends StatelessWidget {
  const _SheetRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppTypography.body(context)),
          ),
        ],
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  const _SheetBtn({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : p.cardAlt,
          borderRadius: BorderRadius.circular(15),
          border: filled ? null : Border.all(color: p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18, color: filled ? Colors.white : p.textSecondary),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: filled ? Colors.white : p.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Date strip cell + header pill
// ─────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────
//  Breaks: add button + creation sheet
// ─────────────────────────────────────────────────────────────────────────

class _AddBreakButton extends StatelessWidget {
  const _AddBreakButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: AppColors.gold),
            const SizedBox(width: 5),
            Text(L.addBreak,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.gold)),
          ],
        ),
      ),
    );
  }
}

class _BreakSheet extends StatefulWidget {
  const _BreakSheet({required this.day});
  final DateTime day;

  @override
  State<_BreakSheet> createState() => _BreakSheetState();
}

class _BreakSheetState extends State<_BreakSheet> {
  late final TextEditingController _label;
  TimeOfDay _start = const TimeOfDay(hour: 13, minute: 0);
  int _duration = 60;
  bool _daily = true;

  static const List<int> _durations = [15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: L.lunchWord);
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _start);
    if (t != null && mounted) setState(() => _start = t);
  }

  void _save() {
    AppState.instance.addBreak(
      label: _label.text.trim().isEmpty ? L.breakWord : _label.text.trim(),
      startMinutes: _start.hour * 60 + _start.minute,
      durationMinutes: _duration,
      daily: _daily,
      date: widget.day,
    );
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: p.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(Icons.coffee_rounded,
                    size: 20, color: AppColors.gold),
                const SizedBox(width: 8),
                Text(L.blockTimeOff, style: AppTypography.h2(context)),
              ],
            ),
            const SizedBox(height: 16),
            // Quick labels.
            Row(
              children: [
                _quickLabel(L.lunchWord, Icons.restaurant_rounded),
                const SizedBox(width: 8),
                _quickLabel(L.breakWord, Icons.local_cafe_rounded),
              ],
            ),
            const SizedBox(height: 12),
            _LabelField(controller: _label, hint: L.labelWord),
            const SizedBox(height: 16),
            // Start time.
            GestureDetector(
              onTap: _pickTime,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 18, color: p.textTertiary),
                    const SizedBox(width: 10),
                    Text(L.startWord,
                        style: AppTypography.body(context)),
                    const Spacer(),
                    Text(_start.format(context),
                        style: AppTypography.h4(context)
                            .copyWith(color: AppColors.accent)),
                    const SizedBox(width: 6),
                    Icon(Icons.expand_more_rounded,
                        size: 18, color: p.textTertiary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Duration chips.
            Text(L.durationMinLabel, style: AppTypography.bodySmall(context)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in _durations)
                  _choice(
                    label: '$d ${L.minShort}',
                    selected: _duration == d,
                    onTap: () => setState(() => _duration = d),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Recurrence.
            Row(
              children: [
                Expanded(
                  child: _choice(
                    label: L.everyDay,
                    icon: Icons.repeat_rounded,
                    selected: _daily,
                    onTap: () => setState(() => _daily = true),
                    big: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _choice(
                    label: L.thisDayOnly,
                    icon: Icons.event_rounded,
                    selected: !_daily,
                    onTap: () => setState(() => _daily = false),
                    big: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: L.save,
              icon: Icons.check_rounded,
              height: 54,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickLabel(String text, IconData icon) {
    final p = Paper.of(context);
    final selected = _label.text.trim() == text;
    return GestureDetector(
      onTap: () => setState(() {
        _label.text = text;
        _label.selection =
            TextSelection.collapsed(offset: _label.text.length);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withValues(alpha: 0.16)
              : p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? AppColors.gold : p.border,
              width: selected ? 1.4 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: selected ? AppColors.gold : p.textSecondary),
            const SizedBox(width: 6),
            Text(text,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? p.text : p.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _choice({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
    bool big = false,
  }) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: big ? 48 : 40,
        padding: EdgeInsets.symmetric(horizontal: big ? 12 : 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : p.card,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
              color: selected ? AppColors.accent : p.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 15,
                  color: selected ? Colors.white : p.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : p.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _LabelField extends StatelessWidget {
  const _LabelField({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: p.text),
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon:
            Icon(Icons.label_outline_rounded, size: 19, color: p.textTertiary),
        filled: true,
        fillColor: p.card,
        labelStyle: GoogleFonts.nunito(
            fontWeight: FontWeight.w600, color: p.textSecondary),
        border: border(p.border),
        enabledBorder: border(p.border),
        focusedBorder: border(AppColors.accent, 1.5),
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.date,
    required this.count,
    required this.selected,
    required this.today,
    required this.width,
    required this.onTap,
  });

  final DateTime date;
  final int count;
  final bool selected;
  final bool today;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final fg = selected ? Colors.white : p.text;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: today && !selected ? AppColors.accent : p.border,
            width: today && !selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE').format(date).toUpperCase(),
              style: GoogleFonts.nunito(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: selected ? Colors.white70 : p.textTertiary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${date.day}',
              style: GoogleFonts.nunito(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                height: 1,
                color: fg,
              ),
            ),
            const SizedBox(height: 5),
            if (count > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                constraints: const BoxConstraints(minWidth: 16),
                height: 16,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: selected ? Colors.white : AppColors.accentDeep,
                  ),
                ),
              )
            else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.nunito(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.accentDeep),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Slots view — the day as booking-style time chips (like the client
//  calendar), with pending requests accept-able right here.
// ─────────────────────────────────────────────────────────────────────────

class _SlotsView extends StatelessWidget {
  const _SlotsView({
    required this.day,
    required this.bookings,
    required this.breaks,
    required this.end,
    required this.onTapBooking,
  });

  final DateTime day;
  final List<Booking> bookings;
  final List<BarberBreak> breaks;
  final DateTime Function(Booking) end;
  final ValueChanged<Booking> onTapBooking;

  /// The booking (if any) covering a slot. Cancelled/declined/no-show don't
  /// block the chip.
  Booking? _bookingAt(DateTime slot) {
    for (final b in bookings) {
      if (b.status == BookingStatus.cancelled ||
          b.status == BookingStatus.declined ||
          b.status == BookingStatus.noShow) {
        continue;
      }
      if (!slot.isBefore(b.dateTime) && slot.isBefore(end(b))) return b;
    }
    return null;
  }

  bool _breakAt(DateTime slot) {
    final m = slot.hour * 60 + slot.minute;
    return breaks.any((br) => m >= br.startMinutes && m < br.endMinutes);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final slots = MockData.timeSlotsFor(day,
        startHour: s.workStartHour, endHour: s.workEndHour);
    final pending = bookings
        .where((b) => b.status == BookingStatus.requested)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      children: [
        // Bulk-accept every pending request on this day.
        if (pending.isNotEmpty) ...[
          PrimaryButton(
            label: L.acceptAllN(pending.length),
            icon: Icons.done_all_rounded,
            height: 50,
            onPressed: () {
              HapticFeedback.mediumImpact();
              for (final b in pending) {
                s.confirmBooking(b.id);
              }
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(SnackBar(
                  content: Text(L.acceptAllN(pending.length)),
                  behavior: SnackBarBehavior.floating,
                ));
            },
          ),
          const SizedBox(height: 14),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in slots) _chip(context, t),
          ],
        ),
      ],
    );
  }

  Widget _chip(BuildContext context, DateTime t) {
    final p = Paper.of(context);
    final b = _bookingAt(t);
    final isBreak = b == null && _breakAt(t);
    final time = DateFormat('HH:mm').format(t);

    // Free slot — plain chip, like an open slot on the client calendar.
    // Tapping it logs a walk-in for this day (the old "Navbatsiz qo'shish"
    // button now lives here, where the empty slot actually is).
    if (b == null && !isBreak) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          showWalkInSheet(context, day: day);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color: p.cardAlt,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(time,
              style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.textSecondary)),
        ),
      );
    }

    if (isBreak) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: p.textTertiary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.coffee_rounded, size: 13, color: p.textTertiary),
            const SizedBox(width: 4),
            Text(time,
                style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textTertiary)),
          ],
        ),
      );
    }

    // Booked chip: pending = gold (tap → accept sheet), confirmed = blue,
    // walk-in = green, completed = faded with a check.
    final requested = b!.status == BookingStatus.requested;
    final completed = b.status == BookingStatus.completed;
    final name = (b.clientName ?? L.youWord).split(' ').first;
    final (bg, fg) = requested
        ? (AppColors.gold.withValues(alpha: 0.18), const Color(0xFF8A6100))
        : completed
            ? (AppColors.green.withValues(alpha: 0.10), AppColors.green)
            : b.isWalkIn
                ? (AppColors.green, Colors.white)
                : (AppColors.accent, Colors.white);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        if (requested) {
          showBookingRequestSheet(context, b);
        } else {
          onTapBooking(b);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: requested
              ? Border.all(color: AppColors.gold.withValues(alpha: 0.6))
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (requested)
                  const Padding(
                    padding: EdgeInsets.only(right: 3),
                    child: Icon(Icons.hourglass_top_rounded,
                        size: 12, color: Color(0xFF8A6100)),
                  ),
                if (completed)
                  const Padding(
                    padding: EdgeInsets.only(right: 3),
                    child: Icon(Icons.check_rounded,
                        size: 12, color: AppColors.green),
                  ),
                Text(time,
                    style: GoogleFonts.nunito(
                        fontSize: 13, fontWeight: FontWeight.w900, color: fg)),
              ],
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 76),
              child: Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: fg.withValues(alpha: 0.85))),
            ),
          ],
        ),
      ),
    );
  }
}
