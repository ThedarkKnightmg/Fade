import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/format/thousands_formatter.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/booking.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'barber_avatar.dart';
import 'barber_history_screen.dart';

/// Barber "Today" — a polished, animated home: who you are, whether you're
/// online, the next booking front-and-centre, history, and today's earnings.
class BarberDashboardScreen extends StatelessWidget {
  const BarberDashboardScreen({
    super.key,
    this.onGoToRequests,
    this.onGoToSchedule,
  });

  final VoidCallback? onGoToRequests;
  final VoidCallback? onGoToSchedule;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return L.goodMorning;
    if (h < 18) return L.goodAfternoon;
    return L.goodEvening;
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
          final me = s.meBarber;
          final name = me.barber.name;
          final pending = s.incomingRequests.length;
          final now = DateTime.now();

          final todayUpcoming = s.barberToday;
          final doneToday = s.barberHistory
              .where((b) =>
                  b.status == BookingStatus.completed &&
                  _sameDay(b.dateTime, now))
              .length;
          final bookingsToday = todayUpcoming.length + doneToday;

          final agenda = s.barberAgenda
              .where((b) => b.dateTime
                  .isAfter(now.subtract(const Duration(minutes: 30))))
              .toList();
          final upNext = agenda.isEmpty ? null : agenda.first;

