import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/primary_button.dart';

const String _supportEmail = 'bizningproject@gmail.com';

/// "Help & feedback" — a bottom sheet where anyone (client or barber) can
/// report a bug, pitch an idea, or just say something's wrong. Saved locally
/// (syncs to the backend later); an email handoff is one tap away.
Future<void> showSupportSheet(BuildContext context) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _SupportSheet(),
  );
}

class _SupportSheet extends StatefulWidget {
  const _SupportSheet();

  @override
  State<_SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<_SupportSheet> {
  final TextEditingController _message = TextEditingController();
  final TextEditingController _contact = TextEditingController();
  int _category = 0; // 0 bug · 1 idea · 2 other
  bool _sent = false;

  List<(IconData, String)> get _categories => [
        (Icons.bug_report_rounded, L.fbBug),
        (Icons.lightbulb_rounded, L.fbIdea),
        (Icons.chat_bubble_rounded, L.fbOther),
      ];

  @override
  void dispose() {
    _message.dispose();
    _contact.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final msg = _message.text.trim();
    if (msg.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(L.fbEmpty),
          behavior: SnackBarBehavior.floating,
        ));
      return;
    }
    HapticFeedback.mediumImpact();
    await AppState.instance.submitFeedback(
      category: const ['bug', 'idea', 'other'][_category],
      message: msg,
      contact: _contact.text.trim().isEmpty ? null : _contact.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sent = true);
    // Auto-dismiss after the thank-you beat.
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  Future<void> _email() async {
    final subject = Uri.encodeComponent('Fade feedback');
    final body = Uri.encodeComponent(_message.text.trim());
    await launchUrl(
      Uri.parse('mailto:$_supportEmail?subject=$subject&body=$body'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        // Scrollable so the form never overflows when the keyboard is up (the
        // autofocused 4-line field + chips + button exceed the space otherwise).
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _sent ? _thanks(p) : _form(p),
          ),
        ),
      ),
    );
  }

  /// The thank-you beat after sending.
  Widget _thanks(PaperPalette p) {
    return Column(
      key: const ValueKey('thanks'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 26),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.green.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child:
              const Icon(Icons.check_rounded, size: 38, color: AppColors.green),
        ),
        const SizedBox(height: 16),
        Text(L.fbThanks, style: AppTypography.h2(context)),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _form(PaperPalette p) {
    return Column(
      key: const ValueKey('form'),
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
        Text(L.feedbackTitle, style: AppTypography.h2(context)),
        const SizedBox(height: 4),
        Text(L.feedbackSub, style: AppTypography.bodySmall(context)),
        const SizedBox(height: 16),
        // Category chips.
        Row(
          children: [
            for (final (i, c) in _categories.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _category = i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 44,
                    decoration: BoxDecoration(
                      color: _category == i
                          ? AppColors.accent.withValues(alpha: 0.14)
                          : p.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            _category == i ? AppColors.accent : p.border,
                        width: _category == i ? 1.4 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c.$1,
                            size: 16,
                            color: _category == i
                                ? AppColors.accent
                                : p.textTertiary),
                        const SizedBox(width: 6),
                        Text(c.$2,
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color:
                                  _category == i ? AppColors.accent : p.text,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _message,
          maxLines: 4,
          maxLength: 500,
          autofocus: true,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: p.text),
          cursorColor: AppColors.accent,
          decoration: _dec(p, L.fbMessageHint),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contact,
          maxLines: 1,
          style: GoogleFonts.nunito(fontWeight: FontWeight.w600, color: p.text),
          cursorColor: AppColors.accent,
          decoration: _dec(p, L.fbContactHint),
        ),
        const SizedBox(height: 16),
        PrimaryButton(
          label: L.fbSend,
          icon: Icons.send_rounded,
          height: 54,
          onPressed: _send,
        ),
        const SizedBox(height: 10),
        Center(
          child: GestureDetector(
            onTap: _email,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alternate_email_rounded,
                      size: 14, color: p.textSecondary),
                  const SizedBox(width: 5),
                  Text('${L.fbEmailUs} · $_supportEmail',
                      style: GoogleFonts.nunito(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: p.textSecondary,
                      )),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _dec(PaperPalette p, String hint) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      counterText: '',
      filled: true,
      fillColor: p.card,
      hintStyle: GoogleFonts.nunito(color: p.textTertiary),
      border: border(p.border),
      enabledBorder: border(p.border),
      focusedBorder: border(AppColors.accent, 1.5),
    );
  }
}
