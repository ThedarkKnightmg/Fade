import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/animations/app_animations.dart';
import '../../../core/animations/motion.dart';
import '../../../core/i18n/app_language.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// The very first question: which language.
///
/// It comes before onboarding and, crucially, before the Terms and Privacy
/// Policy. Consent is recorded as proof that someone agreed, and that proof is
/// only worth something if they could read what they agreed to. The legal
/// documents are trilingual and open in the app's language, so asking here is
/// what makes them readable.
///
/// Tapping a language only selects it, and previews the whole screen in it;
/// Continue commits. Until something is picked we don't know which language
/// this person reads, so the heading takes turns asking in all three, and a
/// single highlight travels between the cards to show which one is meant.
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, required this.next});

  /// Where to go once a language is confirmed. A widget rather than a
  /// callback, for the same reason as [ConsentScreen.next]: the navigation
  /// must run on this screen's own context.
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

  Timer? _cycle;
  int _shown = 0;
  AppLanguage? _picked;
  bool _leaving = false;

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// The card the heading and the highlight point at right now.
  int get _focus => _picked == null ? _shown : _order.indexOf(_picked!);

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

  void _select(AppLanguage language) {
    if (_leaving || _picked == language) return;
    HapticFeedback.selectionClick();
    _cycle?.cancel();
    setState(() => _picked = language);
    // Preview, don't commit: the screen (and its button) switch language
    // live, and nothing is recorded until Continue.
    AppState.instance.previewLanguage(language);
  }

  void _continue() {
    final picked = _picked;
    if (picked == null || _leaving) return;
    _leaving = true;
    HapticFeedback.lightImpact();
    AppState.instance.setLanguage(picked);
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
                        : _FadeSweepHeading(text: _ask[_order[_focus]]!),
                  ),
                ),
              ),
              if (!reduce) ...[
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 140),
                  child: _CycleDots(count: _order.length, active: _focus),
                ),
              ],
              const Spacer(),
              FadeSlideIn(
                delay: const Duration(milliseconds: 220),
                child: _LanguageList(
                  order: _order,
                  focus: _focus,
                  picked: _picked,
                  reduceMotion: reduce,
                  onSelect: _select,
                ),
              ),
              const SizedBox(height: 18),
              _ContinueButton(
                visible: _picked != null,
                reduceMotion: reduce,
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three cards plus the one highlight that travels between them.
///
/// Built in three layers so the highlight reads as a single object moving
/// over the cards: plain card backgrounds at the bottom, the highlight in the
/// middle, and the cards' content (and tap targets) on top.
class _LanguageList extends StatefulWidget {
  const _LanguageList({
    required this.order,
    required this.focus,
    required this.picked,
    required this.reduceMotion,
    required this.onSelect,
  });

  final List<AppLanguage> order;
  final int focus;
  final AppLanguage? picked;
  final bool reduceMotion;
  final ValueChanged<AppLanguage> onSelect;

  @override
  State<_LanguageList> createState() => _LanguageListState();
}

class _LanguageListState extends State<_LanguageList>
    with TickerProviderStateMixin {
  static const double _cardH = 76;
  static const double _gap = 12;

  // The highlight's travel. Its top and bottom edges move on different
  // curves: the edge facing the destination leaves first and the other one
  // follows, so mid-move it stretches across both cards and then pulls
  // itself together, like the liquid tab bar.
  late final AnimationController _move = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  // Ghost outline (0) to solid fill (1), once a language is actually picked.
  late final AnimationController _fill = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  static const Curve _lead = Cubic(0.2, 0.9, 0.3, 1); // quick, then settles
  static const Curve _trail = Cubic(0.55, 0, 0.25, 1); // waits, then catches up

  double _fromTop = 0, _fromBottom = _cardH;
  double _toTop = 0, _toBottom = _cardH;

  double _top(int i) => i * (_cardH + _gap);

  (double, double) get _current {
    final t = _move.value;
    final down = _toTop >= _fromTop;
    final topT = (down ? _trail : _lead).transform(t);
    final bottomT = (down ? _lead : _trail).transform(t);
    return (
      lerpDouble(_fromTop, _toTop, topT)!,
      lerpDouble(_fromBottom, _toBottom, bottomT)!,
    );
  }

  @override
  void initState() {
    super.initState();
    _jumpTo(widget.focus);
    if (widget.picked != null) _fill.value = 1;
  }

  void _jumpTo(int i) {
    _fromTop = _toTop = _top(i);
    _fromBottom = _toBottom = _top(i) + _cardH;
    _move.value = 1;
  }

  @override
  void didUpdateWidget(_LanguageList old) {
    super.didUpdateWidget(old);
    if (old.focus != widget.focus) {
      if (widget.reduceMotion) {
        _jumpTo(widget.focus);
      } else {
        // Start from wherever the highlight is right now, so a quick second
        // tap redirects it mid-flight instead of snapping back first.
        final (top, bottom) = _current;
        _fromTop = top;
        _fromBottom = bottom;
        _toTop = _top(widget.focus);
        _toBottom = _toTop + _cardH;
        _move.forward(from: 0);
      }
    }
    if (old.picked == null && widget.picked != null) {
      widget.reduceMotion ? _fill.value = 1 : _fill.forward();
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final n = widget.order.length;
    final height = n * _cardH + (n - 1) * _gap;
    // With reduced motion there's no travelling outline to follow, so the
    // highlight only appears once something is chosen.
    final showGhost = !widget.reduceMotion;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          for (var i = 0; i < n; i++)
            Positioned(
              top: _top(i),
              left: 0,
              right: 0,
              height: _cardH,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: p.border),
                ),
              ),
            ),
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_move, _fill]),
                builder: (context, _) {
                  final f = _fill.value;
                  if (!showGhost && f == 0) return const SizedBox.shrink();
                  final (top, bottom) = _current;
                  return Stack(children: [
                    Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      height: bottom - top,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: f),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent
                                .withValues(alpha: 0.45 + 0.55 * f),
                            width: 1.6,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent
                                  .withValues(alpha: 0.14 + 0.21 * f),
                              blurRadius: 14 + 8 * f,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]);
                },
              ),
            ),
          ),
          for (var i = 0; i < n; i++)
            Positioned(
              top: _top(i),
              left: 0,
              right: 0,
              height: _cardH,
              child: _LanguageCardContent(
                language: widget.order[i],
                selected: widget.picked == widget.order[i],
                reduceMotion: widget.reduceMotion,
                onTap: () => widget.onSelect(widget.order[i]),
              ),
            ),
        ],
      ),
    );
  }
}

