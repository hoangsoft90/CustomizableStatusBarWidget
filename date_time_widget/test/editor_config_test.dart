import 'package:date_time_widget/models/clock_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClockConfig.copyWith (editor updates)', () {
    test('update format', () {
      const config = ClockConfig();
      final updated = config.copyWith(format: 'dd/MM/yyyy');
      expect(updated.format, 'dd/MM/yyyy');
      // other fields unchanged
      expect(updated.timeFormat, 'HH:mm');
      expect(updated.fontSize, 32);
    });

    test('toggle showSeconds', () {
      const config = ClockConfig(showSeconds: false);
      final updated = config.copyWith(showSeconds: true);
      expect(updated.showSeconds, true);
    });

    test('update fontSize', () {
      const config = ClockConfig(fontSize: 32);
      final updated = config.copyWith(fontSize: 24);
      expect(updated.fontSize, 24);
    });

    test('update color', () {
      const config = ClockConfig(color: '#FFFFFF');
      final updated = config.copyWith(color: '#FF5722');
      expect(updated.color, '#FF5722');
    });

    test('update alignment', () {
      const config = ClockConfig(alignment: 'center');
      final updated = config.copyWith(alignment: 'left');
      expect(updated.alignment, 'left');
    });

    test('update unlockedPresets', () {
      const config = ClockConfig(unlockedPresets: ['basic1', 'basic2']);
      final updated = config.copyWith(
        unlockedPresets: ['basic1', 'basic2', 'premium1'],
      );
      expect(updated.unlockedPresets, ['basic1', 'basic2', 'premium1']);
    });

    test('chain of copyWith preserves earlier changes', () {
      const config = ClockConfig();
      final result = config
          .copyWith(format: 'dd/MM/yyyy')
          .copyWith(timeFormat: 'hh:mm a')
          .copyWith(fontSize: 20);
      expect(result.format, 'dd/MM/yyyy');
      expect(result.timeFormat, 'hh:mm a');
      expect(result.fontSize, 20);
      // defaults preserved
      expect(result.color, '#FFFFFF');
      expect(result.showSeconds, false);
    });

    test('serialise → deserialise preserves all editor changes', () {
      const config = ClockConfig();
      final modified = config
          .copyWith(
            format: 'EEEE, MMMM d',
            timeFormat: 'hh:mm a',
            showSeconds: true,
            showDay: false,
            fontSize: 18,
            color: '#00E676',
            alignment: 'right',
          );
      final json = modified.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored, equals(modified));
    });
  });
}
