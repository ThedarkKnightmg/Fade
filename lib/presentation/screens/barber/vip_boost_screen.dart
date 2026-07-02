import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

/// Tier 4 — the VIP "Turbo Boost" a barber buys to beat the neighborhood:
/// gold map pin, top placement in search, premium badge, top of the roster.
/// Purchase is a provider handoff STUB (Payme/Click) — no card data, no real
/// money; the live subscription is server-side once the backend lands.
class VipBoostScreen extends StatelessWidget {
  const VipBoostScreen({super.key});

  Future<void> _buy(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    // Provider handoff stub — a real flow redirects to Payme/Click and returns.
    HapticFeedback.heavyImpact();
    AppState.instance.activateVipBoost();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(L.vipActivated),
        behavior: SnackBarBehavior.floating,
      ));
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
          final active = s.barberVip;
          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                FadeSlideIn(
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
                const SizedBox(height: 18),
                // Gold hero with a drifting sheen.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: ClipRRect(
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
                            color: AppColors.gold.withValues(alpha: 0.45),
                            blurRadius: 30,
                            spreadRadius: -4,
                            offset: const Offset(0, 16),
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
                                    center:
                                        Alignment(-0.9 + 1.8 * t, -0.8 + 0.4 * t),
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
                                    child: const Icon(Icons.rocket_launch_rounded,
                                        color: Colors.white, size: 30),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  L.vipBoostHeadline,
                                  style: GoogleFonts.nunito(
                                    fontSize: 30,
                                    height: 1.05,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF3A2A00),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  L.vipBoostPitch,
                                  style: GoogleFonts.nunito(
                                    fontSize: 13.5,
                                    height: 1.4,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF3A2A00)
                                        .withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // The four perks.
                for (final (i, perk) in _perks.indexed) ...[
                  FadeSlideIn(
                    delay: Duration(milliseconds: 140 + i * 55),
                    child: _PerkTile(perk: perk),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                // Price + buy (or active state).
                FadeSlideIn(
                  delay: const Duration(milliseconds: 380),
                  child: active
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          decoration: clayDecoration(
                            p,
                            radius: 22,
                            borderColor: AppColors.gold,
                          ),
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
                      : Column(
                          children: [
                            Text(
                              L.vipPerMonth(
                                  "${Money.group(AppState.vipMonthlySom)} so'm"),
                              style: GoogleFonts.nunito(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: p.text,
                              ),
                            ),
                            const SizedBox(height: 12),
                            PrimaryButton(
                              label: L.buyVipNow,
                              icon: Icons.rocket_launch_rounded,
                              style: PrimaryButtonStyle.lime,
                              onPressed: () => _buy(context),
                            ),
                            const SizedBox(height: 8),
                            Text(L.itsAHoldNotCharge,
                                style: AppTypography.caption(context)),
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

  static List<_Perk> get _perks => [
        _Perk(Icons.location_on_rounded, L.vipPerkGoldPin, L.vipPerkGoldPinSub),
        _Perk(Icons.trending_up_rounded, L.vipPerkTopSearch,
            L.vipPerkTopSearchSub),
        _Perk(Icons.workspace_premium_rounded, L.vipPerkBadgePhoto,
            L.vipPerkBadgePhotoSub),
        _Perk(Icons.emoji_events_rounded, L.vipPerkRosterTop,
            L.vipPerkRosterTopSub),
      ];
}

class _Perk {
  const _Perk(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;
}

class _PerkTile extends StatelessWidget {
  const _PerkTile({required this.perk});
  final _Perk perk;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: clayDecoration(p, radius: 20),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(perk.icon, size: 22, color: AppColors.gold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(perk.title,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    )),
                Text(perk.sub, style: AppTypography.caption(context)),
              ],
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              size: 18, color: AppColors.gold),
        ],
      ),
    );
  }
}
