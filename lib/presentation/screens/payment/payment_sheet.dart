import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/money.dart';
import '../../../core/payments/payments_api.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';

/// The OLD demo path's switch, for sheets opened WITHOUT a purpose.
///
/// Real money (wallet top-up, paying for a booking) now goes through the
/// server: pass a `purpose` to [showPaymentSheet] and, once Payme/Click keys
/// are set on Supabase (see supabase/PAYMENTS.md), the sheet opens a server
/// order, sends the person to the provider, and calls onPaid only after the
/// provider's signed callback marked the payment paid.
///
/// Without a purpose (or without keys) the sheet is the demo: a fake charge in
/// debug, "launching soon" in release. Keep this false: flipping it would make
/// a release build grant things with no money moving.
const bool kPaymentsLive = false;

/// The stub may grant in DEBUG (so the paid-feature UI stays testable), but
/// never in a release build until real payments exist.
bool get _paymentsGrantable => kPaymentsLive || kDebugMode;

/// The Uzbek payment providers Fade hands off to. Real integration redirects to
/// each provider's app/checkout and returns; here it's a provider-handoff STUB
/// (no card data, no real charge) with a realistic connect → success beat.
enum PayProvider { payme, click, uzum, uzcard, humo }

class _Brand {
  const _Brand(this.id, this.name, this.color, this.short, {this.sub});
  final String id;
  final String name;
  final Color color;
  final String short; // wordmark shown in the brand tile
  final String? sub;

  _Brand withSub(String s) => _Brand(id, name, color, short, sub: s);
}

const List<_Brand> _brands = [
  _Brand('payme', 'Payme', Color(0xFF00CCCC), 'P'),
  _Brand('click', 'Click', Color(0xFF00A651), 'C'),
  _Brand('uzum', 'Uzum', Color(0xFF7B2FF7), 'U'),
  _Brand('uzcard', 'UzCard', Color(0xFF1F4E9C), '••', sub: '•• 3415'),
  _Brand('humo', 'Humo', Color(0xFFE4002B), 'H'),
];

/// Show the payment sheet. Either pass a fixed [amountSom], or [amountOptions]
/// to let the user pick (used for wallet top-up).
///
/// With a [purpose] the sheet takes REAL payments when the server has Payme /
/// Click keys: it opens a server-side order, sends the person to Payme or
/// Click, and calls [onPaid] only after the server (fed by the provider's
/// signed callback) says the money moved. Without keys it falls back to the
/// old behaviour: a demo charge in debug, "launching soon" in release.
Future<void> showPaymentSheet(
  BuildContext context, {
  required String title,
  int? amountSom,
  List<int>? amountOptions,
  PaymentPurpose? purpose,
  String? bookingId,
  required void Function(int paidSom) onPaid,
}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _PaymentSheet(
      title: title,
      fixedAmount: amountSom,
      amountOptions: amountOptions,
      purpose: purpose,
      bookingId: bookingId,
      onPaid: onPaid,
    ),
  );
}

/// Manage the default payment method (Settings → Payment methods). No amount,
/// no charge — just pick which provider Fade defaults to.
Future<void> showPaymentMethodsSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _MethodsSheet(),
  );
}

class _MethodsSheet extends StatefulWidget {
  const _MethodsSheet();
  @override
  State<_MethodsSheet> createState() => _MethodsSheetState();
}

