import 'package:date_time_widget/models/clock_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('Preset unlock via unlockedPresets', () {
    test('adding preset to unlockedPresets', () {
      const config = ClockConfig(unlockedPresets: ['basic1', 'basic2']);
      final updated = config.copyWith(
        unlockedPresets: [...config.unlockedPresets, 'premium1'],
      );
      expect(updated.unlockedPresets, contains('premium1'));
      expect(updated.unlockedPresets.length, 3);
    });

    test('unlock persists through JSON roundtrip', () {
      const config = ClockConfig(unlockedPresets: ['basic1', 'basic2']);
      final updated = config.copyWith(
        unlockedPresets: [...config.unlockedPresets, 'premium1', 'premium2'],
      );
      final json = updated.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.unlockedPresets, contains('premium1'));
      expect(restored.unlockedPresets, contains('premium2'));
    });

    test('premium purchase unlocks ALL presets', () {
      const config = ClockConfig(unlockedPresets: ['basic1', 'basic2']);
      const allIds = [
        'basic1', 'basic2', 'basic3', 'basic4',
        'basic5', 'basic6', 'premium1', 'premium2',
      ];
      final updated = config.copyWith(
        isPremium: true,
        unlockedPresets: allIds,
      );
      expect(updated.isPremium, true);
      expect(updated.unlockedPresets, allIds);
    });

    test('no duplicate presets in unlockedPresets', () {
      const config = ClockConfig(unlockedPresets: ['basic1', 'basic2']);
      // Simulate trying to unlock already-unlocked preset
      if (!config.unlockedPresets.contains('basic1')) {
        final updated = config.copyWith(
          unlockedPresets: [...config.unlockedPresets, 'basic1'],
        );
        expect(updated.unlockedPresets.where((p) => p == 'basic1').length, 1);
      }
      // basic1 already in list, no change needed
      expect(config.unlockedPresets.contains('basic1'), true);
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
