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

  void _requestBoost() {
    // Boosts aren't self-serve: this files a request the platform's control
    // panel must approve before the promotion goes live.
    if (AppState.instance.requestBoost()) {
      HapticFeedback.mediumImpact();
      _toast(L.boostRequestedToast);
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
                      // Animated: what a Boost does — surge to #1 for an hour.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: _BoostDemoCard(),
                      ),
                      const SizedBox(height: 14),
                      // The payoff, counted up.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 110),
                        child: const _BoostProofCard(),
                      ),
                      const SizedBox(height: 18),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 160),
                        child: _BoostBalanceCard(
                          boosts: s.boosts,
                          active: s.boostActive,
                          activeUntil: s.boostActiveUntil,
                          pending: s.boostRequestPending,
                          onUse: s.boosts > 0 && !s.boostRequestPending
                              ? _requestBoost
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: Text(L.fuelTitle, style: AppTypography.h3(context)),
                      ),
                      const SizedBox(height: 12),
                      for (final (i, pack) in AppState.boostPacks.indexed) ...[
                        FadeSlideIn(
                          delay: Duration(milliseconds: 240 + i * 55),
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
                        delay: const Duration(milliseconds: 420),
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

// ── Animated demo: surge to #1 for an hour, then the timer drains ─────────
/// A titled card that demonstrates what a Boost does: your row surges to the
/// top of the neighborhood, a "1 hour" bar drains, then you drop back — so the
/// pay-per-hour, temporary nature reads at a glance.
class _BoostDemoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayDecoration(p, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BoostDemo(),
          const SizedBox(height: 14),
          Text(L.boostRiseTitle,
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w900, color: p.text)),
          const SizedBox(height: 4),
          Text(L.boostRiseSub, style: AppTypography.bodySmall(context)),
        ],
      ),
    );
  }
}

class _BoostDemo extends StatefulWidget {
  const _BoostDemo();
  @override
  State<_BoostDemo> createState() => _BoostDemoState();
}

class _BoostDemoState extends State<_BoostDemo>
    with SingleTickerProviderStateMixin {
  static const double _rowH = 42;
  static const double _gap = 8;
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _topFor(int slot) => slot * (_rowH + _gap);

  Widget _content(bool risen, double drain) {
    // Slots top→bottom = 0,1,2. Boosted → You takes #1 and the two nearby
    // barbers slide down; otherwise You sits at the bottom.
    final youSlot = risen ? 0 : 2;
    final aSlot = risen ? 1 : 0;
    final bSlot = risen ? 2 : 1;
    return Column(
      children: [
        SizedBox(
          height: _rowH * 3 + _gap * 2,
          child: Stack(
            children: [
              _BoostRow(
                  top: _topFor(aSlot),
                  height: _rowH,
                  boosted: false,
                  rank: aSlot + 1,
                  label: L.vipNearbyRow),
              _BoostRow(
                  top: _topFor(bSlot),
                  height: _rowH,
                  boosted: false,
                  rank: bSlot + 1,
                  label: L.vipNearbyRow),
              _BoostRow(
                  top: _topFor(youSlot),
                  height: _rowH,
                  boosted: risen,
                  rank: youSlot + 1,
                  label: L.boostYouRow),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // The hour draining away.
        Row(
          children: [
            const Icon(Icons.timer_outlined, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: SizedBox(
                  height: 6,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ColoredBox(
                            color: AppColors.accent.withValues(alpha: 0.14)),
                      ),
                      FractionallySizedBox(
                        widthFactor: drain.clamp(0.0, 1.0),
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Color(0xFF4FA3FF),
                              AppColors.accentDeep,
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(L.boostHourLabel, style: AppTypography.caption(context)),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduce) return _content(true, 0.55);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        final risen = t >= 0.12 && t <= 0.9;
        final double drain = t < 0.12
            ? 1.0
            : (t <= 0.9 ? (0.9 - t) / (0.9 - 0.12) : 0.0);
        return _content(risen, drain);
      },
    );
  }
}

class _BoostRow extends StatelessWidget {
  const _BoostRow({
    required this.top,
    required this.height,
    required this.boosted,
    required this.rank,
    required this.label,
  });
  final double top;
  final double height;
  final bool boosted;
  final int rank;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: boosted ? null : p.card,
          gradient: boosted
              ? const LinearGradient(
                  colors: [Color(0xFF4FA3FF), Color(0xFF1E6FE0)])
              : null,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: boosted ? Colors.white.withValues(alpha: 0.6) : p.border,
          ),
          boxShadow: boosted
              ? [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: boosted
                    ? Colors.white.withValues(alpha: 0.9)
                    : p.textTertiary.withValues(alpha: 0.15),
              ),
              child: Text('$rank',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: boosted ? AppColors.accentDeep : p.textSecondary,
                  )),
            ),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: boosted
                    ? Colors.white.withValues(alpha: 0.9)
                    : p.textTertiary.withValues(alpha: 0.2),
              ),
              child: Icon(
                boosted ? Icons.bolt_rounded : Icons.person_rounded,
                size: 15,
                color: boosted ? AppColors.accentDeep : p.textSecondary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: boosted ? Colors.white : p.text,
                ),
              ),
            ),
            if (boosted) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(L.boostTopTag,
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      color: AppColors.accentDeep,
                    )),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.arrow_upward_rounded,
                  size: 15, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}

/// The payoff — "3× more walk-ins in a boosted hour", counted up.
class _BoostProofCard extends StatelessWidget {
  const _BoostProofCard();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: clayDecoration(p, radius: 22, borderColor: AppColors.accent),
      child: Row(
        children: [
          AnimatedCount(
            value: 3,
            duration: const Duration(milliseconds: 1100),
            builder: (context, v) => Text(
              '${v.toStringAsFixed(0)}×',
              style: GoogleFonts.nunito(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1,
                color: AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.boostProofSuffix,
                    style: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: p.text)),
                const SizedBox(height: 2),
                Text(L.boostProofSub, style: AppTypography.bodySmall(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BoostBalanceCard extends StatelessWidget {
  const _BoostBalanceCard({
    required this.boosts,
    required this.active,
    required this.activeUntil,
    required this.pending,
    required this.onUse,
  });

  final int boosts;
  final bool active;
  final DateTime? activeUntil;
  final bool pending;
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
          else if (pending)
            // Filed and escrowed — the platform's control panel reviews it
            // before the promotion goes live.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Breathe(
                    period: const Duration(milliseconds: 1400),
                    // Triangle wave so the pulse loops smoothly (no snap).
                    builder: (context, v) => Opacity(
                      opacity: 0.55 + 0.45 * (1 - (2 * v - 1).abs()),
                      child: const Icon(Icons.hourglass_top_rounded,
                          size: 18, color: AppColors.gold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    L.boostPendingLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
            )
          else
            PrimaryButton(
              label: onUse == null ? L.outOfUps : L.requestBoost,
              icon: Icons.bolt_rounded,
              height: 52,
              onPressed: onUse,
            ),
          if (!active) ...[
            const SizedBox(height: 10),
            Text(
              L.boostPendingHint,
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.textSecondary,
              ),
            ),
          ],
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
                    Flexible(
                      child: Text(L.upsUnit(pack.count),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.nunito(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: p.text,
                          )),
                    ),
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
