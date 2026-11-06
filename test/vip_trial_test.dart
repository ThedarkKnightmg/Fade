import 'package:barber_app/data/app_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// VIP can be tried free for a week, once per account.
void main() {
  test('the free week turns VIP on once, and only once', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState.instance;
    await s.load();
    expect(s.barberVip, isFalse);
    expect(s.vipTrialAvailable, isTrue);

    final boosts = s.boosts;
    expect(s.startVipTrial(), isTrue);
    expect(s.barberVip, isTrue);
    expect(s.vipOnTrial, isTrue);
    expect(s.boosts, boosts + AppState.vipTrialBoosts);
    final days = s.vipUntil!.difference(DateTime.now()).inHours / 24;
    expect(days, closeTo(AppState.vipTrialDays, 0.1));

    // Not twice.
    expect(s.vipTrialAvailable, isFalse);
    expect(s.startVipTrial(), isFalse);
  });

  test('the trial is remembered across restarts', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState.instance;
    await s.load();
    s.startVipTrial();
    await Future<void>.delayed(const Duration(seconds: 2)); // debounced save
    await s.load();
    expect(s.vipTrialAvailable, isFalse);
    expect(s.vipOnTrial, isTrue);
  });

  test('paying after the trial adds a month and ends trial mode', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppState.instance;
    await s.load();
    s.startVipTrial();
    final trialEnd = s.vipUntil!;
    s.activateVipBoost();
    expect(s.vipOnTrial, isFalse);
    expect(s.vipUntil!.difference(trialEnd).inDays, 30);
  });
}
