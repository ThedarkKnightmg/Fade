import 'dart:async';

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

// Shared gold language — mirrors the premium map pin so the explainer and the
// real map read as the same "VIP = gold" system.
const Color _navy = Color(0xFF243049);
const Color _goldLight = Color(0xFFFCE7A6);
const Color _goldDeep = Color(0xFFC9962B);
const LinearGradient _goldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [_goldLight, AppColors.gold, _goldDeep],
);

/// An animated, benefit-first walkthrough of what VIP does for a barber —
/// shown BEFORE any payment. It demonstrates the two flagship perks (the gold
/// map pin + rising to the top of search) with live little animations, lists
/// everything included, then leads into the payment sheet. Activation is a
/// provider-handoff stub (enforcement is server-side once the backend lands).
class VipExplainerScreen extends StatelessWidget {
  const VipExplainerScreen({super.key});

  static String _som(int v) => "${Money.group(v)} so'm";

  void _activate(BuildContext context) {
    showPaymentSheet(
      context,
      title: L.tierVipTitle,
      amountSom: AppState.vipMonthlySom,
      onPaid: (_) {
        AppState.instance.activateVipBoost();
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(L.vipActivated),
            behavior: SnackBarBehavior.floating,
          ));
        Navigator.of(context).maybePop();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final perks = <_Perk>[
      _Perk(Icons.percent_rounded, L.vipPerkLowerFeeTitle,
          L.vipPerkLowerFeeSub),
      _Perk(Icons.location_on_rounded, L.vipPerkGoldPin, L.vipPerkGoldPinSub),
      _Perk(Icons.trending_up_rounded, L.vipPerkTopSearch,
          L.vipPerkTopSearchSub),
      _Perk(Icons.workspace_premium_rounded, L.vipPerkBadgePhoto,
          L.vipPerkBadgePhotoSub),
      _Perk(Icons.emoji_events_rounded, L.vipPerkRosterTop,
          L.vipPerkRosterTopSub),
    ];

    return Scaffold(
      backgroundColor: p.bg,
      // Rebuilds when VIP is activated so the hero + CTA flip to "active".
      body: AnimatedBuilder(
        animation: AppState.instance,
        builder: (context, _) {
          final s = AppState.instance;
          final active = s.barberVip;
          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    children: [
                      Row(
                        children: [
                          CircleBtn(
                            icon: Icons.arrow_back_rounded,
                            size: 42,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 12),
                          Text(L.tierVipTitle,
                              style: AppTypography.h2(context)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FadeSlideIn(child: _Hero(active: active)),
                      const SizedBox(height: 22),

                      // Flagship perk #1 — the gold map pin, demonstrated.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 80),
                        child: _DemoCard(
                          title: L.vipStandOutTitle,
                          sub: L.vipStandOutSub,
                          demo: const _StandOutDemo(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Flagship perk #2 — rising to the top of search.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 140),
                        child: _DemoCard(
                          title: L.vipRiseTitle,
                          sub: L.vipRiseSub,
                          demo: const _RiseDemo(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Money advantage — the new-client fee, shown dropping.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 200),
                        child: const _CommissionCard(),
                      ),
                      const SizedBox(height: 14),

                      // Social-proof stat — the payoff, counted up.
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 250),
                        child: const _ProofCard(),
                      ),
                      const SizedBox(height: 22),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 300),
                        child: Text(L.vipEverythingTitle,
                            style: AppTypography.h3(context)),
                      ),
                      const SizedBox(height: 12),
                      for (final (i, perk) in perks.indexed)
                        FadeSlideIn(
                          delay: Duration(milliseconds: 340 + i * 70),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _PerkRow(
                              perk: perk,
                              // Tick pops just after the row settles.
                              tickDelay:
                                  Duration(milliseconds: 620 + i * 70),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                active
                    ? _ActiveBar(
                        until: s.vipUntil == null
                            ? ''
                            : DateFormat('d MMM yyyy').format(s.vipUntil!),
                        savedSom: s.vipCommissionSavedSom,
                      )
                    : _CtaBar(
                        price: L.vipPerMonth(_som(AppState.vipMonthlySom)),
                        onActivate: () => _activate(context),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({this.active = false});
  final bool active;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: _goldGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.42),
              blurRadius: 28,
              spreadRadius: -6,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Drifting sheen.
            Positioned.fill(
              child: Breathe(
                builder: (context, t) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.9 + 1.8 * t, -0.8 + 0.5 * t),
                      radius: 1.1,
                      colors: [
                        Colors.white.withValues(alpha: 0.34),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pulsing crown coin.
                      ScaleIn(
                        child: Breathe(
                          period: const Duration(milliseconds: 2600),
                          builder: (context, t) => Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white
                                      .withValues(alpha: 0.15 + 0.35 * t),
                                  blurRadius: 12 + 10 * t,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.workspace_premium_rounded,
                                color: Colors.white, size: 34),
                          ),
                        ),
                      ),
                      const Spacer(),
                      // "ACTIVE" ribbon once subscribed.
                      if (active)
                        ScaleIn(
                          delay: const Duration(milliseconds: 320),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    size: 14, color: _goldDeep),
                                const SizedBox(width: 5),
                                Text(L.vipActiveChip.toUpperCase(),
                                    style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                      color: _navy,
                                    )),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    L.vipExplainTitle,
                    style: GoogleFonts.nunito(
                      fontSize: 27,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF3A2A00),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    L.vipExplainSub,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A2A00).withValues(alpha: 0.82),
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

// ── Reusable "titled demo" card ─────────────────────────────────────────
class _DemoCard extends StatelessWidget {
  const _DemoCard(
      {required this.title, required this.sub, required this.demo});
  final String title;
  final String sub;
  final Widget demo;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayDecoration(p, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          demo,
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.nunito(
                  fontSize: 16, fontWeight: FontWeight.w900, color: p.text)),
          const SizedBox(height: 4),
          Text(sub, style: AppTypography.bodySmall(context)),
        ],
      ),
    );
  }
}

// ── Demo 1: the gold pin standing out on a mini map ─────────────────────
class _StandOutDemo extends StatelessWidget {
  const _StandOutDemo();

  // Fixed scatter of "other shops" — resolution-independent alignments.
  static const List<Alignment> _dots = [
    Alignment(-0.75, -0.55),
    Alignment(0.5, -0.62),
    Alignment(-0.45, 0.55),
    Alignment(0.72, 0.42),
    Alignment(-0.9, 0.12),
    Alignment(0.15, -0.12),
    Alignment(0.88, -0.2),
    Alignment(-0.2, 0.85),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 150,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEDF1F7), Color(0xFFDCE3EF)],
          ),
        ),
        child: CustomPaint(
          painter: _GridPainter(const Color(0xFFCAD3E3)),
          child: Stack(
            children: [
              // Regular shops — small, identical navy dots.
              for (final a in _dots)
                Align(
                  alignment: a,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: _navy.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
              // You — the gold pin, haloed and crowned.
              Align(
                alignment: const Alignment(0.05, 0.05),
                child: Breathe(
                  period: const Duration(milliseconds: 2200),
                  builder: (context, t) => SizedBox(
                    width: 96,
                    height: 96,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Expanding halo.
                        Container(
                          width: 34 + 40 * t,
                          height: 34 + 40 * t,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold
                                .withValues(alpha: 0.28 * (1 - t)),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _navy,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(L.vipYouPin,
                                  style: GoogleFonts.nunito(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                    color: AppColors.gold,
                                  )),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: _goldGradient,
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.gold
                                        .withValues(alpha: 0.55),
                                    blurRadius: 14,
                                    spreadRadius: -1,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                  Icons.workspace_premium_rounded,
                                  size: 19,
                                  color: _navy),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const gap = 26.0;
    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

// ── Demo 2: rising to the top of the search list ────────────────────────
class _RiseDemo extends StatefulWidget {
  const _RiseDemo();
  @override
  State<_RiseDemo> createState() => _RiseDemoState();
}

class _RiseDemoState extends State<_RiseDemo> {
  static const double _rowH = 44;
  static const double _gap = 8;
  bool _risen = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Kick off the rise shortly after appearing, then loop it so the point
    // reads even if the user pauses on this card.
    _timer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (mounted) setState(() => _risen = !_risen);
    });
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _risen = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double _topFor(int slot) => slot * (_rowH + _gap);

  @override
  Widget build(BuildContext context) {
    // Slots top→bottom = 0,1,2. When risen, "You" takes slot 0 and the two
    // nearby barbers slide down to 1 and 2; otherwise You sits at the bottom.
    final youSlot = _risen ? 0 : 2;
    final aSlot = _risen ? 1 : 0;
    final bSlot = _risen ? 2 : 1;
    return SizedBox(
      height: _rowH * 3 + _gap * 2,
      child: Stack(
        children: [
          _RiseRow(
            top: _topFor(aSlot),
            height: _rowH,
            gold: false,
            rank: aSlot + 1,
            label: L.vipNearbyRow,
          ),
          _RiseRow(
            top: _topFor(bSlot),
            height: _rowH,
            gold: false,
            rank: bSlot + 1,
            label: L.vipNearbyRow,
          ),
          _RiseRow(
            top: _topFor(youSlot),
            height: _rowH,
            gold: true,
            rank: youSlot + 1,
            label: L.vipYouRow,
          ),
        ],
      ),
    );
  }
}

class _RiseRow extends StatelessWidget {
  const _RiseRow({
    required this.top,
    required this.height,
    required this.gold,
    required this.rank,
    required this.label,
  });
  final double top;
  final double height;
  final bool gold;
  final int rank;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      top: top,
      left: 0,
      right: 0,
      height: height,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: gold ? null : p.card,
          gradient: gold ? _goldGradient : null,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: gold ? Colors.white.withValues(alpha: 0.6) : p.border,
          ),
          boxShadow: gold
              ? [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.45),
                    blurRadius: 14,
                    spreadRadius: -2,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Rank chip.
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold ? _navy : p.textTertiary.withValues(alpha: 0.15),
              ),
              child: Text('$rank',
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: gold ? AppColors.gold : p.textSecondary,
                  )),
            ),
            const SizedBox(width: 10),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold
                    ? _navy.withValues(alpha: 0.9)
                    : p.textTertiary.withValues(alpha: 0.2),
              ),
              child: Icon(
                gold ? Icons.workspace_premium_rounded : Icons.person_rounded,
                size: 14,
                color: gold ? AppColors.gold : p.textSecondary,
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
                  color: gold ? _navy : p.text,
                ),
              ),
            ),
            if (gold)
              const Icon(Icons.arrow_upward_rounded, size: 16, color: _navy),
          ],
        ),
      ),
    );
  }
}

