import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/fade_points_pill.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// "Toza chiziq" (Clean Line) — the steady-hand game.
///
/// Deliberately the OPPOSITE rhythm to Scissor Master. That one is fast, loud
/// and reflexive; a second reflex game would only compete with it and neither
/// would be the one you reach for. This is slow, quiet and precise: it rewards
/// NOT rushing, which is a different itch and a better companion inside the
/// same five minutes of waiting.
///
/// The fiction is the thing a barber is actually judged on — one clean fade
/// line, drawn in a single unbroken pass. You trace a dotted guide; the closer
/// your finger hugs it, the higher the accuracy. Leave the corridor, or lift
/// off halfway, and the hand has slipped and the line is ruined.
class CleanLineGame extends StatefulWidget {
  const CleanLineGame({super.key});

  @override
  State<CleanLineGame> createState() => _CleanLineGameState();
}

/// retry: a hand slipped but another is left, so the same line is tried again.
enum _Phase { idle, drawing, retry, slipped, done }

class _CleanLineGameState extends State<CleanLineGame>
    with SingleTickerProviderStateMixin {
  final _rng = math.Random();

  /// Slips a run can survive. One slip used to end the whole run, so a single
  /// twitch on level 1 sent you back to the menu before the game had started.
  static const _handsPerRun = 2;
  int _hands = _handsPerRun;

  /// Where the hand slipped, shown as a mark so the miss can be learned from.
  Offset? _slipAt;

  /// Pulses the start marker until the trace begins.
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _syncPulse() {
    final want = _phase == _Phase.drawing &&
        _progress == 0 &&
        !(MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    if (want && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!want && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  _Phase _phase = _Phase.idle;
  Size _field = Size.zero;

  /// Evenly sampled points of the guide the player must follow.
  List<Offset> _guide = const [];

  /// How far along [_guide] the player has legitimately traced.
  int _progress = 0;

  /// Every deviation recorded while tracing — this becomes the accuracy score.
  final List<double> _errors = [];

  int _level = 1;
  int _score = 0;
  bool _wasRecord = false;
  int _lastAccuracy = 0;
  int _awarded = 0;

  /// How far the finger may stray before the line is ruined. Tightens with the
  /// level: the difficulty here is precision, never speed.
  double get _tolerance => math.max(16, 34 - _level * 2.4);

  void _start() {
    setState(() {
      _phase = _Phase.drawing;
      _level = 1;
      _score = 0;
      _awarded = 0;
      _hands = _handsPerRun;
      _slipAt = null;
      _buildGuide();
    });
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _phase = _Phase.drawing;
      _slipAt = null;
      _buildGuide();
    });
  }

  /// Same line, fresh attempt (after a slip with a hand to spare).
  void _retryLine() {
    setState(() {
      _phase = _Phase.drawing;
      _progress = 0;
      _errors.clear();
      _slipAt = null;
    });
  }

  /// A fresh fade line: a cubic curve across the head, wavier as levels climb.
  void _buildGuide() {
    _progress = 0;
    _errors.clear();
    final w = _field.width, h = _field.height;
    if (w <= 0) return;

    final wobble = math.min(0.30, 0.06 + _level * 0.035);
    final start = Offset(w * 0.14, h * (0.36 + _rng.nextDouble() * 0.22));
    final end = Offset(w * 0.86, h * (0.36 + _rng.nextDouble() * 0.22));
    final c1 = Offset(
      w * (0.32 + (_rng.nextDouble() - 0.5) * 0.16),
      start.dy + h * (_rng.nextDouble() - 0.5) * wobble * 2,
    );
    final c2 = Offset(
      w * (0.68 + (_rng.nextDouble() - 0.5) * 0.16),
      end.dy + h * (_rng.nextDouble() - 0.5) * wobble * 2,
    );

    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);

    // Sample evenly along the curve so "distance along the line" is a real
    // measure — indexing raw bezier parameters would bunch up on the bends.
    final PathMetric metric = path.computeMetrics().first;
    const samples = 160;
    _guide = [
      for (var i = 0; i <= samples; i++)
        metric.getTangentForOffset(metric.length * i / samples)!.position,
    ];
  }

  void _onDrag(Offset p) {
    if (_phase != _Phase.drawing || _guide.isEmpty) return;

    // Only ever look FORWARD along the guide, and only a short way. Searching
    // the whole line would let a player scrub backwards, or skip a gap and
    // "finish" a line they never actually traced.
    var bestI = -1;
    var bestD = double.infinity;
    final window = math.min(_guide.length, _progress + 14);
    for (var i = _progress; i < window; i++) {
      final d = (p - _guide[i]).distance;
      if (d < bestD) {
        bestD = d;
        bestI = i;
      }
    }
    if (bestI < 0) return;

    if (bestD > _tolerance) {
      // Before the trace has begun, a finger elsewhere isn't a slip; it just
      // hasn't found the start yet. (It used to end the run on touch-down.)
      if (_progress == 0) return;
      _slip(at: p);
      return;
    }

    setState(() {
      _progress = bestI;
      _errors.add(bestD);
      if (_progress >= _guide.length - 3) _finishLine();
    });
  }

  void _slip({Offset? at}) {
    if (_phase != _Phase.drawing) return;
    HapticFeedback.heavyImpact();
    _slipAt = at ?? (_progress < _guide.length ? _guide[_progress] : null);
    _hands--;
    if (_hands > 0) {
      setState(() => _phase = _Phase.retry);
      return;
    }
    _wasRecord = AppState.instance.recordLineGameScore(_score);
    setState(() => _phase = _Phase.slipped);
  }

  /// A completed line scores on how tightly it hugged the guide.
  void _finishLine() {
    final avg = _errors.isEmpty
        ? 0.0
        : _errors.reduce((a, b) => a + b) / _errors.length;
    final accuracy = (100 * (1 - (avg / _tolerance))).clamp(0, 100).round();
    _lastAccuracy = accuracy;
    _score += accuracy;
    _wasRecord = AppState.instance.recordLineGameScore(_score);
    HapticFeedback.mediumImpact();

    // A near-flawless line earns a Fade Point token — drawn from the SAME daily
    // allowance the other game uses, so having two games never means twice the
    // money. The 90% bar keeps it a reward for a genuinely clean pass.
    if (accuracy >= 90) {
      final som = AppState.instance.claimGameToken();
      if (som > 0) _awarded += som;
    }

    _phase = _Phase.done;
  }

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final state = AppState.instance;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Row(
                children: [
                  CircleBtn(
                    icon: Icons.arrow_back_rounded,
                    size: 42,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (_phase == _Phase.drawing) ...[
                    // Steady hands left this run.
                    for (var i = 0; i < _handsPerRun; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.back_hand_rounded,
                          size: 18,
                          color: i < _hands
                              ? AppColors.accent
                              : p.textTertiary.withValues(alpha: 0.35),
                        ),
                      ),
                    const SizedBox(width: 6),
                    MiniPill('${L.lineGameLevel} $_level'),
                  ] else
                    FadePointsPill(
                      som: state.pointsBalanceSom,
                      scale: 0.82,
                      animate: false,
                    ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final needsGuide = _field.width == 0 && _guide.isEmpty;
                  _field = Size(box.maxWidth, box.maxHeight);
                  if (needsGuide) {
                    // The guide needs the field size, which only exists after
                    // layout — build it on the next frame, not during build.
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(_buildGuide);
                    });
                  }
                  _syncPulse();
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (d) => _onDrag(d.localPosition),
                    onPanEnd: (_) {
                      // Lifting off mid-line ruins it. A fade is one pass —
                      // without this you could tap your way along in stages.
                      if (_phase == _Phase.drawing && _progress > 4) _slip();
                    },
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _LinePainter(
                              guide: _guide,
                              progress: _progress,
                              palette: p,
                              tolerance: _tolerance,
                              live: _phase == _Phase.drawing,
                              pulse: _pulse,
                              slipAt: _slipAt,
                              startLabel: L.lineGameStartHere,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Text(
                              '$_score',
                              style: AppTypography.h1(context).copyWith(
                                fontSize: 48,
                                height: 1,
                                color: _phase == _Phase.drawing
                                    ? p.text
                                    : p.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        if (_phase != _Phase.drawing)
                          Positioned.fill(child: _overlay(context, p)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlay(BuildContext context, PaperPalette p) {
    final body = AppTypography.body(context).copyWith(color: p.textSecondary);
    return Container(
      color: p.bg.withValues(alpha: _phase == _Phase.retry ? 0.62 : 0.90),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_phase == _Phase.idle) ...[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.gesture_rounded,
                  size: 34, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(L.lineGameTitle, style: AppTypography.h2(context)),
            const SizedBox(height: 8),
            Text(L.lineGameHowTo, textAlign: TextAlign.center, style: body),
          ] else if (_phase == _Phase.retry) ...[
            Text(
              L.lineGameSlipped,
              style: AppTypography.h2(context)
                  .copyWith(color: const Color(0xFFE2554E)),
            ),
            const SizedBox(height: 8),
            Text(L.lineGameHandsLeft(_hands), style: body),
          ] else if (_phase == _Phase.slipped) ...[
            Text(
              L.lineGameSlipped,
              style: AppTypography.h2(context)
                  .copyWith(color: const Color(0xFFE2554E)),
            ),
            const SizedBox(height: 8),
            Text('${L.gameBest} ${AppState.instance.lineGameBest}', style: body),
            if (_wasRecord) ...[
              const SizedBox(height: 4),
              Text(L.gameNewBest,
                  style: AppTypography.h4(context)
                      .copyWith(color: AppColors.accent)),
            ],
          ] else ...[
            Text(
              _lastAccuracy >= 90
                  ? L.lineGamePerfectLine
                  : L.lineGameAccuracy(_lastAccuracy),
              textAlign: TextAlign.center,
              style: AppTypography.h2(context).copyWith(color: AppColors.accent),
            ),
            if (_awarded > 0) ...[
              const SizedBox(height: 12),
              _RewardChip(som: _awarded),
            ],
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: PrimaryButton(
              label: switch (_phase) {
                _Phase.idle => L.gamePlay,
                _Phase.done => L.continueWord,
                _Phase.retry => L.lineGameRetry,
                _ => L.gameAgain,
              },
              icon: _phase == _Phase.done
                  ? Icons.arrow_forward_rounded
                  : (_phase == _Phase.retry
                      ? Icons.refresh_rounded
                      : Icons.play_arrow_rounded),
              height: 52,
              onPressed: switch (_phase) {
                _Phase.done => _nextLevel,
                _Phase.retry => _retryLine,
                _ => _start,
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardChip extends StatelessWidget {
  const _RewardChip({required this.som});
  final int som;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        gradient: FadePointsPill.gradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        L.gameEarnedPoints(som),
        style: AppTypography.bodySmall(context)
            .copyWith(color: Colors.white, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.guide,
    required this.progress,
    required this.palette,
    required this.tolerance,
    required this.live,
    required this.pulse,
    required this.startLabel,
    this.slipAt,
  }) : super(repaint: pulse);

  final List<Offset> guide;
  final int progress;
  final PaperPalette palette;
  final double tolerance;
  final bool live;
  final Animation<double> pulse;
  final String startLabel;
  final Offset? slipAt;

  /// The head the fade is cut on: a faint silhouette, with the hair side
  /// (above the line) shaded, so the line reads as a fade on a real head
  /// instead of a squiggle on grey.
  void _paintHead(Canvas canvas, Size size) {
    final head = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.50),
      width: size.width * 0.94,
      height: size.height * 0.78,
    );
    final shape = Path()..addOval(head);
    canvas.drawPath(
      shape,
      Paint()..color = palette.textTertiary.withValues(alpha: 0.05),
    );
    // Hair above the line, inside the head.
    final hair = Path()..moveTo(guide.first.dx - tolerance * 3, guide.first.dy);
    for (final g in guide) {
      hair.lineTo(g.dx, g.dy);
    }
    hair
      ..lineTo(guide.last.dx + tolerance * 3, guide.last.dy)
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.save();
    canvas.clipPath(shape);
    canvas.drawPath(
      Path.combine(PathOperation.intersect, hair, shape),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.text.withValues(alpha: 0.10),
            palette.text.withValues(alpha: 0.03),
          ],
        ).createShader(head),
    );
    canvas.restore();
    canvas.drawPath(
      shape,
      Paint()
        ..color = palette.textTertiary.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (guide.isEmpty) return;
    _paintHead(canvas, size);

    // The corridor, drawn at the real tolerance width. Showing it makes the
    // difficulty legible instead of something you only discover by failing.
    canvas.drawPath(
      Path()..addPolygon(guide, false),
      Paint()
        ..color = palette.textTertiary.withValues(alpha: live ? 0.10 : 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = tolerance * 2
        ..strokeCap = StrokeCap.round,
    );

    // The dotted guide down the middle of it.
    for (var i = 0; i < guide.length - 1; i += 6) {
      canvas.drawLine(
        guide[i],
        guide[math.min(i + 3, guide.length - 1)],
        Paint()
          ..color = palette.textTertiary.withValues(alpha: 0.55)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round,
      );
    }

    // The part already traced, in accent — visible progress along the cut.
    if (progress > 1) {
      canvas.drawPath(
        Path()..addPolygon(guide.sublist(0, progress + 1), false),
        Paint()
          ..color = AppColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      // The leading edge — where the blade is right now.
      canvas.drawCircle(guide[progress], 9, Paint()..color = AppColors.accent);
      canvas.drawCircle(guide[progress], 4, Paint()..color = Colors.white);
    }

    // Where to begin: a pulsing ring on the line's first point, labelled,
    // until the trace starts.
    if (live && progress == 0) {
      final s = guide.first;
      final v = pulse.value;
      canvas.drawCircle(
        s,
        12 + 16 * v,
        Paint()
          ..color = AppColors.accent.withValues(alpha: 0.35 * (1 - v))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      canvas.drawCircle(s, 10, Paint()..color = AppColors.accent);
      canvas.drawCircle(s, 4, Paint()..color = Colors.white);
      final tp = TextPainter(
        text: TextSpan(
          text: startLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.accent,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(s.dx - 6, s.dy - 34));
    }

    // Where the hand slipped.
    final at = slipAt;
    if (at != null) {
      final red = Paint()
        ..color = const Color(0xFFE2554E)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      const r = 9.0;
      canvas.drawCircle(at, 16,
          Paint()..color = const Color(0xFFE2554E).withValues(alpha: 0.16));
      canvas.drawLine(at + const Offset(-r, -r), at + const Offset(r, r), red);
      canvas.drawLine(at + const Offset(-r, r), at + const Offset(r, -r), red);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
