// The waiting-chair game keeps exactly one durable number — the best score —
// and the end-of-round card decides whether to celebrate based on what
// recordFadeGameScore() returns. If that flag lied, the game would either
// swallow real records or throw confetti at every miss.
import 'package:barber_app/data/app_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Perfect Fade scores', () {
    test('the first finished run is always a record', () {
      final s = AppState.instance;
      final start = s.fadeGameBest;
      expect(s.recordFadeGameScore(start + 1), isTrue);
      expect(s.fadeGameBest, start + 1);
    });

    test('a worse run never lowers the best', () {
      final s = AppState.instance;
      final best = s.fadeGameBest;
      expect(s.recordFadeGameScore(best - 1), isFalse);
      expect(s.fadeGameBest, best);
    });

    test('matching the best is not a new record', () {
      final s = AppState.instance;
      final best = s.fadeGameBest;
      expect(s.recordFadeGameScore(best), isFalse);
      expect(s.fadeGameBest, best);
    });

    test('every finished run counts as a play, record or not', () {
      final s = AppState.instance;
      final plays = s.fadeGamePlays;
      s.recordFadeGameScore(0);
      s.recordFadeGameScore(s.fadeGameBest + 5);
      expect(s.fadeGamePlays, plays + 2);
    });

    test('the how-to-play hint retires after a couple of rounds', () {
      final s = AppState.instance;
      // Whatever the history, someone who has played twice knows the rule.
      expect(s.fadeGameIsNew, s.fadeGamePlays < 2);
    });
  });

  // Fade Points are money — 1 point = 1 UZS, spendable as a discount at
  // checkout. An uncapped game award would therefore be a money printer, so
  // these pin the two limits that stop it being one.
  group('token payout cap', () {
    test('finishing a run pays nothing by itself — only tokens pay', () {
      final s = AppState.instance;
      final before = s.pointsBalanceSom;
      s.recordFadeGameScore(999);
      expect(s.pointsBalanceSom, before,
          reason: 'score alone must never mint money');
    });

    test('a token pays exactly its face value', () {
      final s = AppState.instance;
      final before = s.pointsBalanceSom;
      final paid = s.claimGameToken();
      expect(paid, MiniGameState.tokenValueSom);
      expect(s.pointsBalanceSom, before + MiniGameState.tokenValueSom);
    });

    test('game points survive a server balance arriving', () async {
      // The balance PREFERS the server figure, and the server has no endpoint
      // for game awards. Before this was fixed, a refresh made everything the
      // player had cut vanish from the balance — they saw "+25" fly up and the
      // number never move. Game points must be additive, never replaced.
      final s = AppState.instance;
      final before = s.pointsBalanceSom;
      s.claimGameToken();
      final afterToken = s.pointsBalanceSom;
      expect(afterToken, greaterThan(before));

      // A server refresh (no session in tests → best-effort no-op) must not
      // eat the game earnings.
      await s.refreshServerLoyalty();
      expect(s.pointsBalanceSom, afterToken,
          reason: 'a server refresh must never swallow game-minted points');
    });

    test('the daily allowance runs out and then pays zero forever', () {
      final s = AppState.instance;
      // Drain whatever is left today.
      var guard = 0;
      while (s.tokensLeftToday > 0 && guard++ < 100) {
        s.claimGameToken();
      }
      expect(s.tokensLeftToday, 0);

      final drained = s.pointsBalanceSom;
      for (var i = 0; i < 25; i++) {
        expect(s.claimGameToken(), 0,
            reason: 'an uncapped token is a money printer — points are UZS');
      }
      expect(s.pointsBalanceSom, drained);
    });

    test('a full day of tokens cannot out-earn a single haircut', () {
      // Cashback on a ~100,000 so'm cut is 2,500. A whole day of play must stay
      // well under that, or playing beats visiting and the product inverts.
      expect(MiniGameState.gameAwardSom, lessThan(2500));
      expect(MiniGameState.gameAwardSom, greaterThan(0));
      expect(MiniGameState.gameAwardSom,
          MiniGameState.tokenValueSom * MiniGameState.dailyTokenCap);
    });
  });
}
