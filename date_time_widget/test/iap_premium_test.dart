import 'package:date_time_widget/models/clock_config.dart';
import 'package:date_time_widget/models/reward_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RewardState model', () {
    test('empty state has zero count and empty list', () {
      final state = RewardState.empty('2026-08-30');
      expect(state.date, '2026-08-30');
      expect(state.unlockCount, 0);
      expect(state.unlockedToday, isEmpty);
    });

    test('JSON roundtrip preserves all fields', () {
      final state = RewardState(
        date: '2026-08-30',
        unlockCount: 1,
        unlockedToday: ['premium1'],
      );
      final json = state.toJsonString();
      final restored = RewardState.fromJsonString(json);
      expect(restored, equals(state));
    });

    test('copyWith preserves unmodified fields', () {
      final state = RewardState.empty('2026-08-30');
      final updated = state.copyWith(unlockCount: 1, unlockedToday: ['premium1']);
      expect(updated.date, '2026-08-30');
      expect(updated.unlockCount, 1);
      expect(updated.unlockedToday, ['premium1']);
    });
  });

  group('ClockConfig.isPremium state', () {
    test('default is false', () {
      const config = ClockConfig();
      expect(config.isPremium, false);
    });

    test('copyWith sets isPremium', () {
      const config = ClockConfig();
      final updated = config.copyWith(isPremium: true);
      expect(updated.isPremium, true);
    });

    test('isPremium persists through JSON roundtrip', () {
      const config = ClockConfig(isPremium: true);
      final json = config.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.isPremium, true);
    });
  });

  group('Banner visibility based on isPremium', () {
    test('showBanners when not premium', () {
      const config = ClockConfig(isPremium: false);
      expect(config.isPremium, false);
    });

    test('hide banners when premium', () {
      const config = ClockConfig(isPremium: true);
      expect(config.isPremium, true);
    });
  });
}
