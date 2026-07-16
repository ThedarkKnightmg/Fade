import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/photo/photo_source.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../core/animations/app_animations.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'barber_workplace_screen.dart';

/// First-run barber setup — welcome → weekly earning goal → photos → ready,
/// then it flips the account into barber mode. Shown once (guarded by
/// [AppState.barberOnboarded]); the "Become a barber" card opens it.
class BarberIntroScreen extends StatefulWidget {
  const BarberIntroScreen({super.key});

  @override
  State<BarberIntroScreen> createState() => _BarberIntroScreenState();
}

class _BarberIntroScreenState extends State<BarberIntroScreen> {
  final PageController _pc = PageController();
  int _page = 0;
  static const int _last = 3;

  int _goal = AppState.instance.weeklyGoalSom;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page >= _last) {
      // Photos are the whole pitch: a client scrolling the barber feed is
      // choosing a face and a fade, so a chair with neither can't compete.
      // Required, not skippable — which is also why there's no Skip button.
      final missing = _missingPhotos();
      if (missing != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(missing),
            behavior: SnackBarBehavior.floating,
          ));
        return;
      }
      return _finish();
    }
    _pc.nextPage(
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  /// Why the barber can't continue yet, or null when they can.
  String? _missingPhotos() {
    final s = AppState.instance;
    if (s.userPhoto == null) return L.biNeedPhoto;
    if (s.shopPhotos.isEmpty) return L.biNeedWork;
    return null;
  }

  void _finish() {
    // Save the goal, then choose the workplace — that step attaches the barber
    // to a shop (or creates one) and flips into barber mode.
    AppState.instance.setWeeklyGoal(_goal);
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      FadeThroughPageRoute(child: const BarberWorkplaceScreen()),
    );
  }

  String get _cta => _page == 0 ? L.biStart : L.biNext;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: back + progress dots + skip (on the photos step).
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  CircleBtn(
                    icon: _page == 0
                        ? Icons.close_rounded
                        : Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () {
                      if (_page == 0) {
                        Navigator.of(context).maybePop();
                      } else {
                        _pc.previousPage(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic);
                      }
                    },
                  ),
                  const Spacer(),
                  _Dots(count: _last + 1, index: _page),
                  const Spacer(),
                  // Balances the 42px back button so the dots stay centred.
                  // This used to hold a "Skip" TextButton — 42px can't fit
                  // "O'tkazib yuborish", so it wrapped to one letter per line,
                  // made this row ten lines tall, and shoved the page's hero
                  // off the top of the screen. Photos are required now, so the
                  // button is gone rather than merely widened.
                  const SizedBox(width: 42),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pc,
                onPageChanged: (i) => setState(() => _page = i),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _WelcomePage(),
                  const _MoneyPage(),
                  _GoalPage(
                    goal: _goal,
                    onChanged: (v) => setState(() => _goal = v),
                  ),
                  const _PhotosPage(),
                ],
              ),
            ),
            // Bottom CTA.
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: PrimaryButton(
                label: _cta,
                icon: _page == _last
                    ? Icons.arrow_forward_rounded
                    : Icons.arrow_forward_rounded,
                height: 56,
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? AppColors.accent : p.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.icon, required this.title, required this.sub});
  final IconData icon;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4AA3FF), Color(0xFF1E6FE0)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.35),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 22),
        Text(title, style: AppTypography.h1(context)),
        const SizedBox(height: 8),
        Text(sub,
            style:
                AppTypography.body(context).copyWith(height: 1.4)),
      ],
    );
  }
}

class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(
            icon: Icons.content_cut_rounded,
            title: L.biWelcomeTitle,
            sub: L.biWelcomeSub,
          ),
          const SizedBox(height: 30),
          // The same 3D stickers as the home tiles, so a barber's first screen
          // speaks the app's own visual language. Each one actually depicts its
          // line — the page used to show three identical blue ticks, which say
          // nothing and made the list read as filler.
          _Perk(
            sticker: 'assets/tiles/cuts.png',
            tint: AppColors.accent,
            text: L.biPerkChair,
          ),
          const SizedBox(height: 14),
          _Perk(
            sticker: 'assets/tiles/book.png',
            tint: AppColors.green,
            text: L.biPerkBookings,
          ),
          const SizedBox(height: 14),
          _Perk(
            sticker: 'assets/tiles/map.png',
            tint: AppColors.gold,
            text: L.biPerkMap,
          ),
        ],
      ),
    );
  }
}

class _Perk extends StatelessWidget {
  const _Perk({
    required this.sticker,
    required this.tint,
    required this.text,
  });

  final String sticker;
  final Color tint;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          // Decoded a touch above its 44px draw size so the sticker stays crisp
          // on a 3x screen without holding a full-res bitmap per row.
          child: Image.asset(
            sticker,
            cacheWidth: 160,
            filterQuality: FilterQuality.high,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall(context)
                .copyWith(color: p.text, height: 1.35),
          ),
        ),
      ],
    );
  }
}

