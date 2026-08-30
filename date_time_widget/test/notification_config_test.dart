import 'package:date_time_widget/models/clock_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClockConfig notificationEnabled state', () {
    test('default is false', () {
      const config = ClockConfig();
      expect(config.notificationEnabled, false);
    });

    test('copyWith enables notification', () {
      const config = ClockConfig();
      final updated = config.copyWith(notificationEnabled: true);
      expect(updated.notificationEnabled, true);
      // Other fields unchanged
      expect(updated.floatingBarEnabled, false);
      expect(updated.format, 'EEE dd MMM');
    });

    test('copyWith disables notification', () {
      const config = ClockConfig(notificationEnabled: true);
      final updated = config.copyWith(notificationEnabled: false);
      expect(updated.notificationEnabled, false);
    });

    test('notificationEnabled persists through JSON roundtrip', () {
      const config = ClockConfig(notificationEnabled: true);
      final json = config.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.notificationEnabled, true);
    });

    test('notificationEnabled false persists through JSON roundtrip', () {
      const config = ClockConfig(notificationEnabled: false);
      final json = config.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.notificationEnabled, false);
    });
  });
}
