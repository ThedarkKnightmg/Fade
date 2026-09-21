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

enum _Phase { idle, drawing, slipped, done }

class _CleanLineGameState extends State<CleanLineGame> {
  final _rng = math.Random();

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
      _buildGuide();
    });
  }

  void _nextLevel() {
    setState(() {
      _level++;
      _phase = _Phase.drawing;
      _buildGuide();
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
      _slip();
      return;
    }

    setState(() {
      _progress = bestI;
      _errors.add(bestD);
      if (_progress >= _guide.length - 3) _finishLine();
    });
  }

  void _slip() {
    if (_phase != _Phase.drawing) return;
    HapticFeedback.heavyImpact();
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
                  if (_phase == _Phase.drawing)
                    MiniPill('${L.lineGameLevel} $_level')
                  else
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
      color: p.bg.withValues(alpha: 0.90),
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
              label: _phase == _Phase.idle
                  ? L.gamePlay
                  : (_phase == _Phase.done ? L.continueWord : L.gameAgain),
              icon: _phase == _Phase.done
                  ? Icons.arrow_forward_rounded
                  : Icons.play_arrow_rounded,
              height: 52,
              onPressed: _phase == _Phase.done ? _nextLevel : _start,
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
  const _LinePainter({
    required this.guide,
    required this.progress,
    required this.palette,
    required this.tolerance,
    required this.live,
  });

  final List<Offset> guide;
  final int progress;
  final PaperPalette palette;
  final double tolerance;
  final bool live;

  @override
  void paint(Canvas canvas, Size size) {
    if (guide.isEmpty) return;

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
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => true;
}
