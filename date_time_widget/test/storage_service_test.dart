import 'package:date_time_widget/models/clock_config.dart';
import 'package:date_time_widget/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late StorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await StorageService.create();
  });

  tearDown(() async {
    await storage.clearAll();
  });

  group('StorageService', () {
    test('loads default config when nothing is saved', () {
      final config = storage.loadConfig();
      expect(config, equals(ClockConfig.defaults()));
    });

    test('save then load returns identical ClockConfig', () async {
      const original = ClockConfig(
        format: 'dd/MM/yyyy',
        timeFormat: 'hh:mm a',
        showSeconds: true,
        showDate: true,
        showDay: false,
        fontSize: 24,
        color: '#FF5722',
        alignment: 'left',
        notificationEnabled: true,
        floatingBarEnabled: false,
        unlockedPresets: ['basic1', 'basic2', 'premium1'],
        isPremium: false,
      );

      final saved = await storage.saveConfig(original);
      expect(saved, isTrue);

      final loaded = storage.loadConfig();
      expect(loaded, equals(original));
      expect(loaded.format, 'dd/MM/yyyy');
      expect(loaded.timeFormat, 'hh:mm a');
      expect(loaded.showSeconds, true);
      expect(loaded.showDay, false);
      expect(loaded.fontSize, 24);
      expect(loaded.color, '#FF5722');
      expect(loaded.alignment, 'left');
      expect(loaded.notificationEnabled, true);
      expect(loaded.unlockedPresets, ['basic1', 'basic2', 'premium1']);
    });

    test('overwriting config persists the latest version', () async {
      const first = ClockConfig(
        format: 'EEE dd MMM',
        fontSize: 32,
        color: '#FFFFFF',
      );
      const second = ClockConfig(
        format: 'dd MMM yyyy',
        fontSize: 20,
        color: '#000000',
      );

      await storage.saveConfig(first);
      await storage.saveConfig(second);

      final loaded = storage.loadConfig();
      expect(loaded, equals(second));
      expect(loaded.format, 'dd MMM yyyy');
      expect(loaded.fontSize, 20);
    });

    test('fromJsonString roundtrip preserves all fields', () {
      const config = ClockConfig(
        format: 'EEEE, MMMM d',
        timeFormat: 'HH:mm:ss',
        showSeconds: true,
        showDate: true,
        showDay: true,
        fontSize: 36,
        color: '#00E676',
        alignment: 'right',
        notificationEnabled: true,
        floatingBarEnabled: true,
        unlockedPresets: ['basic1', 'basic2', 'premium1', 'premium2'],
        isPremium: true,
      );

      final jsonString = config.toJsonString();
      final restored = ClockConfig.fromJsonString(jsonString);
      expect(restored, equals(config));
    });

    test('clearAll removes saved config', () async {
      const config = ClockConfig(format: 'dd/MM', fontSize: 18);
      await storage.saveConfig(config);
      await storage.clearAll();

      final loaded = storage.loadConfig();
      expect(loaded, equals(ClockConfig.defaults()));
    });
  });
}
