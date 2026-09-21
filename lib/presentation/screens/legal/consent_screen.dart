import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';
import 'legal_doc_screen.dart';

/// The first-run consent gate: an explicit ticked box agreeing to the Terms of
/// Use and Privacy Policy, recorded with a timestamp and the document version
/// (see [AppState.acceptLegal]).
///
/// This is deliberately EXPLICIT rather than the implied "by continuing you
/// agree" line on the sign-in screen: a recorded affirmative action is what
/// data-protection regimes and app stores expect, and it is the thing you can
/// actually point to if a user later disputes that they agreed.
///
/// It sits AFTER the onboarding hero (so a first-time visitor sees what Fade is
/// before a wall of legal text) and BEFORE the role choice / sign-in, i.e.
/// before any account exists or any personal data is collected.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.next});

  /// Where to go once the user agrees. Taken as a WIDGET (not a callback) so
  /// the navigation runs on this screen's own context — a callback built by the
  /// previous screen would capture a context that pushReplacement just disposed.
  final Widget next;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;

  void _open(String docKey) {
    Navigator.of(context).push(
      FadeThroughPageRoute(child: LegalDocScreen(docKey: docKey)),
    );
  }

  void _accept() {
    if (!_agreed) return;
    AppState.instance.acceptLegal(); // records tick + timestamp + version
    Navigator.of(context)
        .pushReplacement(FadeThroughPageRoute(child: widget.next));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FadeSlideIn(child: BarberLogo(size: 30)),
              const SizedBox(height: 28),
              FadeSlideIn(
                delay: const Duration(milliseconds: 80),
                child:
                    Text(L.consentTitle, style: AppTypography.display(context)),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 140),
                child: Text(L.consentSub,
                    style: AppTypography.bodySmall(context)),
              ),
              const SizedBox(height: 26),
              // The two documents, each opening the full in-app reader.
              FadeSlideIn(
                delay: const Duration(milliseconds: 200),
                child: _DocRow(
                  icon: Icons.description_outlined,
                  label: L.consentOpenTerms,
                  onTap: () => _open('terms'),
                ),
              ),
              const SizedBox(height: 10),
              FadeSlideIn(
                delay: const Duration(milliseconds: 240),
                child: _DocRow(
                  icon: Icons.privacy_tip_outlined,
                  label: L.consentOpenPrivacy,
                  onTap: () => _open('privacy'),
                ),
              ),
              const Spacer(),
              // The tick itself — the whole row is tappable, so the small box is
              // never the only target.
              FadeSlideIn(
                delay: const Duration(milliseconds: 300),
                child: _AgreeTick(
                  value: _agreed,
                  onChanged: (v) => setState(() => _agreed = v),
                ),
              ),
              const SizedBox(height: 10),
              Text(L.consentAgeNote, style: AppTypography.caption(context)),
              const SizedBox(height: 16),
              FadeSlideIn(
                delay: const Duration(milliseconds: 340),
                child: PrimaryButton(
                  label: L.consentContinue,
                  // Disabled until the box is ticked — consent must be an
                  // affirmative act, never a default.
                  onPressed: _agreed ? _accept : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable row that opens one of the legal documents.
class _DocRow extends StatelessWidget {
  const _DocRow(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.nunito(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.text)),
            ),
            Icon(Icons.chevron_right_rounded, color: p.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// The consent checkbox + its label, as one large tap target.
class _AgreeTick extends StatelessWidget {
  const _AgreeTick({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // While UNCHECKED the box breathes — an accent halo swells and the
          // border pulses, so the eye is drawn to the one action left to take.
          // The moment it's ticked the animation stops and it settles solid.
          Breathe(
            period: const Duration(milliseconds: 1500),
            builder: (context, t) {
              // Only pulse while empty; a ticked box is calm.
              final glow = value ? 0.0 : t;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: AppCurves.easeOutQuart,
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: value ? AppColors.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    // Border brightens toward the accent as it breathes.
                    color: value
                        ? AppColors.accent
                        : Color.lerp(p.border, AppColors.accent, glow)!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.55 * glow),
                      blurRadius: 6 + 10 * glow,
                      spreadRadius: 1 + 2 * glow,
                    ),
                  ],
                ),
                child: value
                    ? const Icon(Icons.check_rounded,
                        size: 18, color: Colors.white)
                    : null,
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                L.consentCheckbox,
                style: GoogleFonts.nunito(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                  color: p.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
