import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../../data/models/wallet_tx.dart';
import '../../widgets/paper_kit.dart';
import '../payment/payment_sheet.dart';
import 'boost_screen.dart';
import 'vip_explainer_screen.dart';

/// The barber's prepaid wallet — money only, kept simple to understand: a
/// dark card with the balance, Top-up · Activity · Boost under it, a plain-language "how fees work" list, and a clear transaction feed
/// (money in vs. commission out, each with a date). No QR/sharing clutter —
/// that lives on the profile's "Grow bookings" card.
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
                      FadeThroughPageRoute(child: const BoostScreen()),
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
                      onTap: i == 1
                          ? () => Navigator.of(context).push(
                                FadeThroughPageRoute(
                                    child: const VipExplainerScreen()),
                              )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 22),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 440),
                  child: Row(
                    children: [
                      Text(L.walletActivity,
                          style: AppTypography.h3(context)),
                      const Spacer(),
                      _LegendChip(
                          color: AppColors.green,
                          sign: '＋',
                          label: L.walletLegendIn),
                      const SizedBox(width: 12),
                      _LegendChip(
                          color: AppColors.red,
                          sign: '－',
                          label: L.walletLegendFee),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final (i, tx) in s.walletLedger.indexed)
                  FadeSlideIn(
                    delay: Duration(milliseconds: 480 + i * 50),
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
        _Tier(Icons.percent_rounded, L.tierStandardTitle, L.tierStandardSub,
            AppColors.accent, '5%'),
        _Tier(Icons.workspace_premium_rounded, L.tierVipProTitle,
            L.tierVipProSub, AppColors.gold, '2.5%'),
        _Tier(Icons.event_available_rounded, L.tierWalkinTitle, L.tierWalkinSub,
            AppColors.green, '0%'),
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

/// The wallet, as a dark card with the actions underneath it.
///
/// Dark on purpose: it is the one near-black surface in a light app, so money
/// reads as its own, more serious thing, the way a bank card does, without
/// introducing a new colour (it is the app's ink).
///
/// Motion, all off with reduced motion:
///  * The balance is an odometer: each digit column rolls on its own, the
///    higher digits a little longer, so the number arrives like a counter
///    rather than flickering through values. Money in rolls the digits up,
///    a fee rolls them down.
///  * Money in also floats a green "+amount" up off the balance and fades.
///  * Hiding the balance rolls the digits away and the dots in.
///  * On opening, one clipper-pass sheen crosses the card: the same move the
///    home tiles and the language screen use.
class _WalletPocket extends StatefulWidget {
  const _WalletPocket({required this.onBoost});
  final VoidCallback onBoost;

  @override
  State<_WalletPocket> createState() => _WalletPocketState();
}

class _WalletPocketState extends State<_WalletPocket>
    with TickerProviderStateMixin {
  bool _hidden = false;

  // Created in initState, not lazily: with reduced motion the sheen is never
  // touched, and a lazy controller would first be created inside dispose().
  late final AnimationController _sheen;

  @override
  void initState() {
    super.initState();
    _sheen = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  /// The last balance seen, to tell money in from money out.
  int? _last;

  /// A green "+amount" floating off the balance after a top-up.
  late final AnimationController _gain = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  int _gainAmount = 0;
  bool _rising = true;

  bool get _reduce => MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reduce && _sheen.status == AnimationStatus.dismissed) {
      Future<void>.delayed(const Duration(milliseconds: 280), () {
        if (mounted) _sheen.forward();
      });
    }
  }

  @override
  void dispose() {
    _sheen.dispose();
    _gain.dispose();
    super.dispose();
  }

  void _track(int balance) {
    final last = _last;
    _last = balance;
    if (last == null || last == balance) return;
    _rising = balance > last;
    if (_rising && !_reduce) {
      _gainAmount = balance - last;
      // Not mid-build: start the float on the next frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _gain.forward(from: 0);
      });
    }
  }

  void _topUp(BuildContext context) {
    final s = AppState.instance;
    showPaymentSheet(
      context,
      title: L.actTopUp,
      amountOptions: const [50000, 100000, 200000, 500000],
      onPaid: (som) {
        s.topUpWallet(som);
        HapticFeedback.mediumImpact();
        _walletToast(context, L.topUpAddedToast);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.instance;
    final p = Paper.of(context);
    final balance = s.walletSom;
    _track(balance);
    final cardColor = p.isDark ? p.cardAlt : const Color(0xFF15181D);
    final reduce = _reduce;

    const amountStyle = TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w900,
      color: Colors.white,
      height: 1.15,
      letterSpacing: -0.5,
    );

    final card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(26),
        border: p.isDark ? Border.all(color: p.border) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: p.isDark ? 0.3 : 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            // A soft light falling from the top-left: material, not glow.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.07),
                      Colors.white.withValues(alpha: 0),
                    ],
                    stops: const [0, 0.55],
                  ),
                ),
              ),
            ),
            // The brand mark, large and faint, in the corner.
            Positioned(
              right: -18,
              bottom: -22,
              child: Icon(Icons.content_cut_rounded,
                  size: 120, color: Colors.white.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text('FADE  ·  ${L.walletTitle.toUpperCase()}',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.6,
                            color: Colors.white.withValues(alpha: 0.55),
                          )),
                      const Spacer(),
                      _CardIconBtn(
                        icon: _hidden
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _hidden = !_hidden);
                        },
                      ),
                      const SizedBox(width: 6),
                      _CardIconBtn(
                        icon: Icons.info_outline_rounded,
                        onTap: () => _walletToast(context, L.walletVending),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(L.walletBalanceLabel,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.6),
                      )),
                  const SizedBox(height: 4),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: reduce ? 0 : 280),
                        switchInCurve: AppCurves.easeOutQuart,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, a) => FadeTransition(
                          opacity: a,
                          child: SlideTransition(
                            position: Tween(
                                    begin: const Offset(0, 0.35),
                                    end: Offset.zero)
                                .animate(a),
                            child: child,
                          ),
                        ),
                        layoutBuilder: (cur, prev) => Stack(
                          alignment: Alignment.centerLeft,
                          children: [...prev, if (cur != null) cur],
                        ),
                        child: _hidden
                            ? Text('••• •••',
                                key: const ValueKey('hidden'),
                                style: amountStyle)
                            : Row(
                                key: const ValueKey('shown'),
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _Odometer(
                                    value: balance,
                                    style: amountStyle,
                                    rising: _rising,
                                    animate: !reduce,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        left: 6, bottom: 5),
                                    child: Text("so'm",
                                        style: GoogleFonts.nunito(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white
                                              .withValues(alpha: 0.65),
                                        )),
                                  ),
                                ],
                              ),
                      ),
                      // Money in: "+amount" lifts off the balance and fades.
                      Positioned(
                        left: 0,
                        top: -6,
                        child: AnimatedBuilder(
                          animation: _gain,
                          builder: (context, _) {
                            final g = _gain.value;
                            if (g == 0 || g == 1 || _hidden) {
                              return const SizedBox.shrink();
                            }
                            final o = g < 0.15 ? g / 0.15 : (1 - g) / 0.85;
                            return Transform.translate(
                              offset: Offset(0, -26 * Curves.easeOutCubic
                                  .transform(g)),
                              child: Opacity(
                                opacity: o.clamp(0.0, 1.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.green,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    '+${Money.group(_gainAmount)}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0B2A1A),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 15, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(L.upsUnit(s.boosts),
                                style: GoogleFonts.nunito(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white.withValues(alpha: 0.85),
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // The clipper-pass sheen, once, on opening.
            if (!reduce)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _sheen,
                    builder: (context, _) {
                      final v = _sheen.value;
                      if (v == 0 || v == 1) return const SizedBox.shrink();
                      final x = -0.4 + 1.8 * Curves.easeInOutCubic.transform(v);
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withValues(alpha: 0),
                              Colors.white.withValues(alpha: 0.13),
                              AppColors.accent.withValues(alpha: 0.25),
                              Colors.white.withValues(alpha: 0),
                            ],
                            stops: [
                              (x - 0.2).clamp(0.0, 1.0),
                              (x - 0.02).clamp(0.0, 1.0),
                              x.clamp(0.0, 1.0),
                              (x + 0.06).clamp(0.0, 1.0),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Column(
      children: [
        card,
        const SizedBox(height: 12),
        // Actions under the card, solid: Top up is the one primary.
        Row(
          children: [
            Expanded(
              flex: 5,
              child: _WalletAction(
                icon: Icons.add_rounded,
                label: L.actTopUp,
                primary: true,
                onTap: () => _topUp(context),
              ),
            ),
            const SizedBox(width: 10),
            _WalletAction(
              icon: Icons.receipt_long_rounded,
              onTap: () => _showActivitySheet(context),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _WalletAction(
                icon: Icons.rocket_launch_rounded,
                label: L.actBoost,
                onTap: widget.onBoost,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A balance that rolls like an odometer: one rolling column per digit,
/// right-aligned so a growing number gains columns on the left.
class _Odometer extends StatelessWidget {
  const _Odometer({
    required this.value,
    required this.style,
    required this.rising,
    required this.animate,
  });

  final int value;
  final TextStyle style;

  /// Money in rolls the digits up; money out rolls them down.
  final bool rising;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final text = Money.group(value);
    final chars = text.split('');
    bool isDigit(String c) => '0123456789'.contains(c);
    var fromRight = chars.where(isDigit).length;
    // Read as one number, not as a dozen separate glyphs.
    return Semantics(
      label: "$text so'm",
      excludeSemantics: true,
      child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final c in chars)
          if (!isDigit(c))
            Text(c, style: style)
          else
            _RollingDigit(
              // Keyed by place value, so the units column stays the units
              // column when the number grows a digit.
              key: ValueKey('place-${--fromRight}'),
              digit: int.parse(c),
              place: fromRight,
              style: style,
              rising: rising,
              animate: animate,
            ),
      ],
      ),
    );
  }
}

class _RollingDigit extends StatefulWidget {
  const _RollingDigit({
    super.key,
    required this.digit,
    required this.place,
    required this.style,
    required this.rising,
    required this.animate,
  });

  final int digit;

  /// 0 = units. Higher places roll a little longer, like a real counter.
  final int place;
  final TextStyle style;
  final bool rising;
  final bool animate;

  @override
  State<_RollingDigit> createState() => _RollingDigitState();
}

class _RollingDigitState extends State<_RollingDigit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  /// Continuous position: 7.0 shows "7", 7.5 is halfway to "8".
  double _from = 0;
  double _to = 0;

  Duration get _duration =>
      Duration(milliseconds: 650 + 90 * widget.place.clamp(0, 6));

  @override
  void initState() {
    super.initState();
    // On first show, spin up from zero (one full turn plus the digit).
    _from = 0;
    _to = widget.animate ? widget.digit + 10.0 : widget.digit.toDouble();
    if (widget.animate) {
      _c.duration = _duration;
      _c.forward();
    } else {
      _c.value = 1;
    }
  }

  @override
  void didUpdateWidget(_RollingDigit old) {
    super.didUpdateWidget(old);
    if (old.digit == widget.digit) return;
    final now = _pos;
    var target = (now / 10).floor() * 10 + widget.digit.toDouble();
    if (widget.rising && target <= now) target += 10;
    if (!widget.rising && target >= now) target -= 10;
    _from = now;
    _to = target;
    if (widget.animate) {
      _c.duration = _duration;
      _c.forward(from: 0);
    } else {
      _c.value = 1;
    }
  }

  double get _pos =>
      _from + (_to - _from) * AppCurves.easeOutQuart.transform(_c.value);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lineH = (widget.style.fontSize ?? 36) * (widget.style.height ?? 1.15);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final pos = _pos;
        final base = pos.floor();
        final frac = pos - base;
        String d(int n) => '${((n % 10) + 10) % 10}';
        return ClipRect(
          child: SizedBox(
            height: lineH,
            child: Stack(
              children: [
                // Sizes the column to its digit's width.
                Opacity(opacity: 0, child: Text('${widget.digit}', style: widget.style)),
                Positioned(
                  left: 0,
                  right: 0,
                  top: -frac * lineH,
                  child: Column(
                    children: [
                      SizedBox(
                          height: lineH,
                          child: Text(d(base),
                              style: widget.style, textAlign: TextAlign.center)),
                      SizedBox(
                          height: lineH,
                          child: Text(d(base + 1),
                              style: widget.style, textAlign: TextAlign.center)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

/// A tiny legend chip under the Activity header — teaches the +/− convention.
class _LegendChip extends StatelessWidget {
  const _LegendChip(
      {required this.color, required this.sign, required this.label});
  final Color color;
  final String sign;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(sign,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: color,
            )),
        if (label != null) ...[
          const SizedBox(width: 4),
          Text(label!,
              style: GoogleFonts.nunito(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Paper.of(context).textSecondary,
              )),
        ],
      ],
    );
  }
}

/// A small round icon button on the dark card.
class _CardIconBtn extends StatelessWidget {
  const _CardIconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
        ),
        child: Icon(icon, size: 17, color: Colors.white.withValues(alpha: 0.9)),
      ),
    );
  }
}

/// An action under the wallet card: the primary one solid accent, the rest
/// white cards; icon-only when there's no label.
class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.icon,
    required this.onTap,
    this.label,
    this.primary = false,
  });
  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final fg = primary ? Colors.white : p.text;
    return PressableScale(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 52,
        width: label == null ? 52 : null,
        alignment: Alignment.center,
        decoration: primary
            ? BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(16),
              )
            : clayDecoration(p, radius: 16),
        child: label == null
            ? Icon(icon, size: 21, color: p.text)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon,
                      size: 19, color: primary ? Colors.white : AppColors.accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: fg,
                        )),
                  ),
                ],
              ),
      ),
    );
  }
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
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: clayDecoration(p, radius: 20),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: t.tint.withValues(alpha: 0.12),
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
                    color: t.tint.withValues(alpha: 0.14),
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

