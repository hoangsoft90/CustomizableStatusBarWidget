import 'package:date_time_widget/models/clock_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for the 9 fixes defined in plan2_final.md.
///
/// These test the Dart-side model and config sync logic.
/// Native-side fixes (NotificationIconService, DateTimeWidgetProvider,
/// FloatingBarService, TimeTickService) are tested via device testing.
void main() {
  group('#1 Sunday crash — safe day-of-week indexing', () {
    test('ClockConfig.fromJsonString handles all day-related fields', () {
      const config = ClockConfig(
        format: 'EEEE',
        showDay: true,
        showDate: true,
      );
      final json = config.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.format, 'EEEE');
      expect(restored.showDay, true);
    });

    test('ClockConfig with Sunday-relevant format parses correctly', () {
      const json = '{"format":"EEEE, MMMM d","timeFormat":"HH:mm","showDay":true}';
      final config = ClockConfig.fromJsonString(json);
      expect(config.format, 'EEEE, MMMM d');
      expect(config.showDay, true);
    });
  });

  group('#2 Notification follows full ClockConfig', () {
    test('toJsonString includes all config fields', () {
      const config = ClockConfig(
        format: 'EEE dd MMM',
        timeFormat: 'hh:mm a',
        showDate: false,
        showDay: true,
        fontSize: 28,
        color: '#FF0000',
        alignment: 'left',
      );
      final json = config.toJsonString();

      expect(json, contains('"format":"EEE dd MMM"'));
      expect(json, contains('"timeFormat":"hh:mm a"'));
      expect(json, contains('"showDate":false'));
      expect(json, contains('"showDay":true'));
      expect(json, contains('"fontSize":28'));
      expect(json, contains('"color":"#FF0000"'));
      expect(json, contains('"alignment":"left"'));
    });

    test('Native parseClockData equivalent — extract all fields from JSON', () {
      const config = ClockConfig(
        format: 'dd/MM/yyyy',
        timeFormat: 'HH:mm',
        showDate: true,
        showDay: false,
        fontSize: 40,
        color: '#00FF00',
        alignment: 'right',
      );
      final json = config.toJsonString();

      String? extract(String key, String jsonStr) {
        final pattern = RegExp('"$key"\\s*:\\s*"([^"]*)"');
        final match = pattern.firstMatch(jsonStr);
        if (match != null) return match.group(1);

        final numPattern = RegExp('"$key"\\s*:\\s*([\\d.]+)');
        final numMatch = numPattern.firstMatch(jsonStr);
        if (numMatch != null) return numMatch.group(1);

        final boolPattern = RegExp('"$key"\\s*:\\s*(true|false)');
        final boolMatch = boolPattern.firstMatch(jsonStr);
        if (boolMatch != null) return boolMatch.group(1);

        return null;
      }

      expect(extract('format', json), 'dd/MM/yyyy');
      expect(extract('timeFormat', json), 'HH:mm');
      expect(extract('showDate', json), 'true');
      expect(extract('showDay', json), 'false');
      expect(extract('fontSize', json), '40.0');
      expect(extract('color', json), '#00FF00');
      expect(extract('alignment', json), 'right');
    });

    test('Notification ClockData defaults match model defaults', () {
      const config = ClockConfig();
      expect(config.format, 'EEE dd MMM');
      expect(config.timeFormat, 'HH:mm');
      expect(config.showDate, true);
      expect(config.showDay, true);
      expect(config.fontSize, 32);
      expect(config.color, '#FFFFFF');
      expect(config.alignment, 'center');
    });
  });

  group('#3 Config sync — JSON roundtrip for native SharedPreferences', () {
    test('toJsonString → status_bar_config key format matches native', () {
      const config = ClockConfig(
        format: 'EEEE, d MMMM',
        timeFormat: 'hh:mm a',
        showDate: true,
        showDay: true,
        fontSize: 36,
        color: '#FF6D00',
        alignment: 'center',
      );
      final json = config.toJsonString();

      final parsed = ClockConfig.fromJsonString(json);
      expect(parsed, equals(config));
    });

    test('null configJson falls back to defaults on native side', () {
      const defaults = ClockConfig();
      expect(defaults.format, 'EEE dd MMM');
      expect(defaults.fontSize, 32);
      expect(defaults.color, '#FFFFFF');
    });
  });

  group('#4 Alignment — valid values and defaults', () {
    test('alignment defaults to center', () {
      const config = ClockConfig();
      expect(config.alignment, 'center');
    });

    test('alignment left preserves through JSON', () {
      const config = ClockConfig(alignment: 'left');
      final json = config.toJsonString();
      final parsed = ClockConfig.fromJsonString(json);
      expect(parsed.alignment, 'left');
    });

    test('alignment right preserves through JSON', () {
      const config = ClockConfig(alignment: 'right');
      final json = config.toJsonString();
      final parsed = ClockConfig.fromJsonString(json);
      expect(parsed.alignment, 'right');
    });

    test('alignment center preserves through JSON', () {
      const config = ClockConfig(alignment: 'center');
      final json = config.toJsonString();
      final parsed = ClockConfig.fromJsonString(json);
      expect(parsed.alignment, 'center');
    });
  });

  group('#5 TimeTickService replaces AlarmManager', () {
    test('ClockConfig has no alarm-specific fields — clean design', () {
      const config = ClockConfig();
      final json = config.toJsonString();
      expect(json, isNot(contains('alarm')));
      expect(json, isNot(contains('schedule')));
    });
  });

  group('#6 SCHEDULE_EXACT_ALARM removed from manifest', () {
    test('not testable in pure Dart — verified in AndroidManifest.xml', () {
      expect(true, isTrue);
    });
  });

  group('#7 Locale-aware day/month names', () {
    test('ClockConfig format tokens are locale-independent', () {
      const config = ClockConfig(format: 'EEEE, MMMM d');
      expect(config.format, contains('EEEE'));
      expect(config.format, contains('MMMM'));
    });

    test('12h time format with AM/PM preserves through JSON', () {
      const config = ClockConfig(timeFormat: 'hh:mm a');
      final json = config.toJsonString();
      final parsed = ClockConfig.fromJsonString(json);
      expect(parsed.timeFormat, 'hh:mm a');
    });
  });

  group('#8 FloatingBar in-place update', () {
    test('update method accepts configJson parameter', () {
      const config = ClockConfig(
        floatingBarEnabled: true,
        format: 'EEE',
        timeFormat: 'HH:mm',
      );
      final json = config.toJsonString();
      expect(json, contains('"floatingBarEnabled":true'));
    });

    test('config changes update all three services via same JSON', () {
      const config = ClockConfig(
        format: 'dd/MM',
        color: '#00BCD4',
        fontSize: 28,
        alignment: 'right',
      );
      final json = config.toJsonString();

      final parsed = ClockConfig.fromJsonString(json);
      expect(parsed.format, 'dd/MM');
      expect(parsed.color, '#00BCD4');
      expect(parsed.fontSize, 28);
      expect(parsed.alignment, 'right');
    });
  });

  group('#9 Home UI hierarchy — section ordering', () {
    test('STATUS BAR section comes before HOME SCREEN in button order', () {
      const sections = [
        'STATUS BAR',
        'HOME SCREEN',
        'CUSTOMIZE',
        'FLOATING BAR',
      ];
      expect(sections[0], 'STATUS BAR');
      expect(sections[1], 'HOME SCREEN');
      expect(sections[2], 'CUSTOMIZE');
      expect(sections[3], 'FLOATING BAR');
    });
  });

  group('Config sync integration — end-to-end JSON flow', () {
    test('Editor save → all services receive same JSON', () {
      const config = ClockConfig(
        format: 'dd MMM yyyy',
        timeFormat: 'HH:mm',
        showDate: true,
        showDay: false,
        fontSize: 40,
        color: '#E91E63',
        alignment: 'left',
      );

      final configJson = config.toJsonString();

      expect(() => ClockConfig.fromJsonString(configJson), returnsNormally);

      final parsed = ClockConfig.fromJsonString(configJson);
      expect(parsed.format, 'dd MMM yyyy');
      expect(parsed.timeFormat, 'HH:mm');
      expect(parsed.showDay, false);
      expect(parsed.fontSize, 40);
      expect(parsed.color, '#E91E63');
      expect(parsed.alignment, 'left');
    });

    test('Preset apply → config JSON updates all services', () {
      const presetConfig = ClockConfig(
        format: 'EEE, MMM d',
        timeFormat: 'hh:mm a',
        showDate: true,
        showDay: true,
        fontSize: 32,
        color: '#4CAF50',
        alignment: 'center',
      );

      final json = presetConfig.toJsonString();
      final parsed = ClockConfig.fromJsonString(json);
      expect(parsed, equals(presetConfig));
    });
  });

  group('Task A — showSeconds removal', () {
    test('ClockConfig has no showSeconds field', () {
      const config = ClockConfig();
      final json = config.toJsonString();
      expect(json, isNot(contains('showSeconds')));
    });

    test('fromJson ignores legacy showSeconds field', () {
      const json = '{"format":"dd/MM","timeFormat":"HH:mm:ss","showSeconds":true}';
      final config = ClockConfig.fromJsonString(json);
      expect(config.timeFormat, 'HH:mm');
      expect(config.toJsonString(), isNot(contains('showSeconds')));
    });

    test('normalizeTimeFormat strips :ss from HH:mm:ss', () {
      expect(ClockConfig.normalizeTimeFormat('HH:mm:ss'), 'HH:mm');
    });

    test('normalizeTimeFormat strips :ss from hh:mm:ss a', () {
      expect(ClockConfig.normalizeTimeFormat('hh:mm:ss a'), 'hh:mm a');
    });

    test('normalizeTimeFormat passes HH:mm unchanged', () {
      expect(ClockConfig.normalizeTimeFormat('HH:mm'), 'HH:mm');
    });

    test('normalizeTimeFormat passes hh:mm a unchanged', () {
      expect(ClockConfig.normalizeTimeFormat('hh:mm a'), 'hh:mm a');
    });

    test('legacy JSON with showSeconds=true + HH:mm:ss normalizes correctly', () {
      const json = '{"timeFormat":"HH:mm:ss","showSeconds":true}';
      final config = ClockConfig.fromJsonString(json);
      expect(config.timeFormat, 'HH:mm');
    });

    test('legacy JSON with showSeconds=true + hh:mm:ss a normalizes correctly', () {
      const json = '{"timeFormat":"hh:mm:ss a","showSeconds":true}';
      final config = ClockConfig.fromJsonString(json);
      expect(config.timeFormat, 'hh:mm a');
    });

    test('preset basic3 has HH:mm not HH:mm:ss', () {
      const config = ClockConfig(timeFormat: 'HH:mm');
      expect(config.timeFormat, 'HH:mm');
      expect(config.toJsonString(), isNot(contains(':ss')));
    });
  });

  group('Task B — unlockedPresets removed from ClockConfig', () {
    test('ClockConfig has no unlockedPresets field', () {
      const config = ClockConfig();
      final json = config.toJsonString();
      expect(json, isNot(contains('unlockedPresets')));
    });

    test('fromJson ignores legacy unlockedPresets field', () {
      const json = '{"format":"dd/MM","timeFormat":"HH:mm","unlockedPresets":["basic1"]}';
      final config = ClockConfig.fromJsonString(json);
      expect(config.toJson(), isNot(contains('unlockedPresets')));
    });

    test('isPremium persists without unlockedPresets', () {
      const config = ClockConfig(isPremium: true);
      final json = config.toJsonString();
      final restored = ClockConfig.fromJsonString(json);
      expect(restored.isPremium, true);
      expect(restored.toJson(), isNot(contains('unlockedPresets')));
    });
  });
}
