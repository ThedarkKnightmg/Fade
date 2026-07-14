import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'vip_explainer_screen.dart';

/// Service profitability — a VIP perk. VIP barbers see which cuts earn them the
/// most (animated revenue bars); everyone else sees a locked teaser that leads
/// to the VIP screen.
class BarberAnalyticsScreen extends StatelessWidget {
  const BarberAnalyticsScreen({super.key});

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
                      Text(L.navAnalytics, style: AppTypography.h2(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: s.barberVip
                      ? _Breakdown(rows: s.serviceBreakdown())
                      : _Locked(
                          onGoVip: () => Navigator.of(context).push(
                            FadeThroughPageRoute(
                                child: const VipExplainerScreen()),
                          ),
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

class _Breakdown extends StatelessWidget {
  const _Breakdown({required this.rows});
  final List<({String name, int count, int revenueSom})> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(L.analyticsEmpty,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall(context)),
        ),
      );
    }
    final total = rows.fold<int>(0, (s, r) => s + r.revenueSom);
    final maxRev = rows.first.revenueSom; // rows are richest-first
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        FadeSlideIn(
          child: Text(L.analyticsTitle, style: AppTypography.h3(context)),
        ),
        const SizedBox(height: 2),
        FadeSlideIn(
          delay: const Duration(milliseconds: 40),
          child: Text(L.analyticsSub, style: AppTypography.bodySmall(context)),
        ),
        const SizedBox(height: 16),
        // Month total.
        FadeSlideIn(
          delay: const Duration(milliseconds: 80),
          child: _TotalCard(totalSom: total),
        ),
        const SizedBox(height: 16),
        for (final (i, r) in rows.indexed) ...[
          FadeSlideIn(
            delay: Duration(milliseconds: 120 + i * 60),
            child: _ServiceBar(
              name: L.tr(r.name),
              revenueSom: r.revenueSom,
              count: r.count,
              fraction: maxRev == 0 ? 0 : r.revenueSom / maxRev,
              top: i == 0,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalSom});
  final int totalSom;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: clayDecoration(p, radius: 22, borderColor: AppColors.gold),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.insights_rounded,
                size: 24, color: AppColors.gold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L.analyticsTotalLabel,
                    style: AppTypography.caption(context)),
                AnimatedCount(
                  value: totalSom.toDouble(),
                  builder: (context, v) => Text(
                    "${Money.group(v.round())} so'm",
                    style: GoogleFonts.nunito(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceBar extends StatelessWidget {
  const _ServiceBar({
    required this.name,
    required this.revenueSom,
    required this.count,
    required this.fraction,
    required this.top,
  });
  final String name;
  final int revenueSom;
  final int count;
  final double fraction;
  final bool top;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final tint = top ? AppColors.gold : AppColors.accent;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: clayDecoration(p, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: p.text,
                    )),
              ),
              Text("${Money.group(revenueSom)} so'm",
                  style: GoogleFonts.nunito(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: tint,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          // Animated revenue bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: tint.withValues(alpha: 0.12)),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: fraction.clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 720),
                    curve: AppCurves.easeOutQuart,
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: tint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(L.analyticsBookingsCount(count),
              style: AppTypography.caption(context)),
        ],
      ),
    );
  }
}

class _Locked extends StatelessWidget {
  const _Locked({required this.onGoVip});
  final VoidCallback onGoVip;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleIn(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.insights_rounded,
                    size: 36, color: AppColors.gold),
              ),
            ),
            const SizedBox(height: 20),
            Text(L.analyticsLockedTitle,
                textAlign: TextAlign.center,
                style: AppTypography.h2(context)),
            const SizedBox(height: 8),
            Text(L.analyticsLockedSub,
                textAlign: TextAlign.center,
                style: AppTypography.body(context).copyWith(height: 1.4)),
            const SizedBox(height: 24),
            PrimaryButton(
              label: L.analyticsUnlock,
              icon: Icons.workspace_premium_rounded,
              height: 54,
              onPressed: onGoVip,
            ),
          ],
        ),
      ),
    );
  }
}
