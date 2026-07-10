import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// Confirms a NEW email or phone before it's saved.
///
/// There's no SMS/email backend yet, so the code is generated locally and shown
/// in a clearly-labelled "demo" hint. The flow — enter code → verify → resend
/// with a cooldown — is exactly what a real OTP needs, so it drops straight onto
/// a Supabase `signInWithOtp` call later. Pops `true` once the code matches.
class VerifyContactScreen extends StatefulWidget {
  const VerifyContactScreen({
    super.key,
    required this.target,
    required this.isEmail,
  });

  /// The new email or phone being confirmed.
  final String target;
  final bool isEmail;

  @override
  State<VerifyContactScreen> createState() => _VerifyContactScreenState();
}

class _VerifyContactScreenState extends State<VerifyContactScreen> {
  static const _len = 4;

  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late String _code;
  String _error = '';
  int _resendIn = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _code = _newCode();
    _startCountdown();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  String _newCode() => (1000 + Random().nextInt(9000)).toString();

  void _startCountdown() {
    _timer?.cancel();
    _resendIn = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _resendIn = _resendIn > 0 ? _resendIn - 1 : 0);
      if (_resendIn == 0) t.cancel();
    });
  }

  void _onChanged(String v) {
    setState(() => _error = '');
    if (v.length == _len) _verify();
  }

  void _verify() {
    if (_ctrl.text.length < _len) {
      _focus.requestFocus();
      return;
    }
    // DEMO VERIFICATION ONLY — there is no SMS/email backend yet. The code is
    // generated and checked entirely on-device, so this proves nothing about
    // ownership of the target address/number. It exists to exercise the UX flow
    // and MUST be replaced by a real server-side OTP check (e.g. Supabase
    // `verifyOtp`) before this is treated as genuine verification.
    if (_ctrl.text == _code) {
      HapticFeedback.lightImpact();
      Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        _error = L.wrongCode;
        _ctrl.clear();
      });
    }
  }

  void _resend() {
    if (_resendIn > 0) return;
    setState(() {
      _code = _newCode();
      _ctrl.clear();
      _error = '';
    });
    _startCountdown();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(L.newCodeSent)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final title = widget.isEmail ? L.verifyEmailTitle : L.verifyPhoneTitle;
    final ready = _ctrl.text.length == _len;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
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
              ],
            ),
            const SizedBox(height: 18),
            FadeSlideIn(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  widget.isEmail
                      ? Icons.mark_email_read_rounded
                      : Icons.sms_rounded,
                  color: AppColors.accent,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),
            FadeSlideIn(
              delay: const Duration(milliseconds: 60),
              child: Text(title, style: AppTypography.display(context)),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 90),
              child: Text(
                L.verifyCodeSentTo(widget.target),
                style: AppTypography.bodyLarge(context)
                    .copyWith(color: p.textSecondary),
              ),
            ),
            const SizedBox(height: 18),
            // Demo code hint — there's no real SMS/email engine yet.
            FadeSlideIn(
              delay: const Duration(milliseconds: 110),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        size: 16, color: AppColors.accentDeep),
                    const SizedBox(width: 8),
                    Expanded(
                      // Honestly labelled "Demo code" so it's never mistaken for
                      // a real delivered OTP — but the value stays visible so the
                      // demo flow still works until a real backend OTP lands.
                      child: Text(
                        '${L.demoCodeLabel}: $_code',
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w800,
                          color: AppColors.accentDeep,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 22),
            _CodeBoxes(
              controller: _ctrl,
              focusNode: _focus,
              length: _len,
              error: _error.isNotEmpty,
              onChanged: _onChanged,
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(_error,
                  style: AppTypography.bodySmall(context)
                      .copyWith(color: AppColors.red)),
            ],
            const SizedBox(height: 22),
            PrimaryButton(
              label: L.verifyWord,
              height: 56,
              icon: Icons.check_rounded,
              onPressed: ready ? _verify : null,
            ),
            const SizedBox(height: 14),
            Center(
              child: GestureDetector(
                onTap: _resend,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    _resendIn > 0 ? L.resendInSec(_resendIn) : L.resendCode,
                    style: GoogleFonts.nunito(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color:
                          _resendIn > 0 ? p.textTertiary : AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Four digit boxes driven by a single transparent text field on top — taps
/// anywhere focus it and the boxes reflect what's typed.
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
                    duration: const Duration(milliseconds: 150),
                    height: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: p.cardAlt,
                      borderRadius: BorderRadius.circular(16),
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
                    ),
                    child: Text(
                      i < value.length ? value[i] : '',
                      style: GoogleFonts.nunito(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: p.text,
                      ),
                    ),
                  ),
                ),
                if (i < length - 1) const SizedBox(width: 12),
              ],
            ],
          ),
          // Invisible capture field on top.
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
