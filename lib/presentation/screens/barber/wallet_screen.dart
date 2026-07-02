import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/wallet_tx.dart';
import '../../widgets/paper_kit.dart';
import 'vip_boost_screen.dart';

/// The barber's prepaid wallet — the monetization "vending machine": load a
/// little, get clients out. A breathing balance hero, a count-up balance, and
/// puffy clay tier tiles. Mock ledger — top-up hands off to a provider.
class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

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
                      Text(L.walletTitle, style: AppTypography.h2(context)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: _BalanceHero(walletSom: s.walletSom, onTopUp: s.topUpWallet),
                ),
                if (s.walletLow) ...[
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 110),
                    child: _LowBalanceStrip(),
                  ),
                ],
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: Text(L.walletVending,
                      style: AppTypography.bodySmall(context)),
                ),
                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 170),
                  child: Text(L.howFeesWork, style: AppTypography.h3(context)),
                ),
                const SizedBox(height: 12),
                // The four tiers as puffy clay tiles; VIP opens Turbo Boost.
                for (final (i, t) in _tiers.indexed) ...[
                  FadeSlideIn(
                    delay: Duration(milliseconds: 200 + i * 55),
                    child: _TierTile(
                      tier: t,
                      onTap: i == 3
                          ? () => Navigator.of(context).push(
                                FadeThroughPageRoute(
                                    child: const VipBoostScreen()),
                              )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 440),
                  child: _LinkCard(link: s.barberLink),
                ),
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 480),
                  child: Text(L.walletActivity, style: AppTypography.h3(context)),
                ),
                const SizedBox(height: 12),
                for (final (i, tx) in s.walletLedger.indexed)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 520 + i * 50),
                    child: _LedgerRow(tx: tx),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static List<_Tier> get _tiers => [
        _Tier(Icons.event_available_rounded, L.tierFreeTitle, L.tierFreeSub,
            AppColors.green, '0%'),
        _Tier(Icons.person_add_alt_1_rounded, L.tierNewTitle, L.tierNewSub,
            AppColors.accent, '5%'),
        _Tier(Icons.qr_code_2_rounded, L.tierRegularTitle, L.tierRegularSub,
            AppColors.green, '~0%'),
        _Tier(Icons.rocket_launch_rounded, L.tierVipTitle, L.tierVipSub,
            AppColors.gold, 'VIP'),
      ];
}

class _Tier {
  const _Tier(this.icon, this.title, this.sub, this.tint, this.badge);
  final IconData icon;
  final String title;
  final String sub;
  final Color tint;
  final String badge;
}

/// The balance hero: a deep blue clay card with a slowly drifting sheen and a
/// count-up balance.
class _BalanceHero extends StatelessWidget {
  const _BalanceHero({required this.walletSom, required this.onTopUp});
  final int walletSom;
  final void Function(int) onTopUp;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xFF3D9BFF), Color(0xFF1E5FCC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.45),
              blurRadius: 30,
              spreadRadius: -4,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Drifting sheen — a soft light blob that breathes across the card.
            Positioned.fill(
              child: Breathe(
                builder: (context, t) => DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-0.8 + 1.6 * t, -0.9 + 0.5 * t),
                      radius: 1.1,
                      colors: [
                        Colors.white.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(L.walletBalanceLabel,
                          style: GoogleFonts.nunito(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedCount(
                    value: walletSom.toDouble(),
                    builder: (context, v) => Text(
                      "${Money.group(v.round())} so'm",
                      style: GoogleFonts.nunito(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(L.walletVendingHint,
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      )),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      for (final amt in const [50000, 100000]) ...[
                        Expanded(
                          child: _TopUpChip(
                            label: L.topUpBySom("${Money.group(amt)} so'm"),
                            onTap: () {
                              HapticFeedback.selectionClick();
                              onTopUp(amt);
                            },
                          ),
                        ),
                        if (amt == 50000) const SizedBox(width: 10),
                      ],
                    ],
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

class _TopUpChip extends StatefulWidget {
  const _TopUpChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_TopUpChip> createState() => _TopUpChipState();
}

class _TopUpChipState extends State<_TopUpChip> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _down ? 0.95 : 1,
          duration: const Duration(milliseconds: 110),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: _down ? 0.06 : 0.14),
                  blurRadius: _down ? 4 : 10,
                  offset: Offset(0, _down ? 2 : 5),
                ),
              ],
            ),
            child: Text(widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.nunito(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.accentDeep,
                )),
          ),
        ),
      ),
    );
  }
}

class _LowBalanceStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ScaleIn(
            child: const Icon(Icons.warning_amber_rounded,
                size: 18, color: AppColors.gold),
          ),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(L.walletLowWarn, style: AppTypography.bodySmall(context))),
        ],
      ),
    );
  }
}

/// A puffy clay tier tile with a press-dip.
class _TierTile extends StatefulWidget {
  const _TierTile({required this.tier, this.onTap});
  final VoidCallback? onTap;
  final _Tier tier;

  @override
  State<_TierTile> createState() => _TierTileState();
}

class _TierTileState extends State<_TierTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final t = widget.tier;
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
        scale: _down ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: clayDecoration(p, radius: 20),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: t.tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(t.icon, size: 22, color: t.tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.title,
                        style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: p.text,
                        )),
                    Text(t.sub, style: AppTypography.caption(context)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: t.tint.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(t.badge,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: t.tint,
                    )),
              ),
              if (widget.onTap != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: p.textTertiary),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.link});
  final String link;

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
              const Icon(Icons.qr_code_2_rounded,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(L.yourLinkLabel, style: AppTypography.h4(context)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.bg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(link,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentDeep,
                      )),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: 'https://$link'));
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text(L.linkCopiedToast),
                      behavior: SnackBarBehavior.floating,
                    ));
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.copy_rounded,
                      size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(L.shareYourLink, style: AppTypography.caption(context)),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.tx});
  final WalletTx tx;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final color = tx.credit ? AppColors.green : p.text;
    final sign = tx.credit ? '+' : '−';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (tx.credit ? AppColors.green : AppColors.accent)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              tx.credit ? Icons.add_rounded : Icons.content_cut_rounded,
              size: 18,
              color: tx.credit ? AppColors.green : AppColors.accent,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.label,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    )),
                if (tx.sub != null)
                  Text(tx.sub!, style: AppTypography.caption(context)),
              ],
            ),
          ),
          Text('$sign ${Money.group(tx.amountSom)}',
              style: GoogleFonts.nunito(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: color,
              )),
        ],
      ),
    );
  }
}
