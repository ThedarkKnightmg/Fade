part of '../app_state.dart';

/// The waiting-chair game's persistent state.
///
/// A barbershop visit has dead time in it — you arrive early, the chair before
/// you runs long, and you sit there with nothing to do. That wait is the single
/// worst moment in the whole experience and the app previously had no answer
/// for it. "Perfect Fade" fills it with something short, tense and thumb-sized.
///
/// Deliberately NOT wired into Fade Points. Points are real money (they buy
/// cuts), so minting them from a game either costs the business on every play
/// or has to be throttled into something insulting. A high score you actually
/// want to beat is a better reward than a rounding error, and it keeps the
/// loyalty currency honestly tied to visits — see [[fade-points-metric]].
mixin MiniGameState on ChangeNotifier, AppStatePlumbing, FadePointsState {
  /// What one cut Fade-Point token is worth, in so'm (1 point = 1 UZS).
  static const int tokenValueSom = 25;

  /// How many tokens a player may bank in a day. This is THE cap: points are
  /// real money, so tokens have to run out or the game is a money printer.
  /// 20 × 25 = 500 so'm a day — about a fifth of the cashback on one haircut,
  /// enough to feel worth chasing and nowhere near enough to beat booking.
  static const int dailyTokenCap = 20;

  /// Total daily payout, for copy that quotes the figure.
  static const int gameAwardSom = tokenValueSom * dailyTokenCap;

  int _fadeGameBest = 0;
  int _fadeGamePlays = 0;

  /// Best "Clean Line" score. A separate number because the two games measure
  /// different things — one rewards speed, the other steadiness — and merging
  /// them into one leaderboard would make both meaningless. The TOKEN allowance
  /// is deliberately shared, though: it caps real money per day, not per game,
  /// or a second game would simply double the payout.
  int _lineGameBest = 0;
  int get lineGameBest => _lineGameBest;

  /// Record a finished Clean Line run. Returns true on a new personal best.
  bool recordLineGameScore(int score) {
    final isRecord = score > _lineGameBest;
    if (isRecord) _lineGameBest = score;
    notifyListeners();
    return isRecord;
  }

  /// Tokens banked today, and the day they belong to (days-since-epoch).
  /// Persisted, because a cap that resets when the app restarts is not a cap.
  int _tokensToday = 0;
  int _lastGameAwardDay = -1;

  /// Roll the allowance over when the calendar day changes.
  void _rollTokenDay() {
    final today = DateTime.now().difference(DateTime(1970)).inDays;
    if (_lastGameAwardDay != today) {
      _lastGameAwardDay = today;
      _tokensToday = 0;
    }
  }

  /// Tokens still claimable today. The game stops spawning them at zero, so
  /// the allowance is visible in the field rather than being a silent rule that
  /// makes tokens mysteriously stop paying.
  int get tokensLeftToday {
    _rollTokenDay();
    return (dailyTokenCap - _tokensToday).clamp(0, dailyTokenCap);
  }

  bool get gameAwardAvailable => tokensLeftToday > 0;

  /// Bank one cut token. Returns the so'm minted, or 0 when today's allowance
  /// is spent. This is the ONLY path from the game to real money.
  int claimGameToken() {
    _rollTokenDay();
    if (_tokensToday >= dailyTokenCap) return 0;
    _tokensToday++;
    _mintPoints(tokenValueSom);
    notifyListeners();
    return tokenValueSom;
  }

  /// Best run so far — the number the next attempt is measured against.
  int get fadeGameBest => _fadeGameBest;

  /// How many rounds have been played, so the UI can stop teaching the rules
  /// to someone who already knows them.
  int get fadeGamePlays => _fadeGamePlays;

  /// True the first couple of times, to show the one-line "how to play".
  bool get fadeGameIsNew => _fadeGamePlays < 2;

  /// Record a finished run. Returns true when it beat the previous best, so
  /// the end-of-game card can celebrate instead of just reporting.
  ///
  /// Points are earned during the run by cutting tokens (see
  /// [claimGameToken]), not awarded here — so this only tracks the score.
  bool recordFadeGameScore(int score) {
    _fadeGamePlays++;
    final isRecord = score > _fadeGameBest;
    if (isRecord) _fadeGameBest = score;
    notifyListeners(); // debounce-saves; see AppStatePlumbing._save
    return isRecord;
  }
}
