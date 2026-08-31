import 'package:date_time_widget/services/reward_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late RewardService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    service = RewardService(prefs);
  });

  tearDown(() async {
    await prefs.clear();
  });

  String today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  group('resetIfNewDay', () {
    test('resets state when date changes', () async {
      // Simulate state from yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await prefs.setString(
        'reward_state',
        '{"date":"$yesterdayStr","unlockCount":2,"unlockedToday":["premium1"]}',
      );

      await service.resetIfNewDay();

      expect(service.remainingUnlocksToday(), 2);
      // After reset, premium1 is NOT pre-unlocked — must watch ad to use
      expect(service.canUsePreset('premium1', isPremium: false, isFreePreset: false), false);
    });

    test('does NOT reset when same day', () async {
      await prefs.setString(
        'reward_state',
        '{"date":"${today()}","unlockCount":1,"unlockedToday":["premium1"]}',
      );

      await service.resetIfNewDay();

      expect(service.remainingUnlocksToday(), 1);
      expect(service.canUsePreset('premium1', isPremium: false, isFreePreset: false), true);
    });
  });

  group('canUsePreset', () {
    test('free preset always returns true', () {
      expect(service.canUsePreset('basic1', isPremium: false, isFreePreset: true), true);
    });

    test('premium user always returns true', () {
      expect(service.canUsePreset('premium1', isPremium: true, isFreePreset: false), true);
    });

    test('locked preset returns true when already unlocked today', () async {
      await service.unlockToday('premium1');
      expect(service.canUsePreset('premium1', isPremium: false, isFreePreset: false), true);
    });

    test('locked preset returns false when not yet unlocked, even with unlocks remaining', () {
      expect(service.canUsePreset('premium1', isPremium: false, isFreePreset: false), false);
    });

    test('locked preset returns false when no unlocks remaining', () async {
      await service.unlockToday('premium1');
      await service.unlockToday('premium2');
      expect(service.canUsePreset('premium1', isPremium: false, isFreePreset: false), true); // already unlocked
      expect(service.canUsePreset('premium3', isPremium: false, isFreePreset: false), false); // limit reached
    });
  });

  group('remainingUnlocksToday', () {
    test('starts at 2', () {
      expect(service.remainingUnlocksToday(), 2);
    });

    test('decreases after unlock', () async {
      await service.unlockToday('premium1');
      expect(service.remainingUnlocksToday(), 1);
    });

    test('reaches 0 after 2 unlocks', () async {
      await service.unlockToday('premium1');
      await service.unlockToday('premium2');
      expect(service.remainingUnlocksToday(), 0);
    });
  });

  group('unlockToday', () {
    test('records unlock and increments count', () async {
      final result = await service.unlockToday('premium1');
      expect(result, true);
      expect(service.remainingUnlocksToday(), 1);
    });

    test('returns true if already unlocked today (idempotent)', () async {
      await service.unlockToday('premium1');
      final result = await service.unlockToday('premium1');
      expect(result, true);
      expect(service.remainingUnlocksToday(), 1); // count not incremented again
    });

    test('returns false when limit reached', () async {
      await service.unlockToday('premium1');
      await service.unlockToday('premium2');
      final result = await service.unlockToday('premium3');
      expect(result, false);
    });

    test('resets count on new day — fresh preset not yet unlocked', () async {
      await service.unlockToday('premium1');
      await service.unlockToday('premium2');
      expect(service.remainingUnlocksToday(), 0);

      // Simulate new day
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await prefs.setString(
        'reward_state',
        '{"date":"$yesterdayStr","unlockCount":2,"unlockedToday":["premium1","premium2"]}',
      );

      await service.resetIfNewDay();
      expect(service.remainingUnlocksToday(), 2);
      // premium3 was never unlocked today — even though unlocks are available,
      // canUsePreset returns false (must watch ad first)
      expect(service.canUsePreset('premium3', isPremium: false, isFreePreset: false), false);
    });
  });

  group('daily reset integration', () {
    test('full flow: unlock 2, new day, unlock again', () async {
      // Day 1: unlock 2 presets
      await service.unlockToday('premium1');
      await service.unlockToday('premium2');
      expect(service.remainingUnlocksToday(), 0);
      expect(service.canUsePreset('premium3', isPremium: false, isFreePreset: false), false);

      // Simulate new day by writing old date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await prefs.setString(
        'reward_state',
        '{"date":"$yesterdayStr","unlockCount":2,"unlockedToday":["premium1","premium2"]}',
      );

      // Day 2: reset and unlock again
      await service.resetIfNewDay();
      expect(service.remainingUnlocksToday(), 2);
      final result = await service.unlockToday('premium3');
      expect(result, true);
      expect(service.remainingUnlocksToday(), 1);
    });
  });
}
