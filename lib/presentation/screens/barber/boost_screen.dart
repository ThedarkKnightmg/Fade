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

/// BOOST — the pay-as-you-go product, fully on its own.
/// Buy cheap packs of "Ups" you keep in the wallet and spend on a dead hour to
/// jump to the top of the neighborhood. No subscription, no commitment — the
/// impulse buy. (Purchases are provider-handoff STUBS — no card data, no real
/// money; enforcement is server-side once the backend lands.)
class BoostScreen extends StatefulWidget {
  const BoostScreen({super.key});

  @override
  State<BoostScreen> createState() => _BoostScreenState();
}

class _BoostScreenState extends State<BoostScreen> {
  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ));
  }

  void _useBoost() {
    if (AppState.instance.useBoost()) {
      HapticFeedback.mediumImpact();
      _toast(L.boostOnToast);
    }
  }

  void _buyPack(BoostPack pack) {
    showPaymentSheet(
      context,
      title: L.upsUnit(pack.count),
      amountSom: pack.priceSom,
      onPaid: (_) {
        AppState.instance.buyBoostPack(pack.id);
        _toast(L.upsAddedToast(pack.count));
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
                      Text(L.tabBoost, style: AppTypography.h2(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      FadeSlideIn(child: _BoostHero()),
                      const SizedBox(height: 16),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: _BoostBalanceCard(
                          boosts: s.boosts,
                          active: s.boostActive,
                          activeUntil: s.boostActiveUntil,
                          onUse: s.boosts > 0 ? _useBoost : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: Text(L.fuelTitle, style: AppTypography.h3(context)),
                      ),
                      const SizedBox(height: 12),
                      for (final (i, pack) in AppState.boostPacks.indexed) ...[
                        FadeSlideIn(
                          delay: Duration(milliseconds: 140 + i * 55),
                          child: _PackCard(
                            pack: pack,
                            best: pack.id == 'growth',
                            onBuy: () => _buyPack(pack),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 6),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 320),
                        child: Center(
                          child: Text(L.boostTabSub,
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

/// The electric-blue Boost hero (bolt + "fill your chair now" pitch).
class _BoostHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF4FA3FF), Color(0xFF1E6FE0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.42),
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
                        Colors.white.withValues(alpha: 0.28),
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
                        color: Colors.white.withValues(alpha: 0.22),
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
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L.fillChairNowSub,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
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
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppColors.accent, size: 24),
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
        borderColor: best ? AppColors.accent : null,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            alignment: Alignment.center,
            child: Text('${pack.count}',
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accent,
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
                      MiniPill(L.bestValue, style: MiniPillStyle.accent),
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