/// What sits on a card: the code badge and the language's own name. Its
/// background comes from the layers underneath.
class _LanguageCardContent extends StatelessWidget {
  const _LanguageCardContent({
    required this.language,
    required this.selected,
    required this.reduceMotion,
    required this.onTap,
  });

  final AppLanguage language;
  final bool selected;
  final bool reduceMotion;
  final VoidCallback onTap;

  // Matched to the highlight's travel: the card's colours hold for the first
  // part of the move and switch as the highlight lands, so the text never
  // turns white over a still-white card (or dark over a still-blue one).
  static const _dur = Duration(milliseconds: 480);
  static const _land = Interval(0.4, 1, curve: Curves.easeOut);
  // The card being left switches back early, as the highlight pulls away.
  static const _leave = Interval(0, 0.45, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          color: Colors.transparent, // whole card is the tap target
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AnimatedContainer(
                duration: _dur,
                curve: selected ? _land : _leave,
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                // The code badge turns into a check when chosen.
                child: AnimatedSwitcher(
                  duration: _dur,
                  switchInCurve: selected ? _land : _leave,
                  transitionBuilder: (child, a) =>
                      FadeTransition(opacity: a, child: child),
                  child: selected
                      ? TweenAnimationBuilder<double>(
                          key: const ValueKey('check'),
                          // Drawn as the highlight lands, like a pen stroke.
                          tween: Tween(begin: reduceMotion ? 1 : 0, end: 1),
                          duration: const Duration(milliseconds: 460),
                          curve: const Interval(0.4, 1,
                              curve: Curves.easeOutCubic),
                          builder: (context, v, _) => CustomPaint(
                            size: const Size(24, 24),
                            painter: _CheckStroke(v),
                          ),
                        )
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
                  curve: selected ? _land : _leave,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : p.text,
                  ),
                  child: Text(language.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Continue: hidden until a language is picked, then it rises into place.
/// Its label is already in the picked language because the screen previews
/// the choice live.
class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.visible,
    required this.reduceMotion,
    required this.onPressed,
  });

  final bool visible;
  final bool reduceMotion;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dur =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 420);
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        duration: dur,
        curve: AppCurves.easeOutQuart,
        opacity: visible ? 1 : 0,
        child: AnimatedSlide(
          duration: dur,
          curve: AppCurves.easeOutQuart,
          offset: visible ? Offset.zero : const Offset(0, 0.6),
          child: PrimaryButton(
            label: L.languageNext,
            onPressed: visible ? onPressed : null,
          ),
        ),
      ),
    );
  }
}

