import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../../core/format/money.dart';
import '../../../core/i18n/strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/app_state.dart';
import '../../widgets/fade_points_pill.dart';
import '../../widgets/paper_kit.dart';
import '../../widgets/primary_button.dart';

/// "Scissor Master" — the waiting-chair game.
///
/// Built for the dead time before your turn: you might be called at any second,
/// so there is no run-up and nothing to mourn if you abandon a round. A game
/// lasts well under a minute.
///
/// The skill is reading several arcs at once and choosing ONE stroke that takes
/// three of them without touching a comb. A swipe carries direction and length,
/// so a single input can express "these three, in this order" — which is what
/// makes a combo feel earned rather than lucky, and what a tap-based version
/// could never express.
///
/// Most of the code here is feedback rather than rules, and deliberately so: a
/// cut that merely made a tuft vanish felt like nothing happened. Every cut now
/// splits the tuft into halves that fly apart along the blade's normal, throws
/// hair fragments, floats the score it earned, and kicks the camera. The rules
/// underneath are unchanged — it is the response that makes it feel good.
class ScissorMasterGame extends StatefulWidget {
  const ScissorMasterGame({super.key});

  @override
  State<ScissorMasterGame> createState() => _ScissorMasterGameState();
}

enum _Phase { idle, running, over }

/// What's in the air. Hair scores, gold is a bonus worth crossing the screen
/// for, and a comb is the thing you must let fall — cutting one jams the blade.
enum _Kind { hair, gold, comb, token }

class _Obj {
  _Obj({
    required this.kind,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rot,
    required this.vrot,
    required this.size,
    this.isHalf = false,
  });

  final _Kind kind;
  double x, y, vx, vy, rot, vrot;
  final double size;

  /// Halves are the debris of a cut object: they still fall, but they can't be
  /// cut again and they never charge a miss.
  final bool isHalf;

  bool sliced = false;
  double fade = 1;
  bool counted = false;
}

/// A hair fragment thrown by a cut. Pure decoration, no gameplay meaning.
class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.size, this.color);
  double x, y, vx, vy;
  final double size;
  final Color color;
  double life = 1;
}

/// A floating "+2" that rises from where the cut landed, so the reward appears
/// where the player was looking instead of only in the header.
class _Popup {
  _Popup(this.x, this.y, this.text, this.color);
  final double x;
  double y;
  final String text;
  final Color color;
  double life = 1;
}