/// One transaction, as a self-contained card so it reads clearly: a coloured
/// direction icon, what it was + when, and a signed amount. Money in is green
/// with ＋; a commission fee is red with －; a regular kept free shows a FREE tag.
class _LedgerRow extends StatelessWidget {
  const _LedgerRow({required this.tx});
  final WalletTx tx;

  static String _relDate(DateTime at) {
    final now = DateTime.now();
    final d = DateTime(at.year, at.month, at.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff <= 0) return '${L.dateToday}, ${DateFormat('HH:mm').format(at)}';
    if (diff == 1) return L.dateYesterday;
    return DateFormat('d MMM').format(at);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    // A 0-fee debit = a returning regular kept free (Tier 3).
    final isFree = !tx.credit && tx.amountSom == 0;
    final Color tint = tx.credit
        ? AppColors.green
        : (isFree ? AppColors.gold : AppColors.red);
    final IconData icon = tx.credit
        ? Icons.south_west_rounded // money in
        : (isFree ? Icons.favorite_rounded : Icons.north_east_rounded);
    // What kind of line this is, in plain words (falls back to the tx sub).
    final String kind = tx.credit
        ? L.txMoneyIn
        : (isFree ? L.txKeptFree : L.txCommissionFee);
    final String caption = '$kind · ${_relDate(tx.at)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: clayDecoration(p, radius: 16),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.nunito(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: p.text,
                    )),
                const SizedBox(height: 2),
                Text(caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption(context)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isFree)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(L.walletFreeTag,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.green,
                  )),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${tx.credit ? '＋' : '－'} ${Money.group(tx.amountSom)}',
                    style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: tx.credit ? AppColors.green : AppColors.red,
                    )),
                Text("so'm", style: AppTypography.caption(context)),
              ],
            ),
        ],
      ),
    );
  }
}
