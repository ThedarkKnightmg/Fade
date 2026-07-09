import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/supabase/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// Animated phone-OTP verification for sign-up.
///
/// Sends a real SMS via Supabase (`AuthService.sendCode` → your SMS provider).
/// If the Supabase project doesn't have Phone auth + an SMS gateway configured
/// yet, it falls back to a locally-generated demo code (clearly labelled) so the
/// flow still works — real texts arrive the moment Twilio is enabled in Supabase.
class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({
    super.key,
    required this.phoneE164,
    required this.onVerified,
  });

  final String phoneE164;
  final VoidCallback onVerified;

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen>
    with SingleTickerProviderStateMixin {
  static const int _len = 6;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();

  bool _sending = true;
  bool _demoMode = false;
  String? _demoCode;
  bool _verifying = false;
  bool _success = false;
  String _error = '';
  int _resendIn = 0;
  Timer? _timer;

  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    _send();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shake.dispose();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = '';
    });
    try {
      await AuthService.sendCode(widget.phoneE164);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _demoMode = false;
      });
    } catch (_) {
      // Phone auth / SMS provider not configured — demo fallback so the flow
      // still works; real SMS flows once Twilio is enabled in Supabase.
      if (!mounted) return;
      setState(() {
        _sending = false;
        _demoMode = true;
        _demoCode = (100000 + Random().nextInt(900000)).toString();
      });
    }
    _startCountdown();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  void _startCountdown() {
    _timer?.cancel();
    _resendIn = 45;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) t.cancel();
    });
  }

  void _onChanged(String v) {
    setState(() => _error = '');
    if (v.length == _len && !_verifying) _verify();
  }

  Future<void> _verify() async {
    if (_ctrl.text.length < _len) {
      _focus.requestFocus();
      return;
    }
    setState(() => _verifying = true);
    bool ok;
    if (_demoMode) {
      ok = _ctrl.text == _demoCode;
    } else {
      try {
        await AuthService.verifyCode(widget.phoneE164, _ctrl.text);
        ok = true;
      } catch (_) {
        ok = false;
      }
    }
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      _focus.unfocus();
      setState(() {
        _success = true;
        _verifying = false;
      });
      await Future<void>.delayed(const Duration(milliseconds: 950));
      if (mounted) widget.onVerified();
    } else {
      HapticFeedback.heavyImpact();
      _shake.forward(from: 0);
      setState(() {
        _verifying = false;
        _error = L.wrongCode;
        _ctrl.clear();
      });
    }
  }

  Future<void> _resend() async {
    if (_resendIn > 0 || _sending) return;
    _ctrl.clear();
    await _send();
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(L.newCodeSent),
          behavior: SnackBarBehavior.floating,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final ready = _ctrl.text.length == _len && !_verifying;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    CircleBtn(
                      icon: Icons.arrow_back_rounded,
                      size: 42,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Pulsing SMS hero — the signature moment.
                FadeSlideIn(child: const _SmsHero()),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 70),
                  child: Text(L.verifyPhoneTitle,
                      style: AppTypography.display(context)),
                ),
                const SizedBox(height: 8),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 110),
                  child: Text(
                    _sending
                        ? L.otpSending
                        : L.verifyCodeSentTo(widget.phoneE164),
                    style: AppTypography.bodyLarge(context)
                        .copyWith(color: p.textSecondary),
                  ),
                ),
                const SizedBox(height: 18),
                if (_demoMode && !_sending)
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 130),
                    child: _DemoHint(code: _demoCode ?? ''),
                  ),
                const SizedBox(height: 20),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) {
                      final dx =
                          sin(_shake.value * pi * 4) * 9 * (1 - _shake.value);
                      return Transform.translate(
                          offset: Offset(dx, 0), child: child);
                    },
                    child: _CodeBoxes(
                      controller: _ctrl,
                      focusNode: _focus,
                      length: _len,
                      error: _error.isNotEmpty,
                      onChanged: _onChanged,
                    ),
                  ),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Center(
                    child: Text(_error,
                        style: AppTypography.bodySmall(context)
                            .copyWith(color: AppColors.red)),
                  ),
                ],
                const SizedBox(height: 24),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 200),
                  child: PrimaryButton(
                    label: _verifying ? L.otpSending : L.verifyWord,
                    height: 58,
                    icon: Icons.check_rounded,
                    onPressed: ready ? _verify : null,
                  ),
                ),
                const SizedBox(height: 14),
                Center(
                  child: GestureDetector(
                    onTap: _resend,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Text(
                        _resendIn > 0
                            ? L.resendInSec(_resendIn)
                            : L.resendCode,
                        style: GoogleFonts.nunito(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: _resendIn > 0
                              ? p.textTertiary
                              : AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Success celebration overlay.
            if (_success) const _SuccessOverlay(),
          ],
        ),
      ),
    );
  }
}

/// A blue SMS chip that scales in and softly pulses — draws the eye to the code.
class _SmsHero extends StatelessWidget {
  const _SmsHero();

  @override
  Widget build(BuildContext context) {
    return ScaleIn(
      child: Breathe(
        period: const Duration(milliseconds: 2600),
        builder: (context, t) => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4FA3FF), Color(0xFF1E6FE0)],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.25 + 0.35 * t),
                blurRadius: 16 + 14 * t,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.sms_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _DemoHint extends StatelessWidget {
  const _DemoHint({required this.code});
  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.accentDeep),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${L.demoCodeLabel}: $code',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                color: AppColors.accentDeep,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-screen green success flourish — check pops in, then the flow continues.
class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Paper.of(context).bg.withValues(alpha: 0.96),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleIn(
                from: 0.4,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.green.withValues(alpha: 0.4),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 54),
                ),
              ),
              const SizedBox(height: 18),
              FadeSlideIn(
                delay: const Duration(milliseconds: 120),
                child: Text(L.otpVerified,
                    style: AppTypography.h2(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Six digit boxes driven by one transparent field; the active box glows and
/// each entered digit pops in.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool error;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final value = controller.text;
    return GestureDetector(
      onTap: focusNode.requestFocus,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Row(
            children: [
              for (var i = 0; i < length; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: AppCurves.easeOutQuart,
                    height: 60,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.cardAlt,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: error
                            ? AppColors.red
                            : (i == value.length
                                ? AppColors.accent
                                : (i < value.length
                                    ? AppColors.accent.withValues(alpha: 0.5)
                                    : p.border)),
                        width: (i <= value.length) ? 2 : 1,
                      ),
                      boxShadow: i == value.length && !error
                          ? [
                              BoxShadow(
                                color:
                                    AppColors.accent.withValues(alpha: 0.25),
                                blurRadius: 10,
                                spreadRadius: -2,
                              ),
                            ]
                          : null,
                    ),
                    child: i < value.length
                        ? ScaleIn(
                            key: ValueKey('d$i${value[i]}'),
                            from: 0.3,
                            duration: const Duration(milliseconds: 240),
                            child: Text(
                              value[i],
                              style: GoogleFonts.nunito(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: p.text,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
                if (i < length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: TextInputType.number,
                maxLength: length,
                showCursor: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: onChanged,
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
