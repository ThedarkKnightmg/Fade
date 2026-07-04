import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/wallet_tx.dart';
import '../../widgets/paper_kit.dart';
import 'vip_boost_screen.dart';

/// The barber's prepaid wallet — the monetization "vending machine", led by a
/// skeuomorphic **coin wallet**: three metallic coins (Credit · Earned · Tips)
/// poke out of a stitched teal→blue leather pocket that shows the embossed
/// total, a weekly-gain delta, and Top-up · Activity · Boost. Below it float
/// the frosted fee-tier slats, the white-label QR card, and the ledger.
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
                  child: _WalletPocket(
                    onBoost: () => Navigator.of(context).push(
                      FadeThroughPageRoute(child: const VipBoostScreen()),
                    ),
                  ),
                ),
                if (s.walletLow) ...[
                  const SizedBox(height: 12),
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 110),
                    child: const _LowBalanceStrip(),
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

// ═══════════════════════════════════════════════════════════════════════
//  The wallet pocket — a stitched teal→blue leather pocket showing the
//  prepaid balance, the barber's scannable booking QR tucked inside, and the
//  Top-up · Activity · Boost actions.
// ═══════════════════════════════════════════════════════════════════════

class _WalletPocket extends StatefulWidget {
  const _WalletPocket({required this.onBoost});
  final VoidCallback onBoost;

  @override
  State<_WalletPocket> createState() => _WalletPocketState();
}

class _WalletPocketState extends State<_WalletPocket> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    const balanceStyle = TextStyle(
      fontSize: 30,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      height: 1,
      shadows: [
        Shadow(color: Color(0x55003049), offset: Offset(0, 1.5), blurRadius: 1),
      ],
    );
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2FB8C6), Color(0xFF1E8FC4), Color(0xFF176BA6)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8FC4).withValues(alpha: 0.42),
            blurRadius: 24,
            spreadRadius: -6,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Leather sheen: bright top-left → dark bottom-right.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.16),
                    Colors.white.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.10),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          // Stitched border.
          Positioned.fill(
            child: CustomPaint(
                painter: _StitchBorder(Colors.white.withValues(alpha: 0.55))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _PocketMiniBtn(
                      icon: _hidden
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _hidden = !_hidden);
                      },
                    ),
                    const Spacer(),
                    Text(L.walletTitle.toUpperCase(),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.72),
                        )),
                    const Spacer(),
                    _PocketMiniBtn(
                      icon: Icons.info_outline_rounded,
                      onTap: () => _walletToast(context, L.walletVending),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(L.walletBalanceLabel,
                    style: GoogleFonts.nunito(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.82),
                    )),
                const SizedBox(height: 3),
                _hidden
                    ? const Text('••• ••• •••', style: balanceStyle)
                    : AnimatedCount(
                        value: s.walletSom.toDouble(),
                        builder: (context, v) => Text(
                          "${Money.group(v.round())} so'm",
                          style: balanceStyle,
                        ),
                      ),
                const SizedBox(height: 16),
                // The barber's scannable booking QR, tucked into the wallet.
                _QrTicket(link: s.barberLink),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _PocketAction(
                        icon: Icons.arrow_downward_rounded,
                        label: L.actTopUp,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          s.topUpWallet(50000);
                          _walletToast(context, L.topUpAddedToast);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PocketAction(
                      icon: Icons.swap_vert_rounded,
                      onTap: () => _showActivitySheet(context),
                      circle: true,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PocketAction(
                        icon: Icons.rocket_launch_rounded,
                        label: L.actBoost,
                        onTap: widget.onBoost,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _walletToast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
    ));
}

/// The full ledger in a bottom sheet — the pocket's Activity key opens this.
void _showActivitySheet(BuildContext context) {
  HapticFeedback.selectionClick();
  final p = Paper.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7),
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: p.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          Text(L.walletActivity, style: AppTypography.h2(context)),
          const SizedBox(height: 14),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final tx in AppState.instance.walletLedger)
                  _LedgerRow(tx: tx),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