          return SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 150),
              children: [
                FadeSlideIn(
                  child: _Header(
                    greeting: _greeting(),
                    name: name,
                    pending: pending,
                    onGoToRequests: onGoToRequests,
                  ),
                ),
                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 70),
                  child: _AvailabilityCard(accepting: s.acceptingBookings),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 110),
                  child: _NextBookingCard(
                    booking: upNext,
                    now: now,
                    bookingsToday: bookingsToday,
                    expected: s.barberEarningsToday,
                    onGoToSchedule: onGoToSchedule,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _GoalCard(
                    earnedSom: s.barberEarnedThisWeekSom,
                    goalSom: s.weeklyGoalSom,
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 210),
                  child: _EarningsChartCard(
                    earned: s.earnedThisWeekByDay(),
                    expected: s.expectedThisWeekByDay(),
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 260),
                  child: _HistoryCard(
                    count: s.barberCompletedCount,
                    earned: s.barberTotalEarned,
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

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _reduced(BuildContext context) =>
    MediaQuery.maybeOf(context)?.disableAnimations ?? false;

// ─────────────────────────────────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
    required this.pending,
    required this.onGoToRequests,
  });
  final String greeting;
  final String name;
  final int pending;
  final VoidCallback? onGoToRequests;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final s = AppState.instance;
    return Row(
      children: [
        const _BlobAvatar(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: p.textSecondary)),
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                      color: p.text)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Language pill.
        _Pressable(
          onTap: () {
            HapticFeedback.selectionClick();
            const langs = AppLanguage.values;
            final next = langs[(langs.indexOf(s.language) + 1) % langs.length];
            s.setLanguage(next);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: _chipDeco(p),
            child: Row(
              children: [
                const Icon(Icons.language_rounded,
                    size: 17, color: AppColors.accent),
                const SizedBox(width: 5),
                Text(s.language.code,
                    style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Requests / inbox button with badge.
        _Pressable(
          onTap: () {
            HapticFeedback.selectionClick();
            onGoToRequests?.call();
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: _chipDeco(p),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.chat_bubble_outline_rounded,
                    size: 20, color: AppColors.accent),
                if (pending > 0)
                  Positioned(
                    right: -7,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      constraints:
                          const BoxConstraints(minWidth: 18, minHeight: 18),
                      decoration: const BoxDecoration(
                          color: AppColors.red, shape: BoxShape.circle),
                      child: Text('$pending',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(
                              fontSize: 10,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _chipDeco(PaperPalette p) => BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border),
        boxShadow: [
          BoxShadow(
              color: p.shadow, blurRadius: 12, offset: const Offset(0, 5)),
        ],
      );
}

/// Avatar with a slowly-morphing blue blob halo and a pulsing online dot.
class _BlobAvatar extends StatefulWidget {
  const _BlobAvatar();

  @override
  State<_BlobAvatar> createState() => _BlobAvatarState();
}

class _BlobAvatarState extends State<_BlobAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = AppState.instance.acceptingBookings;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Morphing blob halo.
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Transform.rotate(
              angle: _c.value * 2 * math.pi,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F9CFF), AppColors.accentDeep],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(30, 22),
                    topRight: Radius.elliptical(22, 30),
                    bottomLeft: Radius.elliptical(22, 30),
                    bottomRight: Radius.elliptical(30, 22),
                  ),
                ),
              ),
            ),
          ),
          const BarberAvatar(size: 46),
          // Online dot.
          if (online)
            const Positioned(
              right: 1,
              bottom: 1,
              child: _PulseDot(),
            ),
        ],
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Container(
              width: 10 + 8 * _c.value,
              height: 10 + 8 * _c.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.green.withValues(alpha: 0.4 * (1 - _c.value)),
              ),
            ),
          ),
          Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.green,
              shape: BoxShape.circle,
              border: Border.all(color: p.bg, width: 2.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Availability card
// ─────────────────────────────────────────────────────────────────────────

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({required this.accepting});
  final bool accepting;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    const green = AppColors.green;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: AppCurves.easeOutQuart,
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: BoxDecoration(
        color: accepting
            ? green.withValues(alpha: 0.12)
            : p.cardAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accepting
              ? green.withValues(alpha: 0.4)
              : p.border,
        ),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: accepting
                  ? green.withValues(alpha: 0.25)
                  : p.border,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: accepting ? green : p.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepting ? L.receivingBookings : L.youreOffline,
                  style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: accepting
                          ? (p.isDark ? green : const Color(0xFF177A48))
                          : p.text),
                ),
                const SizedBox(height: 2),
                Text(accepting ? L.receivingSub : L.offlineSub,
                    style: AppTypography.bodySmall(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(
            value: accepting,
            activeThumbColor: Colors.white,
            activeTrackColor: green,
            onChanged: (_) {
              HapticFeedback.mediumImpact();
              AppState.instance.toggleAccepting();
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Next booking card
// ─────────────────────────────────────────────────────────────────────────

class _NextBookingCard extends StatelessWidget {
  const _NextBookingCard({
    required this.booking,
    required this.now,
    required this.bookingsToday,
    required this.expected,
    required this.onGoToSchedule,
  });
  final Booking? booking;
  final DateTime now;
  final int bookingsToday;
  final double expected;
  final VoidCallback? onGoToSchedule;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      radius: 26,
      padding: const EdgeInsets.all(18),
      child: booking == null ? _empty(context) : _content(context, booking!),
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_available_rounded,
              size: 30, color: AppColors.accent),
        ),
        const SizedBox(height: 14),
        Text(L.noUpcomingBookings, style: AppTypography.h3(context)),
        const SizedBox(height: 4),
        Text(L.chairOpen,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(context)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _content(BuildContext context, Booking b) {
    final p = Paper.of(context);
    final diff = b.dateTime.difference(now);
    final countdown = diff.inMinutes <= 0
        ? L.startingNow
        : L.inHm(diff.inHours, diff.inMinutes % 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(L.nextBookingCap,
                style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: p.textTertiary)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 18, color: p.textTertiary),
            const Spacer(),
            _CountdownPill(text: countdown),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SquircleAvatar(name: b.clientName ?? L.youWord),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.clientName ?? L.youWord,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          color: p.text)),
                  const SizedBox(height: 3),
                  Text(b.service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent)),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: p.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(b.barbershop.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(context)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // Price on its own full-width line — scales to fit in any language.
        _CountUpMoney(
          value: b.service.price,
          style: GoogleFonts.nunito(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.green),
        ),
        const SizedBox(height: 16),
        _ActionButton(
          label: L.viewDetails,
          icon: Icons.arrow_forward_rounded,
          iconTrailing: true,
          filled: true,
          onTap: () => onGoToSchedule?.call(),
        ),
        const SizedBox(height: 16),
        Divider(color: p.divider, height: 1),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _StatCol(
                value: '$bookingsToday',
                label: L.bookingsTodayCap,
                color: AppColors.accent,
              ),
            ),
            Container(width: 1, height: 36, color: p.divider),
            Expanded(
              child: _StatCol(
                valueWidget: _CountUpMoney(
                  value: expected,
                  style: GoogleFonts.nunito(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.green),
                ),
                label: L.expectedCap,
                color: AppColors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CountdownPill extends StatefulWidget {
  const _CountdownPill({required this.text});
  final String text;

  @override
  State<_CountdownPill> createState() => _CountdownPillState();
}

class _CountdownPillState extends State<_CountdownPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduced(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Transform.scale(
        scale: 1 + 0.03 * _c.value,
        child: child,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D97FF), AppColors.accentDeep],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(widget.text,
                style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _SquircleAvatar extends StatelessWidget {
  const _SquircleAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4F9CFF), AppColors.accentDeep],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 5)),
        ],
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: GoogleFonts.nunito(
              fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

class _StatCol extends StatelessWidget {
  const _StatCol({
    this.value,
    this.valueWidget,
    required this.label,
    required this.color,
  });
  final String? value;
  final Widget? valueWidget;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        valueWidget ??
            Text(value!,
                style: GoogleFonts.nunito(
                    fontSize: 22, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: p.textTertiary)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  History + earnings
// ─────────────────────────────────────────────────────────────────────────

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.count,
    required this.earned,
  });
  final int count;
  final double earned;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return _Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          FadeThroughPageRoute(child: const BarberHistoryScreen()),
        );
      },
      child: GlassPanel(
        radius: 20,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.green,
                    AppColors.green.withValues(alpha: 0.7)
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.history_rounded,
                  size: 24, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L.cutHistory, style: AppTypography.h4(context)),
                  const SizedBox(height: 2),
                  Text(L.completedEarned(count, Money.som(earned)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall(context)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ── Weekly earnings goal ──
void _editGoal(BuildContext context, int current) {
  HapticFeedback.selectionClick();
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _GoalEditSheet(current: current),
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.earnedSom, required this.goalSom});
  final int earnedSom;
  final int goalSom;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final pct = goalSom <= 0 ? 0.0 : (earnedSom / goalSom).clamp(0.0, 1.0);
    final reached = goalSom > 0 && earnedSom >= goalSom;
    final toGo = goalSom - earnedSom;
    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(L.weeklyGoalCap,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: p.textTertiary)),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _editGoal(context, goalSom),
                behavior: HitTestBehavior.opaque,
                child: const Icon(Icons.edit_rounded,
                    size: 15, color: AppColors.accent),
              ),
              const Spacer(),
              Text('${(pct * 100).round()}%',
                  style: GoogleFonts.nunito(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(Money.group(earnedSom),
                    style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: p.text)),
                Text('  /  ${Money.group(goalSom)}',
                    style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 800),
              curve: AppCurves.easeOutQuart,
              builder: (_, v, __) => LinearProgressIndicator(
                value: _reduced(context) ? pct : v,
                minHeight: 9,
                backgroundColor: p.cardAlt,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        reached
                            ? Icons.celebration_rounded
                            : Icons.bolt_rounded,
                        size: 14,
                        color: AppColors.green),
                    const SizedBox(width: 4),
                    Text(
                      reached
                          ? L.goalReached
                          : (pct >= 0.5 ? L.onTrack : L.keepGoing),
                      style: GoogleFonts.nunito(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF177A48)),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (!reached)
                Flexible(
                  child: Text(
                    L.toGoLabel(Money.somValue(toGo < 0 ? 0 : toGo)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.bodySmall(context),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalEditSheet extends StatefulWidget {
  const _GoalEditSheet({required this.current});
  final int current;

  @override
  State<_GoalEditSheet> createState() => _GoalEditSheetState();
}

class _GoalEditSheetState extends State<_GoalEditSheet> {
  late final TextEditingController _ctrl = TextEditingController(
      text: ThousandsInputFormatter.groupInt(widget.current));

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _save() {
    final v = int.tryParse(_ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    AppState.instance.setWeeklyGoal(v);
    HapticFeedback.mediumImpact();
    Navigator.of(context).maybePop();
  }

  OutlineInputBorder _border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

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
            Text(L.setWeeklyGoalTitle, style: AppTypography.h2(context)),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: const [ThousandsInputFormatter()],
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, fontSize: 18, color: p.text),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                labelText: L.goalSomLabel,
                prefixIcon: const Icon(Icons.flag_rounded,
                    size: 19, color: AppColors.accent),
                filled: true,
                fillColor: p.card,
                labelStyle: GoogleFonts.nunito(
                    fontWeight: FontWeight.w600, color: p.textSecondary),
                border: _border(p.border),
                enabledBorder: _border(p.border),
                focusedBorder: _border(AppColors.accent, 1.5),
              ),
            ),
            const SizedBox(height: 18),
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
}

/// Interactive 7-day earnings bar chart with a tap-to-reveal tooltip.
class _EarningsChartCard extends StatefulWidget {
  const _EarningsChartCard({required this.earned, required this.expected});
  final List<int> earned; // Mon→Sun, completed so'm (blue)
  final List<int> expected; // Mon→Sun, confirmed-upcoming so'm (green)

  @override
  State<_EarningsChartCard> createState() => _EarningsChartCardState();
}

class _EarningsChartCardState extends State<_EarningsChartCard> {
  late int _selected;

  @override
  void initState() {
    super.initState();
    _selected = (DateTime.now().weekday - 1).clamp(0, 6);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final earned = widget.earned;
    final expected = widget.expected;
    final totals = [for (var i = 0; i < 7; i++) earned[i] + expected[i]];
    final maxV = totals.fold<int>(1, (m, v) => v > m ? v : m);
    final weekTotal = totals.fold<int>(0, (s, v) => s + v);
    final todayIdx = (DateTime.now().weekday - 1).clamp(0, 6);
    final monday = DateTime.now().subtract(Duration(days: todayIdx));
    final reduced = _reduced(context);
    final selTotal = totals[_selected];

    return GlassPanel(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(L.tabThisWeekCap.toUpperCase(),
                  style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: p.textTertiary)),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(Money.somValue(weekTotal),
                      maxLines: 1,
                      style: GoogleFonts.nunito(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.accent)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 150,
            child: LayoutBuilder(
              builder: (ctx, c) {
                final slotW = c.maxWidth / 7;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: _DayBar(
                                earned: earned[i],
                                expected: expected[i],
                                maxV: maxV,
                                selected: _selected == i,
                                isToday: i == todayIdx,
                                weekday: DateFormat('EEE')
                                    .format(monday.add(Duration(days: i))),
                                reduced: reduced,
                                delayMs: i * 70,
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selected = i);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (selTotal > 0)
                      Positioned(
                        left: _selected * slotW + slotW / 2,
                        top: -6,
                        child: FractionalTranslation(
                          translation: const Offset(-0.5, 0),
                          child: _BarTooltip(text: Money.somValue(selTotal)),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          // Legend — what the two stacked colours mean.
          Row(
            children: [
              _LegendDot(color: AppColors.accent, label: L.earnedLegend),
              const SizedBox(width: 18),
              _LegendDot(color: AppColors.green, label: L.expectedLegend),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: p.textSecondary)),
      ],
    );
  }
}

class _BarTooltip extends StatelessWidget {
  const _BarTooltip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Text(text,
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.nunito(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white)),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.earned,
    required this.expected,
    required this.maxV,
    required this.selected,
    required this.isToday,
    required this.weekday,
    required this.reduced,
    required this.delayMs,
    required this.onTap,
  });
  final int earned;
  final int expected;
  final int maxV;
  final bool selected;
  final bool isToday;
  final String weekday;
  final bool reduced;
  final int delayMs;
  final VoidCallback onTap;

  static const double _barArea = 104;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final total = earned + expected;
    final totalH = (maxV <= 0 ? 0.0 : total / maxV * _barArea)
        .clamp(total > 0 ? 10.0 : 4.0, _barArea);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: reduced ? totalH : 0, end: totalH),
            duration: Duration(milliseconds: 600 + delayMs),
            curve: AppCurves.easeOutQuart,
            builder: (_, h, __) {
              if (total <= 0) {
                return Container(
                  width: 18,
                  height: 4,
                  decoration: BoxDecoration(
                      color: p.border, borderRadius: BorderRadius.circular(4)),
                );
              }
              final expectedH = h * (expected / total);
              return Opacity(
                opacity: selected ? 1 : 0.78,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(7),
                  child: SizedBox(
                    width: 18,
                    height: h,
                    child: Column(
                      children: [
                        // Expected (green) stacks on top of earned (blue).
                        if (expected > 0)
                          Container(height: expectedH, color: AppColors.green),
                        if (earned > 0)
                          Expanded(child: Container(color: AppColors.accent)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(weekday,
              style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: (selected || isToday)
                      ? AppColors.accent
                      : p.textTertiary)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
//  Shared: count-up money, action button, pressable
// ─────────────────────────────────────────────────────────────────────────

class _CountUpMoney extends StatelessWidget {
  const _CountUpMoney({required this.value, required this.style});
  final double value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    Widget txt(double v) =>
        Text(Money.som(v), style: style, maxLines: 1, softWrap: false);
    final child = _reduced(context)
        ? txt(value)
        : TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value),
            duration: const Duration(milliseconds: 800),
            curve: AppCurves.easeOutQuart,
            builder: (_, v, __) => txt(v),
          );
    // Scale-to-fit so long so'm amounts never wrap mid-number in any language.
    return FittedBox(
        fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: child);
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.iconTrailing = false,
  });
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final bool iconTrailing;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final fg = filled ? Colors.white : AppColors.accent;
    final children = <Widget>[
      Icon(icon, size: 18, color: fg),
      const SizedBox(width: 7),
      Text(label,
          style: GoogleFonts.nunito(
              fontSize: 15, fontWeight: FontWeight.w800, color: fg)),
    ];
    return _Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 54,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: filled ? AppColors.accent : p.card,
          borderRadius: BorderRadius.circular(16),
          border: filled ? null : Border.all(color: p.border, width: 1.4),
          boxShadow: filled
              ? [
                  BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconTrailing ? children.reversed.toList() : children,
        ),
      ),
    );
  }
}

/// Wraps a tappable in a quick press-scale for tactile feedback.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 110),
        curve: AppCurves.easeOutQuart,
        child: widget.child,
      ),
    );
  }
}
