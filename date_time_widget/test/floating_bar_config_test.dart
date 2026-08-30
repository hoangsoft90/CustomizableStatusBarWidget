import 'package:date_time_widget/models/clock_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClockConfig.floatingBarEnabled state', () {
    test('default is false', () {
      const config = ClockConfig();
      expect(config.floatingBarEnabled, false);
    });

    test('copyWith enables floating bar', () {
      const config = ClockConfig();
      final updated = config.copyWith(floatingBarEnabled: true);
      expect(updated.floatingBarEnabled, true);
      // Other fields unchanged
      expect(updated.notificationEnabled, false);
      expect(updated.format, 'EEE dd MMM');
    });

    test('copyWith disables floating bar', () {
      const config = ClockConfig(floatingBarEnabled: true);
      final updated = config.copyWith(floatingBarEnabled: false);
      expect(updated.floatingBarEnabled, false);
    });

    test('floatingBarEnabled persists through JSON roundtrip', () {
      const config = ClockConfig(floatingBarEnabled: true);
      final json = config.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.floatingBarEnabled, true);
    });

    test('floatingBarEnabled independent of notificationEnabled', () {
      const config = ClockConfig(
        notificationEnabled: true,
        floatingBarEnabled: false,
      );
      final json = config.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.notificationEnabled, true);
      expect(restored.floatingBarEnabled, false);
    });
  });
}