/// Page 2 — plain-language money & commissions, so a barber knows exactly how
/// he gets paid before he ever takes a booking.
class _MoneyPage extends StatelessWidget {
  const _MoneyPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(
            icon: Icons.account_balance_wallet_rounded,
            title: L.biMoneyTitle,
            sub: L.biMoneySub,
          ),
          const SizedBox(height: 28),
          _MoneyRow(
            index: 0,
            icon: Icons.savings_rounded,
            tint: AppColors.green,
            title: L.biMoneyKeepTitle,
            sub: L.biMoneyKeepSub,
          ),
          const SizedBox(height: 12),
          // The badge reads 95%, not 5% — the number that matters to a barber
          // is what he takes home, and anchoring on the fee makes a small fee
          // look like the headline. The 5% is still stated plainly in the sub:
          // framing what's true is fair game, hiding it isn't.
          _MoneyRow(
            index: 1,
            icon: Icons.percent_rounded,
            tint: AppColors.green,
            title: L.biMoneyCommTitle,
            sub: L.biMoneyCommSub,
            badge: '95%',
          ),
          const SizedBox(height: 12),
          _MoneyRow(
            index: 2,
            icon: Icons.replay_rounded,
            tint: AppColors.gold,
            title: L.biMoneyCashTitle,
            sub: L.biMoneyCashSub,
          ),
          const SizedBox(height: 12),
          _MoneyRow(
            index: 3,
            icon: Icons.receipt_long_rounded,
            tint: AppColors.accent,
            title: L.biMoneyWalletTitle,
            sub: L.biMoneyWalletSub,
          ),
          const SizedBox(height: 12),
          _MoneyRow(
            index: 4,
            icon: Icons.rocket_launch_rounded,
            tint: AppColors.gold,
            title: L.biMoneyBoostTitle,
            sub: L.biMoneyBoostSub,
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({
    required this.index,
    required this.icon,
    required this.tint,
    required this.title,
    required this.sub,
    this.badge,
  });
  final int index;
  final IconData icon;
  final Color tint;
  final String title;
  final String sub;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return FadeSlideIn(
      delay: Duration(milliseconds: 80 + index * 70),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: clayDecoration(p, radius: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 22, color: tint),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: p.text,
                            )),
                      ),
                      if (badge != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: tint.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(badge!,
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                                color: tint,
                              )),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(sub,
                      style: AppTypography.bodySmall(context)
                          .copyWith(height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalPage extends StatelessWidget {
  const _GoalPage({required this.goal, required this.onChanged});
  final int goal;
  final ValueChanged<int> onChanged;

  static const List<int> _chips = [
    1500000,
    2000000,
    2800000,
    3500000,
    5000000,
  ];

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Hero(
            icon: Icons.savings_rounded,
            title: L.biGoalTitle,
            sub: L.biGoalSub,
          ),
          const SizedBox(height: 30),
          // Big live figure.
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: Money.group(goal),
                      style: GoogleFonts.nunito(
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: p.text),
                    ),
                    TextSpan(
                      text: "  so'm",
                      style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: p.textTertiary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(L.biGoalSub, style: AppTypography.caption(context)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in _chips)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(c);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    decoration: BoxDecoration(
                      color: goal == c
                          ? AppColors.accent
                          : p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: goal == c ? AppColors.accent : p.border,
                      ),
                    ),
                    child: Text(
                      '${(c / 1000000).toStringAsFixed(c % 1000000 == 0 ? 0 : 1)}M',
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: goal == c ? Colors.white : p.text,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // Fine stepper (± 100k).
          Row(
            children: [
              _StepBtn(
                  icon: Icons.remove_rounded,
                  onTap: goal > 500000
                      ? () {
                          HapticFeedback.selectionClick();
                          onChanged(goal - 100000);
                        }
                      : null),
              const SizedBox(width: 10),
              Expanded(
                child: Text('± 100 000',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall(context)),
              ),
              const SizedBox(width: 10),
              _StepBtn(
                  icon: Icons.add_rounded,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onChanged(goal + 100000);
                  }),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final on = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 46,
        decoration: BoxDecoration(
          color: on ? AppColors.accent.withValues(alpha: 0.12) : p.cardAlt,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon,
            size: 22, color: on ? AppColors.accent : p.textTertiary),
      ),
    );
  }
}

/// A section heading that carries its own state: "Required" until it's filled,
/// then a green tick. Says what's needed before the barber taps Continue and
/// gets told off, rather than after.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.done});

  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: AppTypography.h4(context)),
        const SizedBox(width: 8),
        if (done)
          const Icon(Icons.check_circle_rounded, size: 17, color: AppColors.green)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              L.biRequired,
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
              ),
            ),
          ),
      ],
    );
  }
}

class _PhotosPage extends StatelessWidget {
  const _PhotosPage();

  Future<void> _profile() async {
    final bytes = await capturePhoto();
    if (bytes != null) AppState.instance.setUserPhoto(bytes);
  }

  Future<void> _work() async {
    final bytes = await capturePhoto();
    if (bytes != null) AppState.instance.addShopPhoto(bytes);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final s = AppState.instance;
        final photo = s.userPhoto;
        final work = s.shopPhotos;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Hero(
                icon: Icons.photo_camera_rounded,
                title: L.biPhotoTitle,
                sub: L.biPhotoSub,
              ),
              const SizedBox(height: 26),
              _SectionLabel(text: L.biYourPhoto, done: photo != null),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _profile,
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.card,
                    border: Border.all(
                        color: photo == null ? p.border : AppColors.accent,
                        width: photo == null ? 1 : 2),
                    image: photo == null
                        ? null
                        : DecorationImage(
                            image: MemoryImage(photo), fit: BoxFit.cover),
                  ),
                  child: photo == null
                      ? const Icon(Icons.add_a_photo_rounded,
                          size: 26, color: AppColors.accent)
                      : null,
                ),
              ),
              const SizedBox(height: 26),
              _SectionLabel(text: L.biYourWork, done: work.isNotEmpty),
              const SizedBox(height: 10),
              SizedBox(
                height: 92,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var i = 0; i < work.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(work[i],
                              width: 92, height: 92, fit: BoxFit.cover),
                        ),
                      ),
                    GestureDetector(
                      onTap: _work,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color:
                                  AppColors.accent.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.add_rounded,
                            size: 28, color: AppColors.accent),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