class _ScissorMasterGameState extends State<ScissorMasterGame>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _gravity = 1750.0; // px/s²
  static const _lives = 3;
  static const _trailLength = 14;

  late final Ticker _ticker = createTicker(_onTick);
  final _rng = math.Random();
  final _objects = <_Obj>[];
  final _particles = <_Particle>[];
  final _popups = <_Popup>[];
  final _trail = <Offset>[];

  _Phase _phase = _Phase.idle;
  Size _field = Size.zero;
  Duration _last = Duration.zero;
  double _spawnIn = 0.6;
  double _elapsed = 0;

  int _score = 0;
  int _livesLeft = _lives;
  int _slicedThisStroke = 0;
  int _bestCombo = 0;
  int _awarded = 0; // Fade Points (so'm) banked this run by cutting tokens

  /// Consecutive cuts without dropping hair or jamming the blade. Past
  /// [_heatAt] the blade visibly catches fire — a reward for flow that costs
  /// the player nothing to understand and everything to lose.
  int _streak = 0;
  static const _heatAt = 8;
  bool get _hot => _streak >= _heatAt;

  String? _flash;
  double _flashFor = 0;
  bool _wasRecord = false;
  int _nearMiss = 0; // points short of the record, when it was close
  bool _paused = false;

  /// Brief time dilation after a big stroke — the cut lands, the world slows
  /// for a beat, and you get to SEE the thing you just pulled off.
  double _slowmo = 0;

  // Feel: a camera kick on impact and a red wash when damaged. Both decay to
  // zero on their own so nothing has to remember to switch them off.
  double _shake = 0;
  double _damageFlash = 0;
  double _comboPop = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  /// Losing a run because the barber called you is the one death this game must
  /// never inflict — the whole point is that you're waiting for exactly that.
  /// Leaving the app freezes the round instead of letting hair pile up on the
  /// floor unattended.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _phase == _Phase.running) {
      _pause();
    }
  }

  void _pause() {
    if (_paused || _phase != _Phase.running) return;
    _ticker.stop();
    setState(() => _paused = true);
  }

  void _resume() {
    if (!_paused) return;
    setState(() => _paused = false);
    _last = Duration.zero; // drop the gap, or one huge dt teleports everything
    _ticker.start();
  }

  void _start() {
    setState(() {
      _phase = _Phase.running;
      _objects.clear();
      _particles.clear();
      _popups.clear();
      _trail.clear();
      _score = 0;
      _livesLeft = _lives;
      _bestCombo = 0;
      _awarded = 0;
      _streak = 0;
      _elapsed = 0;
      _spawnIn = 0.4;
      _flash = null;
      _shake = 0;
      _damageFlash = 0;
      _paused = false;
      _slowmo = 0;
    });
    _last = Duration.zero;
    _ticker.start();
  }

  /// Difficulty follows time, not score, so a cautious player and a greedy one
  /// face the same ramp — otherwise playing well would punish you.
  ///
  /// 55 seconds to full pressure. 75 was so slow the hard part never arrived;
  /// 40 was a cliff — the screen filled before the player had settled into the
  /// rhythm, which reads as unfair rather than difficult. 55 keeps the ramp
  /// inside a normal round while leaving room to feel good first.
  double get _rampT => math.min(1, _elapsed / 55);

  void _spawn() {
    final w = _field.width;
    if (w <= 0) return;

    // Combs start earlier and end denser: they are the only thing that makes
    // a fast stroke risky, so at low density the game has no downside to
    // swiping wildly. Roughly a quarter of late throws are combs.
    final combChance = _elapsed < 5 ? 0 : 0.12 + 0.15 * _rampT;
    // Tokens only exist while today's allowance does. When it's spent they
    // stop appearing, so the cap is something you SEE run out rather than a
    // hidden rule that makes tokens quietly stop paying.
    final tokenChance =
        AppState.instance.tokensLeftToday > 0 ? 0.13 : 0.0;
    final roll = _rng.nextDouble();
    final kind = roll < combChance
        ? _Kind.comb
        : (roll < combChance + tokenChance
            ? _Kind.token
            : (roll > 0.96 ? _Kind.gold : _Kind.hair));

    final x = w * (0.10 + _rng.nextDouble() * 0.80);

    // Two throw types. A lob hangs high and reads easily; a FLAT one is thrown
    // lower and much faster across the screen, so it is on and off before a
    // lazy swipe can reach it. Flat throws only appear as the ramp climbs —
    // they are the difference between "wait for it" and "react now".
    final flat = _rng.nextDouble() < 0.34 * _rampT;
    final peak = flat
        ? _field.height * (0.30 + _rng.nextDouble() * 0.14)
        : _field.height * (0.52 + _rng.nextDouble() * 0.24);
    final vy = -math.sqrt(2 * _gravity * peak);
    final spread = flat ? 1.5 : 0.6;
    final drift = (w / 2 - x) * (0.5 + _rng.nextDouble() * spread);

    // Late tufts run a little smaller, so a sloppy stroke that used to clip
    // everything nearby now has to be aimed.
    final shrink = 1 - 0.14 * _rampT;

    _objects.add(_Obj(
      kind: kind,
      x: x,
      y: _field.height + 40,
      vx: drift.clamp(-430.0, 430.0),
      vy: vy,
      rot: _rng.nextDouble() * math.pi,
      vrot: (_rng.nextDouble() - 0.5) * 3.4,
      size: (kind == _Kind.comb
              ? 34
              : (kind == _Kind.gold ? 30 : (kind == _Kind.token ? 30 : 32))) *
          shrink,
    ));
  }

  void _onTick(Duration now) {
    final rawDt =
        _last == Duration.zero ? 0.0 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    if (rawDt <= 0 || rawDt > 0.1) return; // skip absurd frames (resume from bg)

    // Slow-motion scales the SIMULATION only. It decays on RAW time, so the
    // effect always lasts the same wall-clock beat (~0.45s) no matter how
    // slowed the world currently is — decaying on the slowed dt would make it
    // stretch itself out forever.
    var dt = rawDt;
    if (_slowmo > 0) {
      _slowmo = math.max(0, _slowmo - rawDt * 2.2);
      dt *= 1 - 0.55 * _slowmo.clamp(0.0, 1.0);
    }

    setState(() {
      _elapsed += dt;
      if (_flashFor > 0) {
        _flashFor -= dt;
        if (_flashFor <= 0) _flash = null;
      }
      _shake = math.max(0, _shake - dt * 42);
      _damageFlash = math.max(0, _damageFlash - dt * 2.2);
      _comboPop = math.max(0, _comboPop - dt * 3.2);

      _spawnIn -= dt;
      if (_spawnIn <= 0) {
        // Flurries: late on, a throw can be three at once. A single stroke can
        // still take all three — that's the skill ceiling this creates — but
        // only if you read them fast and pick one line through the lot.
        final r = _rng.nextDouble();
        final burst = r < 0.08 * _rampT ? 3 : (r < 0.32 * _rampT ? 2 : 1);
        for (var i = 0; i < burst; i++) {
          _spawn();
        }
        // 0.92s down to ~0.26s between throws. The old floor of 0.42s left
        // room to deal with each object on its own; below ~0.3s they start
        // overlapping in the air, which is what forces multi-cut strokes.
        _spawnIn = 0.95 - 0.60 * _rampT + _rng.nextDouble() * 0.20;
      }

      for (final o in _objects) {
        o.vy += _gravity * dt;
        o.x += o.vx * dt;
        o.y += o.vy * dt;
        o.rot += o.vrot * dt;
        if (o.isHalf) o.fade -= dt * 1.1;

        // Fell past the floor untouched. Hair you were meant to cut costs a
        // life; a comb you correctly ignored is a relief, not a penalty. Halves
        // are debris and never charge anything.
        if (o.y > _field.height + 60 && !o.counted) {
          o.counted = true;
          if (o.kind != _Kind.comb && !o.isHalf) _loseLife(L.gameMissedHair);
        }
      }
      _objects.removeWhere(
        (o) => o.fade <= 0 || o.y > _field.height + 140,
      );

      for (final p in _particles) {
        p.vy += _gravity * 0.45 * dt;
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.life -= dt * 1.6;
      }
      _particles.removeWhere((p) => p.life <= 0);

      for (final p in _popups) {
        p.y -= dt * 62;
        p.life -= dt * 1.3;
      }
      _popups.removeWhere((p) => p.life <= 0);
    });
  }

  void _loseLife(String reason) {
    _livesLeft--;
    _streak = 0; // flow broken — the blade cools
    _flash = reason;
    _flashFor = 1.0;
    _shake = 16;
    _damageFlash = 1;
    HapticFeedback.heavyImpact();
    if (_livesLeft <= 0) _gameOver();
  }

  void _gameOver() {
    _ticker.stop();
    final record = AppState.instance.recordFadeGameScore(_score);
    _phase = _Phase.over;
    _wasRecord = record;
    // "You were two off" is the line that starts another run. Only shown when
    // it's true and close — a near-miss banner on every loss would be noise.
    final best = AppState.instance.fadeGameBest;
    final gap = best - _score;
    _nearMiss = (!record && gap > 0 && gap <= 5) ? gap : 0;
    // _awarded is accumulated during the run as tokens are cut, so there is
    // nothing to collect here.
    _trail.clear();
  }

  // ── Blade ────────────────────────────────────────────────────────────────
  void _strokeStart(Offset p) {
    if (_phase != _Phase.running || _paused) return;
    _slicedThisStroke = 0;
    _trail
      ..clear()
      ..add(p);
  }

  void _strokeMove(Offset p) {
    if (_phase != _Phase.running || _paused) return;
    setState(() {
      _trail.add(p);
      if (_trail.length > _trailLength) _trail.removeAt(0);
      if (_trail.length >= 2) {
        _cutAlong(_trail[_trail.length - 2], p);
      }
    });
  }

  void _strokeEnd() {
    if (_slicedThisStroke > 1) {
      // Paid at the END of the stroke so the reward lands with the gesture that
      // earned it rather than mid-swipe.
      final bonus = _slicedThisStroke * (_slicedThisStroke - 1);
      // The shout escalates with the stroke, so a four-cut sweep is audibly
      // different from a lucky two. Same reason the shake scales.
      final shout = switch (_slicedThisStroke) {
        2 => L.gameNice,
        3 => L.gameSharp,
        4 => L.gameMaster,
        _ => L.gameLegend,
      };
      setState(() {
        _score += bonus;
        _bestCombo = math.max(_bestCombo, _slicedThisStroke);
        _flash = '$shout  $_slicedThisStroke× +$bonus';
        _flashFor = 1.3;
        _comboPop = 1;
        _shake = 6.0 + _slicedThisStroke * 2.0;
      });
      if (_slicedThisStroke >= 4) {
        _slowmo = 1; // the world hangs for a beat so the stroke can be seen
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
    _slicedThisStroke = 0;
  }

  /// Everything whose body the segment a→b passes through gets cut.
  void _cutAlong(Offset a, Offset b) {
    final seg = b - a;
    if (seg.distance < 4) return; // ignore jitter, not a real stroke
    for (final o in _objects) {
      if (o.sliced || o.isHalf) continue;
      final centre = Offset(o.x, o.y);
      if (!_segmentHits(a, b, centre, o.size * 0.92)) continue;

      o.sliced = true;
      o.fade = 0; // removed this frame; the halves take over
      if (o.kind == _Kind.comb) {
        _burst(centre, const Color(0xFFE2554E), 14);
        _popups.add(_Popup(o.x, o.y, L.gameOops, const Color(0xFFE2554E)));
        _loseLife(L.gameCutComb);
        continue;
      }
      _streak++;
      // Crossing into "on fire" is announced once, not every cut after it.
      if (_streak == _heatAt) {
        _flash = L.gameOnFire;
        _flashFor = 1.4;
        _shake = math.max(_shake, 10);
        HapticFeedback.heavyImpact();
      }

      // A token is real money, so the claim goes through AppState — which is
      // where the daily allowance lives. If it returns 0 the allowance is
      // spent and the token is worth score only.
      if (o.kind == _Kind.token) {
        final som = AppState.instance.claimGameToken();
        _score += 1;
        _slicedThisStroke++;
        _splitInTwo(o, seg);
        _burst(centre, AppColors.accent, 20);
        if (som > 0) {
          _awarded += som;
          _popups.add(_Popup(o.x, o.y, '+$som', AppColors.accent));
          HapticFeedback.mediumImpact();
        } else {
          _popups.add(_Popup(o.x, o.y, '+1', AppColors.accent));
        }
        _shake = math.max(_shake, 7);
        continue;
      }

      final worth = o.kind == _Kind.gold ? 5 : 1;
      _score += worth;
      _slicedThisStroke++;
      _splitInTwo(o, seg);
      _burst(
        centre,
        o.kind == _Kind.gold ? const Color(0xFFE0A106) : Paper.of(context).text,
        o.kind == _Kind.gold ? 16 : 10,
      );
      _popups.add(_Popup(
        o.x,
        o.y,
        '+$worth',
        o.kind == _Kind.gold ? const Color(0xFFE0A106) : AppColors.accent,
      ));
      _shake = math.max(_shake, 5);
      HapticFeedback.selectionClick();
    }
  }

  /// Replaces a cut object with two smaller halves flying apart along the
  /// blade's NORMAL — the direction the two pieces would actually separate in,
  /// which is what makes the cut read as a cut rather than a disappearance.
  void _splitInTwo(_Obj o, Offset cut) {
    final n = cut.distance == 0 ? const Offset(1, 0) : cut / cut.distance;
    final normal = Offset(-n.dy, n.dx);
    for (final sign in [-1.0, 1.0]) {
      _objects.add(_Obj(
        kind: o.kind,
        x: o.x + normal.dx * sign * o.size * 0.22,
        y: o.y + normal.dy * sign * o.size * 0.22,
        vx: o.vx + normal.dx * sign * 165,
        vy: o.vy + normal.dy * sign * 165 - 40,
        rot: o.rot,
        vrot: o.vrot + sign * 6.5,
        size: o.size * 0.58,
        isHalf: true,
      ));
    }
  }

  void _burst(Offset at, Color color, int count) {
    for (var i = 0; i < count; i++) {
      final a = _rng.nextDouble() * math.pi * 2;
      final sp = 90 + _rng.nextDouble() * 240;
      _particles.add(_Particle(
        at.dx,
        at.dy,
        math.cos(a) * sp,
        math.sin(a) * sp,
        1.6 + _rng.nextDouble() * 2.6,
        color,
      ));
    }
  }

  /// Distance from [c] to the segment a→b, compared against [r].
  bool _segmentHits(Offset a, Offset b, Offset c, double r) {
    final ab = b - a;
    final lenSq = ab.dx * ab.dx + ab.dy * ab.dy;
    if (lenSq == 0) return (c - a).distance <= r;
    var t = ((c.dx - a.dx) * ab.dx + (c.dy - a.dy) * ab.dy) / lenSq;
    t = t.clamp(0.0, 1.0);
    final closest = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (c - closest).distance <= r;
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
                  if (_phase == _Phase.running)
                    Row(
                      children: [
                        // Scissors, not hearts: the currency of this game is
                        // blades, and a jammed blade is what you're losing.
                        for (var i = 0; i < _lives; i++)
                          Padding(
                            padding: const EdgeInsets.only(left: 5),
                            child: Icon(
                              Icons.content_cut_rounded,
                              size: 19,
                              color: i < _livesLeft
                                  ? AppColors.accent
                                  : p.textTertiary.withValues(alpha: 0.35),
                            ),
                          ),
                      ],
                    )
                  else
                    MiniPill('${L.gameBest} ${state.fadeGameBest}'),
                  if (_phase == _Phase.running) ...[
                    const SizedBox(width: 10),
                    // Live Fade Points balance, and what this run has added to
                    // it. Always on screen: the reason to keep playing should
                    // never be something you must finish the run to discover.
                    // The same pill as the home header, so the balance the
                    // player is growing is visibly the one they already know.
                    // animate:false — this rebuilds every frame, and a
                    // count-up would restart forever.
                    FadePointsPill(
                      som: state.pointsBalanceSom,
                      scale: 0.82,
                      animate: false,
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  _field = Size(box.maxWidth, box.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: (d) =>
                        _paused ? null : _strokeStart(d.localPosition),
                    onPanUpdate: (d) => _strokeMove(d.localPosition),
                    onPanEnd: (_) => _strokeEnd(),
                    onTap: _phase == _Phase.running ? null : _start,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _FieldPainter(
                              objects: _objects,
                              particles: _particles,
                              popups: _popups,
                              trail: _trail,
                              palette: p,
                              shake: _shake,
                              damage: _damageFlash,
                              hot: _hot,
                              rng: _rng,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              // The score pops on a combo, so a big stroke is
                              // felt in the number as well as the field.
                              Transform.scale(
                                scale: 1 + _comboPop * 0.16,
                                child: Text(
                                  '$_score',
                                  style: AppTypography.h1(context).copyWith(
                                    fontSize: 56,
                                    height: 1,
                                    color: _phase == _Phase.running
                                        ? p.text
                                        : p.textTertiary,
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: 22,
                                child: _flash == null
                                    ? null
                                    : Text(
                                        _flash!,
                                        style: AppTypography.bodySmall(context)
                                            .copyWith(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                        if (_phase != _Phase.running)
                          Positioned.fill(child: _overlay(context, p)),
                        if (_paused && _phase == _Phase.running)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _resume,
                              child: Container(
                                color: p.bg.withValues(alpha: 0.88),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.pause_circle_filled_rounded,
                                        size: 62, color: p.textTertiary),
                                    const SizedBox(height: 12),
                                    Text(L.gamePaused,
                                        style: AppTypography.h2(context)),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: 200,
                                      child: PrimaryButton(
                                        label: L.gameResume,
                                        icon: Icons.play_arrow_rounded,
                                        height: 50,
                                        onPressed: _resume,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
    final body =
        AppTypography.body(context).copyWith(color: p.textSecondary);
    return Container(
      color: p.bg.withValues(alpha: 0.88),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_phase == _Phase.over) ...[
            Text(
              _wasRecord ? L.gameNewBest : L.gameOver,
              style: AppTypography.h2(context).copyWith(
                color: _wasRecord ? AppColors.accent : p.text,
              ),
            ),
            const SizedBox(height: 14),
            // The three numbers worth knowing, side by side, so a run can be
            // compared at a glance instead of read as a sentence.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Stat(label: L.gameScore, value: '$_score'),
                _Stat(
                    label: L.gameBest,
                    value: '${AppState.instance.fadeGameBest}'),
                if (_bestCombo > 1)
                  _Stat(label: L.gameBestCombo, value: '$_bestCombo×'),
              ],
            ),
            if (_nearMiss > 0) ...[
              const SizedBox(height: 12),
              Text(
                L.gameSoClose(_nearMiss),
                textAlign: TextAlign.center,
                style: AppTypography.h4(context)
                    .copyWith(color: AppColors.accent),
              ),
            ],
            if (_awarded > 0) ...[
              const SizedBox(height: 22),
              _RewardCard(
                earned: _awarded,
                balance: AppState.instance.pointsBalanceSom,
              ),
            ],
          ] else ...[
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.content_cut_rounded,
                  size: 34, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            Text(L.gameTitle, style: AppTypography.h2(context)),
            const SizedBox(height: 8),
            Text(L.gameHowTo, textAlign: TextAlign.center, style: body),
            const SizedBox(height: 18),
            // The explainer. Nobody plays twice for an abstract score — they
            // play because the tokens are worth money, so say so up front and
            // in plain terms, before the first run rather than after it.
            _TokenExplainer(left: AppState.instance.tokensLeftToday),
            const SizedBox(height: 14),
            FadePointsPill(som: AppState.instance.pointsBalanceSom),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: 220,
            child: PrimaryButton(
              label: _phase == _Phase.over ? L.gameAgain : L.gamePlay,
              icon: _phase == _Phase.over
                  ? Icons.refresh_rounded
                  : Icons.play_arrow_rounded,
              height: 52,
              onPressed: _start,
            ),
          ),
        ],
      ),
    );
  }
}

/// The payoff card at the end of a run.
///
/// This is the moment the whole reward loop is built around, so it gets the
/// app's loudest treatment: the signature Fade Points gradient, the earned
/// figure at hero size counting up, and the new balance in the same pill the
/// home header uses — so the number the player just grew is visibly the same
/// number waiting for them on the home screen.
class _RewardCard extends StatelessWidget {
  const _RewardCard({required this.earned, required this.balance});

  final int earned;
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
      decoration: BoxDecoration(
        gradient: FadePointsPill.gradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7A3CF0).withValues(alpha: 0.42),
            blurRadius: 26,
            spreadRadius: -2,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, size: 20, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                L.gameFadePoints,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.92),
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // The earned figure counts up, so the reward arrives as an event
          // rather than appearing already-finished.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: earned.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => Text(
              '+${Money.group(v.round())}',
              style: GoogleFonts.nunito(
                fontSize: 44,
                height: 1.05,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            L.gameSomOffNextCut,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.90),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              L.gameTotalBalance(balance),
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Explains, before the first run, that the blue tokens are money.
///
/// This is the difference between a score and a reason to come back: a player
/// who doesn't know the tokens are real treats them as decoration. It also
/// states how many are left today, so the cap reads as a daily allowance
/// rather than the game mysteriously going quiet.
class _TokenExplainer extends StatelessWidget {
  const _TokenExplainer({required this.left});

  final int left;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    final spent = left <= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: spent ? p.border : AppColors.accent.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // The token, drawn exactly as it appears in play, so the thing
              // being described is recognisable the moment it flies past.
              CustomPaint(
                size: const Size(34, 34),
                painter: const _TokenChipPainter(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(L.gameTokensTitle,
                    style: AppTypography.h4(context)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            L.gameTokensBody,
            style: AppTypography.bodySmall(context)
                .copyWith(color: p.textSecondary, height: 1.45),
          ),
          // Only speak up once the tokens are GONE. Quoting the daily ceiling
          // up front reframed the reward as a limit — the first thing a new
          // player read was how little they could win, which is an argument
          // against starting. The cap still exists and is still enforced; it
          // just isn't the pitch.
          if (spent) ...[
            const SizedBox(height: 12),
            Text(
              L.gameTokensSpent,
              style: AppTypography.bodySmall(context).copyWith(
                color: p.textTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// The token art on its own, for the explainer.
class _TokenChipPainter extends CustomPainter {
  const _TokenChipPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.translate(size.width / 2, size.height / 2);
    final r = size.width * 0.5;
    canvas.drawCircle(Offset.zero, r, Paint()..color = AppColors.accent);
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.055,
    );
    final mark = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(-r * 0.20, -r * 0.34), Offset(-r * 0.20, r * 0.34), mark);
    canvas.drawLine(
        Offset(-r * 0.20, -r * 0.34), Offset(r * 0.26, -r * 0.34), mark);
    canvas.drawLine(Offset(-r * 0.20, 0), Offset(r * 0.14, 0), mark);
  }

  @override
  bool shouldRepaint(covariant _TokenChipPainter old) => false;
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = Paper.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Text(value, style: AppTypography.h3(context)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption(context)
                  .copyWith(color: p.textSecondary)),
        ],
      ),
    );
  }
}

class _FieldPainter extends CustomPainter {
  const _FieldPainter({
    required this.objects,
    required this.particles,
    required this.popups,
    required this.trail,
    required this.palette,
    required this.shake,
    required this.damage,
    required this.hot,
    required this.rng,
  });

  final List<_Obj> objects;
  final List<_Particle> particles;
  final List<_Popup> popups;
  final List<Offset> trail;
  final PaperPalette palette;
  final double shake;
  final double damage;

  /// True while the player is on a streak — the blade burns gold.
  final bool hot;
  final math.Random rng;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (shake > 0) {
      canvas.translate(
        (rng.nextDouble() * 2 - 1) * shake,
        (rng.nextDouble() * 2 - 1) * shake,
      );
    }

    _paintFloor(canvas, size);

    for (final p in particles) {
      canvas.drawCircle(
        Offset(p.x, p.y),
        p.size * p.life.clamp(0.0, 1.0),
        Paint()..color = p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
      );
    }

    for (final o in objects) {
      canvas.save();
      canvas.translate(o.x, o.y);
      canvas.rotate(o.rot);
      final alpha = o.fade.clamp(0.0, 1.0);
      switch (o.kind) {
        case _Kind.hair:
          _paintTuft(canvas, o.size, palette.text.withValues(alpha: alpha));
        case _Kind.gold:
          _paintTuft(
              canvas, o.size, const Color(0xFFE0A106).withValues(alpha: alpha));
        case _Kind.comb:
          _paintComb(canvas, o.size, alpha);
        case _Kind.token:
          _paintToken(canvas, o.size, alpha);
      }
      canvas.restore();
    }

    // The blade trail: a tapering ribbon so the stroke reads as one motion with
    // a direction, plus a soft glow underneath so it looks like a blade rather
    // than a pencil line.
    if (trail.length > 1) {
      // On a streak the blade burns: a wider amber glow and a hotter core, so
      // being in flow is something you can see without reading a counter.
      final glow = hot ? const Color(0xFFFF8A00) : AppColors.accent;
      final core = hot ? const Color(0xFFFFE07A) : Colors.white;
      for (var i = 1; i < trail.length; i++) {
        final t = i / trail.length;
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = glow.withValues(alpha: (hot ? 0.26 : 0.13) * t)
            ..strokeWidth = (hot ? 20 : 12) * t
            ..strokeCap = StrokeCap.round
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, hot ? 10 : 6),
        );
        canvas.drawLine(
          trail[i - 1],
          trail[i],
          Paint()
            ..color = core.withValues(alpha: 0.10 + 0.75 * t)
            ..strokeWidth = (hot ? 2.4 : 1.6) + (hot ? 5.6 : 4.2) * t
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    for (final p in popups) {
      final tp = TextPainter(
        text: TextSpan(
          text: p.text,
          style: TextStyle(
            color: p.color.withValues(alpha: p.life.clamp(0.0, 1.0)),
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(p.x - tp.width / 2, p.y - tp.height / 2));
    }

    canvas.restore();

    // Damage wash sits OUTSIDE the shake transform so it covers the full frame
    // even while the camera is kicking.
    if (damage > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = const Color(0xFFE2554E).withValues(alpha: 0.20 * damage),
      );
    }
  }

  /// A soft band at the bottom — the floor hair must not reach. It makes the
  /// lose condition visible instead of an invisible line you learn by failing.
  void _paintFloor(Canvas canvas, Size size) {
    final h = size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, h - 46, size.width, 46),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            palette.textTertiary.withValues(alpha: 0),
            palette.textTertiary.withValues(alpha: 0.16),
          ],
        ).createShader(Rect.fromLTWH(0, h - 46, size.width, 46)),
    );
    canvas.drawLine(
      Offset(0, h - 46),
      Offset(size.width, h - 46),
      Paint()
        ..color = palette.textTertiary.withValues(alpha: 0.28)
        ..strokeWidth = 1.2,
    );
  }

  /// A lock of hair: a filled teardrop with a few strands combed off it.
  void _paintTuft(Canvas canvas, double s, Color color) {
    final fill = Paint()..color = color;
    final path = Path()
      ..moveTo(0, -s * 0.55)
      ..quadraticBezierTo(s * 0.62, -s * 0.10, s * 0.16, s * 0.58)
      ..quadraticBezierTo(-s * 0.30, s * 0.20, -s * 0.46, -s * 0.18)
      ..quadraticBezierTo(-s * 0.30, -s * 0.52, 0, -s * 0.55)
      ..close();
    canvas.drawPath(path, fill);

    final strand = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;
    for (var i = -1; i <= 1; i++) {
      final dx = i * s * 0.20;
      canvas.drawPath(
        Path()
          ..moveTo(dx, -s * 0.44)
          ..quadraticBezierTo(dx + s * 0.30, s * 0.02, dx + s * 0.06, s * 0.50),
        strand,
      );
    }
  }

  /// A Fade Point token: an accent coin with a scissor notch, ringed so it
  /// reads as currency at a glance and can never be mistaken for a comb — the
  /// one thing you must NOT cut.
  void _paintToken(Canvas canvas, double s, double alpha) {
    final r = s * 0.52;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()..color = AppColors.accent.withValues(alpha: alpha),
    );
    canvas.drawCircle(
      Offset.zero,
      r * 0.78,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75 * alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.055,
    );
    // A small "F" bar mark — legible even at speed, where a glyph would blur.
    final mark = Paint()
      ..color = Colors.white.withValues(alpha: 0.95 * alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-r * 0.20, -r * 0.34),
        Offset(-r * 0.20, r * 0.34), mark);
    canvas.drawLine(Offset(-r * 0.20, -r * 0.34),
        Offset(r * 0.26, -r * 0.34), mark);
    canvas.drawLine(Offset(-r * 0.20, 0), Offset(r * 0.14, 0), mark);
  }

  /// A comb: spine plus teeth. Deliberately angular and red so it never reads
  /// as hair at a glance — the whole penalty depends on telling them apart fast.
  void _paintComb(Canvas canvas, double s, double alpha) {
    final c = const Color(0xFFE2554E).withValues(alpha: alpha);
    final fill = Paint()..color = c;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-s * 0.60, -s * 0.44, s * 1.20, s * 0.26),
        Radius.circular(s * 0.09),
      ),
      fill,
    );
    for (var i = 0; i < 7; i++) {
      final x = -s * 0.52 + i * (s * 1.04 / 6);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, -s * 0.20, s * 0.085, s * 0.62),
          Radius.circular(s * 0.04),
        ),
        fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FieldPainter old) => true;
}
