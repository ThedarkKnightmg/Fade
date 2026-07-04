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

/// Barber "Today" — a calm, flat home: who you are, whether you're online,
/// the next booking as the single blue hero, weekly goal, earnings chart and
/// history — all on clean white cards over the plain canvas.
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
                const SizedBox(height: 12),
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
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: _GoalSection(
                    earnedSom: s.barberEarnedThisWeekSom,
                    goalSom: s.weeklyGoalSom,
                  ),
                ),
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 210),
                  child: _EarningsSection(
                    earned: s.earnedThisWeekByDay(),
                    expected: s.expectedThisWeekByDay(),
                  ),
                ),
                const SizedBox(height: 12),
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
//  Section title — sits OUTSIDE the card, Yandex-style.
// ─────────────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3(context)),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

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
        const _HeaderAvatar(),
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: clayDecoration(p, radius: 999),
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
        Stack(
          clipBehavior: Clip.none,
          children: [
            CircleBtn(
              icon: Icons.chat_bubble_outline_rounded,
              size: 44,
              iconSize: 20,
              iconColor: AppColors.accent,
              onTap: () {
                HapticFeedback.selectionClick();
                onGoToRequests?.call();
              },
            ),
            if (pending > 0)
              Positioned(
                right: -3,
                top: -4,
                child: IgnorePointer(
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
              ),
          ],
        ),
      ],
    );
  }
}

/// Avatar in a quiet white ring, with a pulsing online dot.
class _HeaderAvatar extends StatelessWidget {
  const _HeaderAvatar();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final online = AppState.instance.acceptingBookings;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: p.card,
              border: Border.all(color: p.border),
              boxShadow: [
                BoxShadow(
                    color: p.shadow,
                    blurRadius: 18,
                    spreadRadius: -4,
                    offset: const Offset(0, 8)),
              ],
            ),
            alignment: Alignment.center,
            child: const BarberAvatar(size: 48),
          ),
          // Online dot.
          if (online)
            const Positioned(
              right: 0,
              bottom: 0,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      decoration: clayDecoration(p, radius: 20),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: AppCurves.easeOutQuart,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accepting ? green.withValues(alpha: 0.12) : p.cardAlt,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.power_settings_new_rounded,
                size: 21, color: accepting ? green : p.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  accepting ? L.receivingBookings : L.youreOffline,
                  style: AppTypography.h4(context),
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
//  Next booking — the ONE blue hero on this screen
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
    if (booking == null) return _empty(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4AA3FF), Color(0xFF1E6FE0)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.35),
              blurRadius: 22,
              spreadRadius: -6,
              offset: const Offset(0, 12)),
        ],
      ),
      child: _content(context, booking!),
    );
  }

  Widget _empty(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: clayDecoration(p, radius: 24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available_rounded,
                size: 28, color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          Text(L.noUpcomingBookings, style: AppTypography.h3(context)),
          const SizedBox(height: 4),
          Text(L.chairOpen,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(context)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, Booking b) {
    final diff = b.dateTime.difference(now);
    final countdown = diff.inMinutes <= 0
        ? L.startingNow
        : L.inHm(diff.inHours, diff.inMinutes % 60);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(L.nextBookingCap,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.nunito(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: Colors.white.withValues(alpha: 0.8))),
            ),
            const SizedBox(width: 8),
            _CountdownPill(text: countdown),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FrostAvatar(name: b.clientName ?? L.youWord),
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
                          color: Colors.white)),
                  const SizedBox(height: 3),
                  Text(b.service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9))),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7)),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(b.barbershop.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.nunito(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.7))),
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
              fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 16),
        _HeroButton(
          label: L.viewDetails,
          onTap: () => onGoToSchedule?.call(),
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: Colors.white.withValues(alpha: 0.25)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _HeroStat(
                value: '$bookingsToday',
                label: L.bookingsTodayCap,
              ),
            ),
            Container(
                width: 1,
                height: 36,
                color: Colors.white.withValues(alpha: 0.25)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: _HeroStat(
                  valueWidget: _CountUpMoney(
                    value: expected,
                    style: GoogleFonts.nunito(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white),
                  ),
                  label: L.expectedCap,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Frosted-glass countdown chip on the hero — keeps its gentle pulse.
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schedule_rounded, size: 14, color: Colors.white),
            const SizedBox(width: 5),
            Text(widget.text,
                style: GoogleFonts.nunito(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

/// Frosted-glass initial avatar on the hero.
class _FrostAvatar extends StatelessWidget {
  const _FrostAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(initial,
          style: GoogleFonts.nunito(
              fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

/// White pill CTA on the blue hero.
class _HeroButton extends StatelessWidget {
  const _HeroButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.accentDeep)),
            const SizedBox(width: 7),
            const Icon(Icons.arrow_forward_rounded,
                size: 18, color: AppColors.accentDeep),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    this.value,
    this.valueWidget,
    required this.label,
  });
  final String? value;
  final Widget? valueWidget;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        valueWidget ??
            Text(value!,
                style: GoogleFonts.nunito(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
        const SizedBox(height: 2),
        Text(label,
            style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Colors.white.withValues(alpha: 0.7))),
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
    return PaperCard(
      radius: 20,
      padding: const EdgeInsets.all(14),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          FadeThroughPageRoute(child: const BarberHistoryScreen()),
        );
      },
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.history_rounded,
                size: 21, color: AppColors.green),
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

/// Title outside the card (Yandex pattern) with the edit affordance beside it.
class _GoalSection extends StatelessWidget {
  const _GoalSection({required this.earnedSom, required this.goalSom});
  final int earnedSom;
  final int goalSom;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          L.setWeeklyGoalTitle,
          trailing: GestureDetector(
            onTap: () => _editGoal(context, goalSom),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child:
                  Icon(Icons.edit_rounded, size: 16, color: AppColors.accent),
            ),
          ),
        ),
        _GoalCard(earnedSom: earnedSom, goalSom: goalSom),
      ],
    );
  }
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: clayDecoration(p, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: FittedBox(
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
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: p.textTertiary)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${(pct * 100).round()}%',
                  style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent)),
            ],
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
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
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
                          color: p.isDark
                              ? AppColors.green
                              : const Color(0xFF177A48)),
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

/// Title outside the card + the interactive 7-day earnings chart.
class _EarningsSection extends StatelessWidget {
  const _EarningsSection({required this.earned, required this.expected});
  final List<int> earned;
  final List<int> expected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(L.tabThisWeekCap),
        _EarningsChartCard(earned: earned, expected: expected),
      ],
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

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: clayDecoration(p, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(Money.somValue(weekTotal),
                maxLines: 1,
                style: GoogleFonts.nunito(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent)),
          ),
          const SizedBox(height: 16),
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
//  Shared: count-up money, pressable
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
