import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/calendar_link.dart';
import '../../../data/app_state.dart';
import '../../../data/hair_data.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/hairstyle.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import '../game/games_sheet.dart';

/// The peak-end moment: a stamp + confetti, a *variable* surprise reward
/// (the slot-machine dopamine hit), and the loyalty punch-card advancing —
/// so the user leaves wanting the next cut. Engineered to be the most
/// satisfying screen in the app.
class BookingConfirmationScreen extends StatefulWidget {
  const BookingConfirmationScreen({super.key, required this.booking});

  final Booking booking;

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  late final Animation<double> _scale = CurvedAnimation(
    parent: _stamp,
    curve: Curves.elasticOut,
  );

  Hairstyle? _look;
  late final _Reward _reward = _pickReward(widget.booking.id);

  @override
  void initState() {
    super.initState();
    final id = AppState.instance.desiredStyleId;
    if (id != null) {
      _look = HairData.byId(id);
      AppState.instance.clearDesiredStyle();
    }
    // The reward is EARNED when the visit is completed (AppState._awardVisitPerk
    // uses the same deterministic roll on this booking id) — NOT on the request,
    // so passes can't be farmed by re-booking without ever showing up.
  }

  @override
  void dispose() {
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final b = widget.booking;
    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  ScaleTransition(
                    scale: _scale,
                    child: Container(
                      width: 104,
                      height: 104,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.45),
                            blurRadius: 28,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 52, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 22),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 140),
                    child: Text(
                      b.status == BookingStatus.requested
                          ? L.requestSent
                          : L.bookedExcl,
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: p.text,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: Text(
                      b.status == BookingStatus.requested
                          ? L.sentToBarber(b.barber.name.split(' ').first)
                          : L.chairLockedIn,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall(context),
                    ),
                  ),
                  const SizedBox(height: 22),
                  // --- Variable reward (the dopamine hit) ---
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 320),
                    child: _RewardReveal(reward: _reward),
                  ),
                  const SizedBox(height: 16),
                  // --- The booking ticket ---
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 420),
                    child: PaperCard(
                      radius: 26,
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _Line(
                            icon: Icons.event_rounded,
                            title:
                                DateFormat('EEEE, d MMMM').format(b.dateTime),
                            sub: DateFormat('HH:mm').format(b.dateTime),
                            accent: true,
                          ),
                          const SizedBox(height: 14),
                          _Line(
                            icon: Icons.content_cut_rounded,
                            title: L.tr(b.service.name),
                            sub:
                                '${b.service.formattedDuration} · ${b.service.formattedPrice}',
                          ),
                          const SizedBox(height: 14),
                          _Line(
                            icon: Icons.person_rounded,
                            title: b.barber.name,
                            sub: L.tr(b.barber.specialty),
                          ),
                          if (_look != null) ...[
                            const SizedBox(height: 14),
                            _Line(
                              icon: _look!.icon,
                              title: _look!.name,
                              sub: L.requestedLook,
                            ),
                          ],
                          const SizedBox(height: 14),
                          _Line(
                            icon: Icons.storefront_rounded,
                            title: b.barbershop.name,
                            sub: b.barbershop.address,
                          ),
                          const SizedBox(height: 16),
                          Divider(color: p.divider, thickness: 1.4),
                          const SizedBox(height: 10),
                          Text(
                            '${L.bkNoteNo} ${b.id.length > 12 ? b.id.substring(2, 12) : b.id.substring(2)}',
                            style: GoogleFonts.nunito(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: p.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // --- Loyalty advance (goal gradient at the peak) ---
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 520),
                    child: const _LoyaltyMini(),
                  ),
                  const SizedBox(height: 16),
                  // The chair is booked — the next question is "so what now?".
                  // Answering it here, at the peak, is what turns a one-shot
                  // booking into time spent in the app. A full card (not a
                  // third stacked ghost button) so it actually gets seen.
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 580),
                    child: const GameInviteCard(),
                  ),
                  const SizedBox(height: 26),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 600),
                    child: PrimaryButton(
                      label: L.doneWord,
                      height: 62,
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 660),
                    child: PrimaryButton(
                      label: L.addToCalendar,
                      height: 56,
                      style: PrimaryButtonStyle.ghost,
                      icon: Icons.calendar_month_rounded,
                      onPressed: () => addBookingToCalendar(context, b),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Positioned.fill(child: ConfettiBurst()),
        ],
      ),
    );
  }
}

/// A surprise perk. Variable-ratio: mostly small, occasionally a real prize —
/// which is exactly what makes a reward habit-forming (the slot-machine effect).
class _Reward {
  const _Reward(this.id, this.emoji, this.title, this.sub, this.color);

  /// AppState perk id ('priority' | 'skip' | 'double'); empty = the loyalty
  /// filler, which isn't a stored pass.
  final String id;
  final String emoji;
  final String title;
  final String sub;
  final Color color;
}

_Reward _pickReward(String id) {
  final roll = id.hashCode.abs() % 100;
  if (roll < 8) {
    return _Reward('priority', '🔓', L.bkPriorityPass,
        L.bkPriorityPassSub, const Color(0xFFE0467E));
  }
  if (roll < 22) {
    return _Reward('skip', '⚡', L.bkSkipQueuePass,
        L.bkSkipQueueSub, const Color(0xFFE0683C));
  }
  if (roll < 42) {
    return _Reward('double', '⭐', L.perkDoublePoints,
        L.bkEarnedThisBooking, const Color(0xFFE0A12E));
  }
  return _Reward('', '✂️', L.bkPlusOnePerk,
      L.bkLoyaltyProgressSaved, AppColors.accent);
}

class _RewardReveal extends StatelessWidget {
  const _RewardReveal({required this.reward});

  final _Reward reward;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            reward.color.withValues(alpha: 0.24),
            reward.color.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(color: reward.color.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: reward.color.withValues(alpha: 0.30),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(reward.emoji, style: const TextStyle(fontSize: 34)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.bkYouJustEarned,
                  style: GoogleFonts.nunito(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                    color: reward.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reward.title,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: p.text,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 1),
                Text(reward.sub, style: AppTypography.bodySmall(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact goal-gradient punch card — reinforces "you're almost to your next
/// perk" at the exact moment satisfaction peaks.
class _LoyaltyMini extends StatelessWidget {
  const _LoyaltyMini();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // THE Fade-points number, same everywhere (badge, profile, sheet, ticket).
    const goal = AppState.fadePointsGoal;
    final cuts = AppState.instance.fadePoints;
    final into = cuts % goal;
    final unlocked = into == 0;
    final remaining = unlocked ? 0 : goal - into;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.cardAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded,
                  size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  unlocked
                      ? L.bkPerkUnlocked
                      : L.bkCutsToNextPerk(remaining),
                  style: GoogleFonts.nunito(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  ),
                ),
              ),
              Text(
                L.bkCutsCount(cuts),
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFE0A12E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < goal; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: 8,
                    decoration: BoxDecoration(
                      color: (unlocked || i < into)
                          ? AppColors.gold
                          : p.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({
    required this.icon,
    required this.title,
    required this.sub,
    this.accent = false,
  });

  final IconData icon;
  final String title;
  final String sub;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: accent ? AppColors.accent : p.cardAlt,
            borderRadius: BorderRadius.circular(14),
            border: accent ? null : Border.all(color: p.border),
          ),
          child: Icon(icon,
              size: 19, color: accent ? Colors.white : p.textSecondary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.h4(context)),
              const SizedBox(height: 1),
              Text(
                sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
