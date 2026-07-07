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
import '../payment/payment_sheet.dart';

/// The "Turbo Boost" hub. Two ways to jump to the top of the neighborhood:
///   • BARBER FUEL — cheap micro-transaction packs of "Ups" you keep in the
///     wallet and spend on a dead hour (pay-as-you-go, the no-brainer entry).
///   • VIP — a monthly subscription for always-on placement (go unlimited).
/// Both promote the chair: gold map pin, top of search, premium badge, top of
/// the roster. Purchases are provider-handoff STUBS — no card data, no real
/// money; enforcement is server-side once the backend lands.
class VipBoostScreen extends StatelessWidget {
  const VipBoostScreen({super.key});

  static String _som(int v) => "${Money.group(v)} so'm";

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _useBoost(BuildContext context) {
    if (AppState.instance.useBoost()) {
      HapticFeedback.mediumImpact();
      _toast(context, L.boostOnToast);
    }
  }

  void _buyPack(BuildContext context, BoostPack pack) {
    showPaymentSheet(
      context,
      title: L.upsUnit(pack.count),
      amountSom: pack.priceSom,
      onPaid: (_) {
        AppState.instance.buyBoostPack(pack.id);
        _toast(context, L.upsAddedToast(pack.count));
      },
    );
  }

  void _buyVip(BuildContext context) {
    showPaymentSheet(
      context,
      title: L.tierVipTitle,
      amountSom: AppState.vipMonthlySom,
      onPaid: (_) {
        AppState.instance.activateVipBoost();
        _toast(context, L.vipActivated);
      },
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
                // Gold hero — the "fill your chair right now" pitch.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: _GoldHero(),
                ),
                const SizedBox(height: 16),
                // Boosts balance + use-now.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 110),
                  child: _BoostBalanceCard(
                    boosts: s.boosts,
                    active: s.boostActive,
                    activeUntil: s.boostActiveUntil,
                    onUse: s.boosts > 0 ? () => _useBoost(context) : null,
                  ),
                ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: Text(L.fuelTitle, style: AppTypography.h3(context)),
                ),
                const SizedBox(height: 12),
                // The Fuel packs.
                for (final (i, pack) in AppState.boostPacks.indexed) ...[
                  FadeSlideIn(
                    delay: Duration(milliseconds: 180 + i * 55),
                    child: _PackCard(
                      pack: pack,
                      best: pack.id == 'growth',
                      onBuy: () => _buyPack(context, pack),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 12),
                // What a boost does.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 360),
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
                const SizedBox(height: 22),
                // VIP unlimited option.
                FadeSlideIn(
                  delay: const Duration(milliseconds: 420),
                  child: Text(L.orGoUnlimited, style: AppTypography.h3(context)),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 450),
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
                                    L.vipPerMonth(_som(AppState.vipMonthlySom)),
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
                                onPressed: () => _buyVip(context),
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 480),
                  child: Center(
                    child: Text(L.itsAHoldNotCharge,
                        style: AppTypography.caption(context)),
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

class _GoldHero extends StatelessWidget {
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
              color: AppColors.gold.withValues(alpha: 0.4),
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
                      center: Alignment(-0.9 + 1.8 * t, -0.8 + 0.4 * t),
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
                      child: const Icon(Icons.bolt_rounded,
                          color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    L.fillChairNow,
                    style: GoogleFonts.nunito(
                      fontSize: 28,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3A2A00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L.fillChairNowSub,
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

class _BoostBalanceCard extends StatelessWidget {
  const _BoostBalanceCard({
    required this.boosts,
    required this.active,
    required this.activeUntil,
    required this.onUse,
  });

  final int boosts;
  final bool active;
  final DateTime? activeUntil;
  final VoidCallback? onUse;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayDecoration(p, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppColors.gold, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(L.upsInWallet(boosts),
                    style: GoogleFonts.nunito(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (active && activeUntil != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                L.boostedUntilTime(DateFormat('HH:mm').format(activeUntil!)),
                style: GoogleFonts.nunito(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.green,
                ),
              ),
            )
          else
            PrimaryButton(
              label: onUse == null ? L.outOfUps : L.useBoostNow,
              icon: Icons.bolt_rounded,
              height: 52,
              style: PrimaryButtonStyle.lime,
              onPressed: onUse,
            ),
        ],
      ),
    );
  }
}

class _PackCard extends StatelessWidget {
  const _PackCard(
      {required this.pack, required this.best, required this.onBuy});
  final BoostPack pack;
  final bool best;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: clayDecoration(
        p,
        radius: 20,
        borderColor: best ? AppColors.gold : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text('${pack.count}',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gold,
                )),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(L.upsUnit(pack.count),
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: p.text,
                        )),
                    if (best) ...[
                      const SizedBox(width: 8),
                      MiniPill(L.bestValue, style: MiniPillStyle.gold),
                    ],
                  ],
                ),
                Text(L.perBoostLabel("${Money.group(pack.perBoostSom)} so'm"),
                    style: AppTypography.caption(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onBuy,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                "${Money.group(pack.priceSom)} so'm",
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
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
