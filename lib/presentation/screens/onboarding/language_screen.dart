import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';

/// The very first question: which language.
///
/// It comes before onboarding and, crucially, before the Terms and Privacy
/// Policy. Consent is recorded as proof that someone agreed, and that proof is
/// only worth something if they could read what they agreed to. The legal
/// documents are trilingual and open in the app's language, so asking here is
/// what makes them readable.
///
/// The heading is written in all three languages at once on purpose: until a
/// choice is made we don't know which one this person reads.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key, required this.next});

  /// Where to go once a language is picked. A widget rather than a callback,
  /// for the same reason as [ConsentScreen.next]: the navigation must run on
  /// this screen's own context.
  final Widget next;

  /// Uzbek first: Fade launches in Uzbekistan.
  static const _order = [AppLanguage.uz, AppLanguage.ru, AppLanguage.en];

  void _pick(BuildContext context, AppLanguage language) {
    AppState.instance.setLanguage(language);
    Navigator.of(context).pushReplacement(FadeThroughPageRoute(child: next));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(child: BarberLogo(size: 30)),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child: Text('Tilni tanlang',
                    style: AppTypography.display(context)),
              ),
              const SizedBox(height: 8),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Text('Выберите язык · Choose your language',
                    style: AppTypography.bodySmall(context)),
              ),
              const Spacer(),
              for (var i = 0; i < _order.length; i++) ...[
                FadeSlideIn(
                  delay: Duration(milliseconds: 220 + 60 * i),
                  child: _LanguageRow(
                    language: _order[i],
                    onTap: () => _pick(context, _order[i]),
                  ),
                ),
                if (i < _order.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/// One language as a full-width card: its code badge and its own name.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({required this.language, required this.onTap});

  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                language.code,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                language.label,
                style: GoogleFonts.nunito(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.text,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}