/// A white "ticket" of the barber's booking QR, tucked into the wallet pocket.
/// A regular who scans it books at 0% commission (Tier 3).
class _QrTicket extends StatelessWidget {
  const _QrTicket({required this.link});
  final String link;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: 'https://$link',
              version: QrVersions.auto,
              size: 128,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle,
                color: AppColors.accentDeep,
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.circle,
                color: AppColors.accentDeep,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code_scanner_rounded,
                    size: 13, color: Color(0xFF8A94A6)),
                const SizedBox(width: 5),
                Text(L.scanToBookMe,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF8A94A6),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PocketMiniBtn extends StatelessWidget {
  const _PocketMiniBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: Icon(icon, size: 17, color: Colors.white),
      ),
    );
  }
}

class _PocketAction extends StatelessWidget {
  const _PocketAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.circle = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        width: circle ? 44 : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(circle ? 22 : 14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.30)),
        ),
        child: circle
            ? Icon(icon, size: 20, color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(label ?? '',
                      style: GoogleFonts.nunito(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      )),
                ],
              ),
      ),
    );
  }
}

/// Dashed "stitching" around the pocket.
class _StitchBorder extends CustomPainter {
  const _StitchBorder(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(7, 7, size.width - 14, size.height - 14),
      const Radius.circular(21),
    );
    final src = Path()..addRRect(rrect);
    final dashed = Path();
    for (final m in src.computeMetrics()) {
      double d = 0;
      while (d < m.length) {
        final len = math.min(6.0, m.length - d);
        dashed.addPath(m.extractPath(d, d + len), Offset.zero);
        d += 10; // 6 dash + 4 gap
      }
    }
    canvas.drawPath(
      dashed,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StitchBorder old) => old.color != color;
}

class _LowBalanceStrip extends StatelessWidget {
  const _LowBalanceStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.35)),
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

/// A liquid-glass tier slat with a press-dip.
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
          child: GlassPanel(
            radius: 20,
            blur: 14,
            fillAlpha: 0.5,
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        t.tint.withValues(alpha: 0.22),
                        t.tint.withValues(alpha: 0.10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1),
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
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5), width: 1),
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
    return GlassPanel(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.link_rounded,
                  size: 20, color: AppColors.accent),
              const SizedBox(width: 8),
              Text(L.yourLinkLabel, style: AppTypography.h4(context)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  // "Engraved" groove — dark at the top, light at the bottom.
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x22244A9E), Color(0x0AFFFFFF)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: const Border(
                      top: BorderSide(color: Color(0x33244A9E)),
                      bottom: BorderSide(color: Color(0x80FFFFFF)),
                    ),
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
              _CopyKey(link: link),
            ],
          ),
          const SizedBox(height: 8),
          Text(L.qrStickerHint, style: AppTypography.caption(context)),
        ],
      ),
    );
  }
}

class _CopyKey extends StatefulWidget {
  const _CopyKey({required this.link});
  final String link;

  @override
  State<_CopyKey> createState() => _CopyKeyState();
}

class _CopyKeyState extends State<_CopyKey> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _down = true),
      onPointerUp: (_) => setState(() => _down = false),
      onPointerCancel: (_) => setState(() => _down = false),
      child: GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: 'https://${widget.link}'));
          HapticFeedback.selectionClick();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(L.linkCopiedToast),
              behavior: SnackBarBehavior.floating,
            ));
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 110),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF429BFF), AppColors.accentDeep],
            ),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.4),
                blurRadius: _down ? 3 : 8,
                offset: Offset(0, _down ? 1 : 4),
              ),
            ],
          ),
          child: const Icon(Icons.copy_rounded, size: 18, color: Colors.white),
        ),
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
    // A 0-fee debit = a returning regular kept free (Tier 3).
    final isFree = !tx.credit && tx.amountSom == 0;
    final positive = tx.credit || isFree;
    final tint = positive ? AppColors.green : AppColors.accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
            ),
            child: Icon(
              tx.credit
                  ? Icons.add_rounded
                  : (isFree
                      ? Icons.favorite_rounded
                      : Icons.content_cut_rounded),
              size: 18,
              color: tint,
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
          Text(
              isFree
                  ? L.walkInFreeTag.split(' ').first // "FREE"
                  : '${tx.credit ? '+' : '−'} ${Money.group(tx.amountSom)}',
              style: GoogleFonts.nunito(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: positive ? AppColors.green : p.text,
              )),
        ],
      ),
    );
  }
}