class _MethodsSheetState extends State<_MethodsSheet> {
  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return AnimatedBuilder(
      animation: AppState.instance,
      builder: (context, _) {
        final current = AppState.instance.payMethod;
        return Container(
          decoration: BoxDecoration(
            color: p.bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: p.border,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Text(L.payMethodsTitle, style: AppTypography.h2(context)),
              const SizedBox(height: 4),
              Text(L.payStubNote, style: AppTypography.bodySmall(context)),
              const SizedBox(height: 16),
              for (final b in _brands) ...[
                _MethodRow(
                  brand: b,
                  selected: current == b.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    AppState.instance.setPayMethod(b.id);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet({
    required this.title,
    required this.fixedAmount,
    required this.amountOptions,
    required this.onPaid,
    this.purpose,
    this.bookingId,
  });
  final String title;
  final int? fixedAmount;
  final List<int>? amountOptions;
  final PaymentPurpose? purpose;
  final String? bookingId;
  final void Function(int) onPaid;

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  late String _method = AppState.instance.payMethod;
  late int _amount =
      widget.fixedAmount ?? (widget.amountOptions?.first ?? 0);
  // 0 pick · 1 processing · 2 done · 3 coming-soon · 4 waiting for the
  // provider · 5 failed
  int _phase = 0;

  /// Real payments are on (the server has merchant keys). Until known, the
  /// sheet shows the usual list.
  bool _live = false;
  PaymentStart? _start;
  String? _openedUrl;
  String _error = '';

  /// Payme and Click are the integrated providers; cards (UzCard, Humo, Visa)
  /// are paid inside their checkouts.
  List<_Brand> get _shown => _live
      ? _brands.where((b) => b.id == 'payme' || b.id == 'click').toList()
      : _brands;

  _Brand get _brand =>
      _shown.firstWhere((b) => b.id == _method, orElse: () => _shown.first);

  @override
  void initState() {
    super.initState();
    if (widget.purpose != null) {
      PaymentsApi.instance.isLive().then((live) {
        if (!mounted || !live) return;
        setState(() {
          _live = true;
          if (_method != 'payme' && _method != 'click') _method = 'payme';
        });
      });
    }
  }

  Future<void> _payForReal() async {
    setState(() => _phase = 1);
    final start = await PaymentsApi.instance.start(
      purpose: widget.purpose!,
      amountSom:
          widget.purpose == PaymentPurpose.walletTopup ? _amount : null,
      bookingId: widget.bookingId,
      lang: AppState.instance.language.name,
    );
    if (!mounted) return;
    if (!start.configured) {
      // Keys were removed meanwhile: behave like before real payments.
      setState(() => _live = false);
      return _payDemo();
    }
    if (!start.ok) {
      setState(() {
        _error = start.error == 'sign in first' ? L.paySignInFirst : L.payFailedSub;
        _phase = 5;
      });
      return;
    }
    _start = start;
    final url = _method == 'click'
        ? (start.clickUrl ?? start.paymeUrl)
        : (start.paymeUrl ?? start.clickUrl);
    if (url == null) {
      setState(() {
        _error = L.payFailedSub;
        _phase = 5;
      });
      return;
    }
    if (url == start.clickUrl) _method = 'click';
    if (url == start.paymeUrl) _method = 'payme';
    _openedUrl = url;
    setState(() => _phase = 4);
    await _open();
    final outcome = await PaymentsApi.instance.waitForResult(
      start.paymentId!,
      stop: () => !mounted || _phase != 4,
    );
    if (!mounted || _phase != 4) return;
    if (outcome == PaymentOutcome.paid) {
      setState(() => _phase = 2);
      HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onPaid(start.amountSom ?? _amount);
    } else {
      setState(() {
        _error = L.payFailedSub;
        _phase = 5;
      });
    }
  }

  Future<void> _open() async {
    final url = _openedUrl;
    if (url == null) return;
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _pay() async {
    AppState.instance.setPayMethod(_method);
    HapticFeedback.mediumImpact();
    if (widget.purpose != null && _live) return _payForReal();
    return _payDemo();
  }

  Future<void> _payDemo() async {
    // No real provider yet: in a shipped build, refuse rather than hand out a
    // paid feature for free. onPaid is never called here.
    if (!_paymentsGrantable) {
      setState(() => _phase = 3);
      return;
    }
    setState(() => _phase = 1);
    // Simulated provider handoff — a real flow deep-links to Payme/Click here.
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _phase = 2);
    HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    Navigator.of(context).pop();
    widget.onPaid(_amount);
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          child: switch (_phase) {
            0 => _picker(p),
            3 => _comingSoon(p),
            4 => _waiting(p),
            5 => _failed(p),
            _ => _status(p),
          },
        ),
      ),
    );
  }

  Widget _picker(PaperPalette p) {
    return Column(
      key: const ValueKey('pick'),
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
        Text(widget.title, style: AppTypography.h2(context)),
        const SizedBox(height: 14),
        // Amount — a picker for top-ups, or a fixed figure.
        if (widget.amountOptions != null) ...[
          Text(L.payTopUpAmount, style: AppTypography.h4(context)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in widget.amountOptions!)
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _amount = a);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: _amount == a ? AppColors.accent : p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _amount == a ? AppColors.accent : p.border),
                    ),
                    child: Text("${Money.group(a)} so'm",
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _amount == a ? Colors.white : p.text,
                        )),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),
        ],
        Text(L.payChoose, style: AppTypography.h4(context)),
        const SizedBox(height: 10),
        for (final b in _shown) ...[
          _MethodRow(
            brand: _live ? b.withSub(L.payCardsInside) : b,
            selected: _brand.id == b.id,
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _method = b.id);
            },
          ),
          const SizedBox(height: 8),
        ],
        const SizedBox(height: 8),
        // Pay button.
        GestureDetector(
          onTap: _pay,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.34),
                    blurRadius: 16,
                    offset: const Offset(0, 7)),
              ],
            ),
            child: Text(L.payPay(Money.group(_amount)),
                style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white)),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(Icons.lock_outline_rounded, size: 13, color: p.textTertiary),
            const SizedBox(width: 5),
            Expanded(
              child: Text(_live ? L.payLiveNote : L.payStubNote,
                  style: AppTypography.caption(context)),
            ),
          ],
        ),
      ],
    );
  }

  /// Sent to Payme / Click: waiting for THEIR confirmation via our server.
  Widget _waiting(PaperPalette p) {
    return Column(
      key: const ValueKey('waiting'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation(_brand.color),
                ),
              ),
              _BrandTile(brand: _brand, size: 46),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(L.payFinishIn(_brand.name),
            textAlign: TextAlign.center, style: AppTypography.h3(context)),
        const SizedBox(height: 4),
        Text("${Money.group(_start?.amountSom ?? _amount)} so'm",
            style: AppTypography.bodySmall(context)),
        const SizedBox(height: 8),
        Text(L.payWaitingNote,
            textAlign: TextAlign.center,
            style: AppTypography.caption(context)),
        const SizedBox(height: 18),
        _wideButton(p, L.payOpenAgain(_brand.name), filled: true, onTap: _open),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(L.cancel,
              style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w800, color: p.textSecondary)),
        ),
      ],
    );
  }

  Widget _failed(PaperPalette p) {
    return Column(
      key: const ValueKey('failed'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.close_rounded, size: 42, color: AppColors.red),
        ),
        const SizedBox(height: 18),
        Text(L.payFailedTitle,
            textAlign: TextAlign.center, style: AppTypography.h3(context)),
        const SizedBox(height: 6),
        Text(_error,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(context)),
        const SizedBox(height: 20),
        _wideButton(p, L.payTryAgain,
            filled: true, onTap: () => setState(() => _phase = 0)),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _wideButton(PaperPalette p, String label,
      {required bool filled, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: filled ? AppColors.accent : p.card,
            borderRadius: BorderRadius.circular(16),
            border: filled ? null : Border.all(color: p.border),
          ),
          child: Text(label,
              style: GoogleFonts.nunito(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: filled ? Colors.white : p.text)),
        ),
      ),
    );
  }

  /// Shown when no real payment provider is wired yet. The point is that
  /// tapping Pay grants NOTHING — no free VIP/Boost/top-up in a shipped build.
  Widget _comingSoon(PaperPalette p) {
    return Column(
      key: const ValueKey('soon'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.schedule_rounded,
              size: 42, color: AppColors.accent),
        ),
        const SizedBox(height: 18),
        Text(L.payComingSoonTitle,
            textAlign: TextAlign.center, style: AppTypography.h3(context)),
        const SizedBox(height: 6),
        Text(L.payComingSoonSub,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(context)),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: p.border),
              ),
              child: Text(L.okGotIt,
                  style: GoogleFonts.nunito(
                      fontSize: 15, fontWeight: FontWeight.w900, color: p.text)),
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _status(PaperPalette p) {
    final done = _phase == 2;
    return Column(
      key: const ValueKey('status'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: 84,
          height: 84,
          child: done
              ? Container(
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      size: 44, color: AppColors.green),
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      strokeWidth: 4,
                      valueColor: AlwaysStoppedAnimation(_brand.color),
                    ),
                    _BrandTile(brand: _brand, size: 46),
                  ],
                ),
        ),
        const SizedBox(height: 18),
        Text(done ? L.paySuccess : L.payVia(_brand.name),
            style: AppTypography.h3(context)),
        const SizedBox(height: 4),
        Text("${Money.group(_amount)} so'm",
            style: AppTypography.bodySmall(context)),
        const SizedBox(height: 26),
      ],
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow(
      {required this.brand, required this.selected, required this.onTap});
  final _Brand brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : p.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            _BrandTile(brand: brand, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand.name, style: AppTypography.h4(context)),
                  if (brand.sub != null)
                    Text(brand.sub!,
                        style: AppTypography.caption(context)),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.accent : Colors.transparent,
                border: Border.all(
                    color: selected ? AppColors.accent : p.border, width: 2),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand, required this.size});
  final _Brand brand;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.color,
            Color.lerp(brand.color, Colors.black, 0.18)!,
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      alignment: Alignment.center,
      child: Text(brand.short,
          style: GoogleFonts.nunito(
            fontSize: size * 0.4,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          )),
    );
  }
}