/// The heading, changing phrases the way clippers blend a fade.
///
/// Fade is named after the haircut, so the heading borrows its look: a soft
/// gradient band sweeps left to right like a clipper pass. Behind the band the
/// new phrase is combed in; ahead of it the old one is still there, dissolving
/// as the band reaches it. A thin glowing line rides the leading edge, the
/// clipper itself. One line, scaled down rather than wrapped, so a longer
/// phrase never pushes the layout.
class _FadeSweepHeading extends StatefulWidget {
  const _FadeSweepHeading({required this.text});

  final String text;

  @override
  State<_FadeSweepHeading> createState() => _FadeSweepHeadingState();
}

class _FadeSweepHeadingState extends State<_FadeSweepHeading>
    with SingleTickerProviderStateMixin {
  /// Width of the soft blend between old and new, as a fraction of the line.
  static const double _band = 0.22;

  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
    value: 1,
  );

  late String _current = widget.text;
  String? _previous;

  @override
  void didUpdateWidget(_FadeSweepHeading old) {
    super.didUpdateWidget(old);
    if (widget.text != _current) {
      _previous = _current;
      _current = widget.text;
      _sweep.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  /// The phrase, masked to the part of the line the sweep has (or hasn't)
  /// reached. [revealed] shows it behind the band; otherwise ahead of it.
  Widget _masked(String text, TextStyle style, double edge,
      {required bool revealed}) {
    final from = edge.clamp(0.0, 1.0);
    final to = (edge + _band).clamp(0.0, 1.0);
    const on = Colors.white, off = Colors.transparent;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => LinearGradient(
        colors: revealed ? const [on, on, off, off] : const [off, off, on, on],
        stops: [0, from, to, 1],
      ).createShader(rect),
      child: SizedBox(
        width: double.infinity,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(text, style: style, maxLines: 1),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.display(context);
    final height = (style.fontSize ?? 34) * 1.3;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, box) => AnimatedBuilder(
          animation: _sweep,
          builder: (context, _) {
            final v = _sweep.value;
            // From the first frame (v == 0, old phrase whole) to the last.
            final moving = _previous != null && v < 1;
            final t = Curves.easeInOutCubic.transform(v);
            // The band starts just off the left edge and leaves off the right.
            final edge = -_band + (1 + _band) * t;
            return Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                if (moving) _masked(_previous!, style, edge, revealed: false),
                moving
                    ? _masked(_current, style, edge, revealed: true)
                    : _masked(_current, style, 2, revealed: true),
                if (moving)
                  Positioned(
                    left: (edge + _band * 0.5) * box.maxWidth,
                    top: -height * 0.1,
                    bottom: -height * 0.1,
                    child: Opacity(
                      // Strongest mid-pass, so it eases in and out of view.
                      opacity: math.sin(math.pi * t),
                      child: Container(
                        width: 2.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.accent.withValues(alpha: 0),
                              AppColors.accent,
                              AppColors.accent.withValues(alpha: 0),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.55),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
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

/// Three small marks under the heading; the active one stretches.
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

/// A check mark drawn up to [progress]: the short stroke down, then the long
/// one up, with round ends.
class _CheckStroke extends CustomPainter {
  _CheckStroke(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w * 0.2, h * 0.52)
      ..lineTo(w * 0.42, h * 0.73)
      ..lineTo(w * 0.8, h * 0.29);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * progress),
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckStroke old) => old.progress != progress;
}