// ── Commission drop ─────────────────────────────────────────────────────
/// The money advantage: VIP halves the new-client fee. The old 5% sits struck
/// through above a big, softly-glowing gold 2.5% so the drop reads instantly.
class _CommissionCard extends StatelessWidget {
  const _CommissionCard();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayDecoration(p, radius: 22, borderColor: AppColors.gold),
      child: Row(
        children: [
          // The fee, visibly dropping: 5% struck → 2.5% gold.
          SizedBox(
            width: 66,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(L.vipFeeWas,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.textTertiary,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: p.textTertiary,
                    )),
                const Icon(Icons.arrow_downward_rounded,
                    size: 15, color: AppColors.gold),
                ScaleIn(
                  from: 0.4,
                  duration: const Duration(milliseconds: 520),
                  child: Breathe(
                    period: const Duration(milliseconds: 2600),
                    builder: (context, t) => Text(
                      L.vipFeeNow,
                      style: GoogleFonts.nunito(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: Color.lerp(AppColors.gold, _goldDeep, t),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.vipFeeCardTitle,
                    style: GoogleFonts.nunito(
                        fontSize: 16, fontWeight: FontWeight.w900, color: p.text)),
                const SizedBox(height: 3),
                Text(L.vipFeeCardSub, style: AppTypography.bodySmall(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Proof stat ──────────────────────────────────────────────────────────
class _ProofCard extends StatelessWidget {
  const _ProofCard();

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: clayDecoration(p, radius: 22, borderColor: AppColors.gold),
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
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  L.vipProofSuffix,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(L.vipProofSub, style: AppTypography.bodySmall(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Perk checklist row ──────────────────────────────────────────────────
class _Perk {
  const _Perk(this.icon, this.title, this.sub);
  final IconData icon;
  final String title;
  final String sub;
}

class _PerkRow extends StatelessWidget {
  const _PerkRow({required this.perk, this.tickDelay = Duration.zero});
  final _Perk perk;
  final Duration tickDelay;

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
        // The tick pops in just after the row settles — a small "included ✓".
        ScaleIn(
          delay: tickDelay,
          from: 0.2,
          duration: const Duration(milliseconds: 420),
          child: const Icon(Icons.check_circle_rounded,
              size: 19, color: AppColors.gold),
        ),
      ],
    );
  }
}

// ── Sticky activate bar ─────────────────────────────────────────────────
class _CtaBar extends StatelessWidget {
  const _CtaBar({required this.price, required this.onActivate});
  final String price;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(
            color: p.shadow,
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  price,
                  style: GoogleFonts.nunito(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: p.text,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 13, color: p.textTertiary),
                  const SizedBox(width: 4),
                  Text(L.itsAHoldNotCharge,
                      style: AppTypography.caption(context)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: L.vipActivate,
            icon: Icons.rocket_launch_rounded,
            style: PrimaryButtonStyle.lime,
            height: 56,
            onPressed: onActivate,
          ),
        ],
      ),
    );
  }
}

// ── Sticky "already VIP" bar ────────────────────────────────────────────
class _ActiveBar extends StatelessWidget {
  const _ActiveBar({required this.until, this.savedSom = 0});
  final String until;
  final int savedSom;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.border)),
        boxShadow: [
          BoxShadow(color: p.shadow, blurRadius: 18, offset: const Offset(0, -6)),
        ],
      ),
      child: Row(
        children: [
          // Softly pulsing gold crown coin — you're already in.
          Breathe(
            period: const Duration(milliseconds: 2600),
            builder: (context, t) => Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: _goldGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3 + 0.35 * t),
                    blurRadius: 10 + 10 * t,
                    spreadRadius: -1,
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium_rounded,
                  size: 24, color: _navy),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.vipYoureInTitle,
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                    )),
                if (savedSom > 0)
                  Text(L.vipSavedSoFar("${Money.group(savedSom)} so'm"),
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _goldDeep,
                      ))
                else if (until.isNotEmpty)
                  Text(L.vipActiveUntil(until),
                      style: AppTypography.caption(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
