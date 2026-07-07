import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'vip_explainer_screen.dart';

/// VIP — the subscription product, fully on its own.
/// One price a month for always-on premium placement: gold map pin, top of
/// search, premium badge, top of the roster. The commitment tier for barbers
/// who want to stay at the top without thinking about it. (Subscription is a
/// provider-handoff STUB — no card data, no real money.)
class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  static String _som(int v) => "${Money.group(v)} so'm";

  static List<_Perk> get _perks => [
        _Perk(Icons.location_on_rounded, L.vipPerkGoldPin, L.vipPerkGoldPinSub),
        _Perk(Icons.trending_up_rounded, L.vipPerkTopSearch,
            L.vipPerkTopSearchSub),
        _Perk(Icons.workspace_premium_rounded, L.vipPerkBadgePhoto,
            L.vipPerkBadgePhotoSub),
        _Perk(Icons.emoji_events_rounded, L.vipPerkRosterTop,
            L.vipPerkRosterTopSub),
      ];

  void _subscribe(BuildContext context) {
    // Explain VIP with an animated walkthrough first, then let that screen
    // lead into the payment sheet — never charge before it's understood.
    Navigator.of(context).push(
      FadeThroughPageRoute(child: const VipExplainerScreen()),
    );
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
          return SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      CircleBtn(
                        icon: Icons.arrow_back_rounded,
                        size: 42,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Text(L.tierVipTitle, style: AppTypography.h2(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      FadeSlideIn(child: const _VipHero()),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: Text(L.orGoUnlimited,
                            style: AppTypography.h3(context)),
                      ),
                      const SizedBox(height: 12),
                      // The four premium perks.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: clayDecoration(p, radius: 22),
                          child: Column(
                            children: [
                              for (final (i, perk) in _perks.indexed) ...[
                                _PerkRow(perk: perk),
                                if (i < 3) const SizedBox(height: 12),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: s.barberVip
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: clayDecoration(p,
                                    radius: 22, borderColor: AppColors.gold),
                                child: Row(
                                  children: [
                                    const Icon(Icons.workspace_premium_rounded,
                                        color: AppColors.gold, size: 24),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        L.vipActiveUntil(DateFormat('d MMM yyyy')
                                            .format(s.vipUntil!)),
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: p.text,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                decoration: clayDecoration(p, radius: 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.all_inclusive_rounded,
                                            color: AppColors.gold, size: 22),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(L.tierVipTitle,
                                              style: AppTypography.h4(context)),
                                        ),
                                        Text(
                                          L.vipPerMonth(
                                              _som(AppState.vipMonthlySom)),
                                          style: GoogleFonts.nunito(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w900,
                                            color: p.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    PrimaryButton(
                                      label: L.buyVipNow,
                                      icon: Icons.rocket_launch_rounded,
                                      height: 52,
                                      onPressed: () => _subscribe(context),
                                    ),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 10),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: Center(
                          child: Text(L.itsAHoldNotCharge,
                              style: AppTypography.caption(context)),
                        ),
                      ),
                    ],
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

/// A tall gold VIP hero (crown + always-on pitch).
class _VipHero extends StatelessWidget {
  const _VipHero();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFFF3C556), Color(0xFFD99A18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.42),
              blurRadius: 26,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Breathe(
                builder: (context, t) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.9 + 1.8 * t, -0.8),
                      radius: 1.1,
                      colors: [
                        Colors.white.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScaleIn(
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    L.tierVipTitle,
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3A2A00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L.vipTabSub,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A2A00).withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Perk {
  const _Perk(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.perk});
  final _Perk perk;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(perk.icon, size: 20, color: AppColors.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(perk.title,
                  style: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.text,
                  )),
              Text(perk.sub, style: AppTypography.caption(context)),
            ],
          ),
        ),
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.gold),
      ],
    );
  }
}
