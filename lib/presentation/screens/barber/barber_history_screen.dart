import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';

/// The barber's completed-cut history: a summary + a time-filtered list.
class BarberHistoryScreen extends StatefulWidget {
  const BarberHistoryScreen({super.key});

  @override
  State<BarberHistoryScreen> createState() => _BarberHistoryScreenState();
}

class _BarberHistoryScreenState extends State<BarberHistoryScreen> {
  int _tab = 0; // 0 = all time, 1 = this month, 2 = this week

  DateTime? _since() {
    final n = DateTime.now();
    switch (_tab) {
      case 1:
        return DateTime(n.year, n.month, 1);
      case 2:
        return DateTime(n.year, n.month, n.day)
            .subtract(Duration(days: n.weekday - 1));
      default:
        return null;
    }
  }

  /// Deterministic per-cut rating (4.0–5.0) so totals stay stable.
  double _rating(Booking b) => 4.0 + (b.id.hashCode.abs() % 11) / 10.0;

  String _whenLabel(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    final time = DateFormat('HH:mm').format(dt);
    if (diff == 0) return '${L.today}, $time';
    if (diff == 1) return '${L.yesterdayWord}, $time';
    return '${DateFormat('d MMM').format(dt)}, $time';
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final list = AppState.instance.completedHistory(since: _since());
          final count = list.length;
          final earnedSom =
              list.fold(0, (s, b) => s + Money.toSom(b.service.price));
          final avg = list.isEmpty
              ? 0.0
              : list.map(_rating).reduce((a, b) => a + b) / list.length;

          return SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header.
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 20, 0),
                  child: Row(
                    children: [
                      CircleBtn(
                        icon: Icons.arrow_back_rounded,
                        size: 42,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(L.cutHistory,
                                style: AppTypography.h2(context)),
                            Text(L.everythingCompleted,
                                style: AppTypography.bodySmall(context)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tabs.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _Tabs(
                    index: _tab,
                    labels: [L.tabAllTime, L.tabThisMonth, L.tabThisWeekCap],
                    onChanged: (i) => setState(() => _tab = i),
                  ),
                ),
                const SizedBox(height: 16),
                // Summary.
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SummaryCard(
                    count: count,
                    earnedSom: earnedSom,
                    avg: avg,
                  ),
                ),
                const SizedBox(height: 16),
                // List.
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history_rounded,
                                  size: 40, color: p.textTertiary),
                              const SizedBox(height: 10),
                              Text(L.noCompletedYet,
                                  style: AppTypography.bodySmall(context)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => FadeSlideIn(
                            delay: Duration(milliseconds: 40 * i),
                            child: _HistoryRow(
                              booking: list[i],
                              rating: _rating(list[i]),
                              when: _whenLabel(list[i].dateTime),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs(
      {required this.index, required this.labels, required this.onChanged});
  final int index;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: AppCurves.easeOutQuart,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: index == i ? p.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: index == i
                        ? [
                            BoxShadow(
                                color: p.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 3))
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[i],
                    style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: index == i ? AppColors.accent : p.textSecondary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.count, required this.earnedSom, required this.avg});
  final int count;
  final int earnedSom;
  final double avg;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _Metric(
              value: Text('$count', style: AppTypography.h1(context)),
              label: L.completedCap,
            ),
          ),
          Container(width: 1, height: 44, color: p.divider),
          Expanded(
            flex: 2,
            child: _Metric(
              value: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(Money.group(earnedSom),
                    maxLines: 1,
                    style: GoogleFonts.nunito(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: p.text)),
              ),
              sub: "so'm",
              label: L.earnedCap,
            ),
          ),
          Container(width: 1, height: 44, color: p.divider),
          Expanded(
            child: _Metric(
              value: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded,
                      size: 18, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text(avg.toStringAsFixed(2),
                      style: AppTypography.h2(context)),
                ],
              ),
              label: L.avgRatingCap,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.sub});
  final Widget value;
  final String label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Column(
      children: [
        value,
        if (sub != null)
          Text(sub!,
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: p.textTertiary)),
        const SizedBox(height: 3),
        Text(label,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: p.textTertiary)),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow(
      {required this.booking, required this.rating, required this.when});
  final Booking booking;
  final double rating;
  final String when;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = booking;
    final som = Money.toSom(b.service.price);
    final stars = rating.round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(b.service.icon, size: 22, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.h4(context)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Icon(Icons.star_rounded,
                          size: 13,
                          color: i < stars
                              ? AppColors.gold
                              : p.border),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('· ${b.clientName ?? L.youWord}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(when, style: AppTypography.caption(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('+${Money.group(som)}',
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green)),
              Text("SO'M",
                  style: GoogleFonts.nunito(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: p.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}
