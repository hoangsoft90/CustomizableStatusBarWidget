import 'package:date_time_widget/models/clock_config.dart';
import 'package:date_time_widget/utils/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Fixed DateTime: Sunday, August 30, 2026, 08:35:42
  final testDate = DateTime(2026, 8, 30, 8, 35, 42);

  group('DateFormatter.formatTime', () {
    test('24h format', () {
      const config = ClockConfig(timeFormat: 'HH:mm');
      expect(DateFormatter.formatTime(testDate, config), '08:35');
    });

    test('12h format AM', () {
      const config = ClockConfig(timeFormat: 'hh:mm a');
      expect(DateFormatter.formatTime(testDate, config), '08:35 AM');
    });

    test('12h format PM', () {
      final pm = DateTime(2026, 8, 30, 20, 15, 0);
      const config = ClockConfig(timeFormat: 'hh:mm a');
      expect(DateFormatter.formatTime(pm, config), '08:15 PM');
    });

    test('12h midnight', () {
      final midnight = DateTime(2026, 8, 30, 0, 0, 0);
      const config = ClockConfig(timeFormat: 'hh:mm a');
      expect(DateFormatter.formatTime(midnight, config), '12:00 AM');
    });

    test('12h noon', () {
      final noon = DateTime(2026, 8, 30, 12, 0, 0);
      const config = ClockConfig(timeFormat: 'hh:mm a');
      expect(DateFormatter.formatTime(noon, config), '12:00 PM');
    });
  });

  group('DateFormatter.formatDate', () {
    test('EEE dd MMM', () {
      const config = ClockConfig(format: 'EEE dd MMM');
      expect(DateFormatter.formatDate(testDate, config), 'Sun 30 Aug');
    });

    test('dd/MM/yyyy', () {
      const config = ClockConfig(format: 'dd/MM/yyyy');
      expect(DateFormatter.formatDate(testDate, config), '30/08/2026');
    });

    test('EEEE, MMMM d', () {
      const config = ClockConfig(format: 'EEEE, MMMM d');
      expect(
        DateFormatter.formatDate(testDate, config),
        'Sunday, August 30',
      );
    });

    test('yy-MM-dd', () {
      const config = ClockConfig(format: 'yy-MM-dd');
      expect(DateFormatter.formatDate(testDate, config), '26-08-30');
    });
  });

  group('DateFormatter.formatDay', () {
    test('returns full day name when format has no day tokens', () {
      const config = ClockConfig(format: 'dd/MM/yyyy', showDay: true);
      expect(DateFormatter.formatDay(testDate, config), 'Sunday');
    });

    test('returns empty when showDay is false', () {
      const config = ClockConfig(format: 'dd/MM/yyyy', showDay: false);
      expect(DateFormatter.formatDay(testDate, config), '');
    });

    test('returns empty when day is already in format string', () {
      const config = ClockConfig(format: 'EEE dd MMM', showDay: true);
      expect(DateFormatter.formatDay(testDate, config), '');
    });
  });

  group('DateFormatter.buildDisplay', () {
    test('builds all three lines for separate day + date format', () {
      const config = ClockConfig(
        format: 'dd/MM/yyyy',
        timeFormat: 'HH:mm',
        showDay: true,
        showDate: true,
      );
      final display = DateFormatter.buildDisplay(testDate, config);
      expect(display.time, '08:35');
      expect(display.day, 'Sunday');
      expect(display.date, '30/08/2026');
    });

    test('mixed day+date in single format', () {
      const config = ClockConfig(
        format: 'EEE dd MMM',
        timeFormat: 'HH:mm',
        showDay: true,
        showDate: true,
      );
      final display = DateFormatter.buildDisplay(testDate, config);
      expect(display.time, '08:35');
      expect(display.day, '');
      expect(display.date, 'Sun 30 Aug');
    });
  });
}
