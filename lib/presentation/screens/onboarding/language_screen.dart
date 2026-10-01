import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
/// Motion has two jobs here. Until a choice is made we don't know which
/// language this person reads, so the heading takes turns asking in all three.
/// Once they tap, the heading settles on their language and the chosen card
/// fills in, so the choice is confirmed before the screen moves on.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.next});

  /// Where to go once a language is picked. A widget rather than a callback,
  /// for the same reason as [ConsentScreen.next]: the navigation must run on
  /// this screen's own context.
  final Widget next;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  /// Uzbek first: Fade launches in Uzbekistan.
  static const _order = [AppLanguage.uz, AppLanguage.ru, AppLanguage.en];

  /// "Choose your language", each in its own language.
  static const _ask = {
    AppLanguage.uz: 'Tilni tanlang',
    AppLanguage.ru: 'Выберите язык',
    AppLanguage.en: 'Choose your language',
  };

  /// Long enough to read a short phrase in an unfamiliar script.
  static const _cycleEvery = Duration(milliseconds: 2400);

  /// How long the confirmed choice stays on screen before moving on.
  static const _confirmHold = Duration(milliseconds: 520);

  Timer? _cycle;
  int _shown = 0;
  AppLanguage? _picked;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduceMotion) {
      _cycle?.cancel();
      _cycle = null;
    } else if (_cycle == null && _picked == null) {
      _cycle = Timer.periodic(_cycleEvery, (_) {
        if (!mounted || _picked != null) return;
        setState(() => _shown = (_shown + 1) % _order.length);
      });
    }
  }

  @override
  void dispose() {
    _cycle?.cancel();
    super.dispose();
  }

  Future<void> _pick(AppLanguage language) async {
    if (_picked != null) return; // one choice; ignore taps while confirming
    HapticFeedback.selectionClick();
    _cycle?.cancel();
    setState(() {
      _picked = language;
      _shown = _order.indexOf(language);
    });
    AppState.instance.setLanguage(language);
    if (!_reduceMotion) await Future<void>.delayed(_confirmHold);
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(FadeThroughPageRoute(child: widget.next));
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final reduce = _reduceMotion;
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
                child: Semantics(
                  // Screen readers get all three at once, never a moving target.
                  label: _order.map((l) => _ask[l]).join('. '),
                  child: ExcludeSemantics(
                    child: reduce
                        ? _StaticHeading(ask: _ask, order: _order)
                        : _CyclingHeading(text: _ask[_order[_shown]]!),
                  ),
                ),
              ),
              if (!reduce) ...[
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: _CycleDots(count: _order.length, active: _shown),
                ),
              ],
              const Spacer(),
              for (var i = 0; i < _order.length; i++) ...[
                FadeSlideIn(
                  delay: Duration(milliseconds: 220 + 90 * i),
                  child: _LanguageRow(
                    language: _order[i],
                    // The row being asked about right now is lifted a little,
                    // tying the heading to its card.
                    spotlit: _picked == null && !reduce && _shown == i,
                    selected: _picked == _order[i],
                    dimmed: _picked != null && _picked != _order[i],
                    onTap: () => _pick(_order[i]),
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

/// The heading, swapping phrases with a short rise-and-fade. One line, scaled
/// down rather than wrapped, so a longer phrase never pushes the layout.
class _CyclingHeading extends StatelessWidget {
  const _CyclingHeading({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.display(context);
    return SizedBox(
      height: (style.fontSize ?? 34) * 1.3,
      width: double.infinity,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 460),
        reverseDuration: const Duration(milliseconds: 340),
        switchInCurve: AppCurves.easeOutQuart,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.centerLeft,
          children: [...previous, if (current != null) current],
        ),
        transitionBuilder: (child, animation) {
          // Incoming phrases rise into place; outgoing ones keep rising away.
          final incoming = child.key == ValueKey(text);
          final slide = Tween<Offset>(
            begin: incoming ? const Offset(0, 0.45) : const Offset(0, -0.45),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: FittedBox(
          key: ValueKey(text),
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, style: style, maxLines: 1),
        ),
      ),
    );
  }
}

/// Reduced motion: no cycling, just all three phrases at once.
class _StaticHeading extends StatelessWidget {
  const _StaticHeading({required this.ask, required this.order});

  final Map<AppLanguage, String> ask;
  final List<AppLanguage> order;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(ask[order.first]!, style: AppTypography.display(context)),
        const SizedBox(height: 8),
        Text(order.skip(1).map((l) => ask[l]).join(' · '),
            style: AppTypography.bodySmall(context)),
      ],
    );
  }
}

/// Three small marks under the heading; the active one stretches, showing
/// the heading is taking turns rather than glitching.
class _CycleDots extends StatelessWidget {
  const _CycleDots({required this.count, required this.active});

  final int count;
  final int active;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Row(
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 360),
            curve: AppCurves.easeOutQuart,
            margin: const EdgeInsets.only(right: 6),
            width: i == active ? 22 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == active
                  ? AppColors.accent
                  : p.textTertiary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
      ],
    );
  }
}

/// One language as a full-width card: its code badge and its own name.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.language,
    required this.onTap,
    this.spotlit = false,
    this.selected = false,
    this.dimmed = false,
  });

  final AppLanguage language;
  final VoidCallback onTap;

  /// The heading is currently asking in this language.
  final bool spotlit;

  /// This is the language that was tapped.
  final bool selected;

  /// Another language was tapped; this one steps back.
  final bool dimmed;

  static const _dur = Duration(milliseconds: 260);

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final fg = selected ? Colors.white : p.text;
    return Semantics(
      button: true,
      selected: selected,
      child: AnimatedOpacity(
        duration: _dur,
        curve: AppCurves.easeOutQuart,
        opacity: dimmed ? 0.35 : 1,
        child: AnimatedSlide(
          duration: _dur,
          curve: AppCurves.easeOutQuart,
          offset: dimmed ? const Offset(0, 0.06) : Offset.zero,
          child: PressableScale(
            onTap: onTap,
            child: AnimatedContainer(
              duration: _dur,
              curve: AppCurves.easeOutQuart,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : p.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.accent
                      : spotlit
                          ? AppColors.accent.withValues(alpha: 0.45)
                          : p.border,
                  width: spotlit || selected ? 1.6 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(
                        alpha: selected ? 0.35 : (spotlit ? 0.14 : 0)),
                    blurRadius: selected ? 22 : 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: _dur,
                    curve: AppCurves.easeOutQuart,
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.22)
                          : AppColors.accentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    // The code badge turns into a check: the confirmation.
                    child: AnimatedSwitcher(
                      duration: _dur,
                      switchInCurve: AppCurves.easeOutQuart,
                      transitionBuilder: (child, a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(
                          scale: Tween(begin: 0.6, end: 1.0).animate(a),
                          child: child,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              key: ValueKey('check'),
                              size: 24,
                              color: Colors.white)
                          : Text(
                              language.code,
                              key: const ValueKey('code'),
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                                color: AppColors.accent,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: _dur,
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                      child: Text(language.label),
                    ),
                  ),
                  AnimatedSlide(
                    duration: _dur,
                    curve: AppCurves.easeOutQuart,
                    offset: selected ? const Offset(0.4, 0) : Offset.zero,
                    child: Icon(Icons.chevron_right_rounded,
                        color: selected
                            ? Colors.white
                            : spotlit
                                ? AppColors.accent
                                : p.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
