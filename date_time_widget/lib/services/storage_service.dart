import 'package:shared_preferences/shared_preferences.dart';

import '../models/clock_config.dart';

/// Persists [ClockConfig] and app-level state using [SharedPreferences].
///
/// All data is stored locally — no backend involved (see plan "Không làm").
class StorageService {
  static const String _configKey = 'clock_config';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  /// Initialise by loading the prefs instance. Call once at app start.
  static Future<StorageService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return StorageService(prefs);
  }

  // ── ClockConfig ──────────────────────────────────────────

  /// Load the saved [ClockConfig], or return [ClockConfig.defaults]
  /// if nothing has been saved yet.
  ClockConfig loadConfig() {
    final jsonString = _prefs.getString(_configKey);
    if (jsonString == null) return ClockConfig.defaults();
    try {
      return ClockConfig.fromJsonString(jsonString);
    } catch (_) {
      return ClockConfig.defaults();
    }
  }

  /// Persist [ClockConfig] to shared preferences.
  Future<bool> saveConfig(ClockConfig config) {
    return _prefs.setString(_configKey, config.toJsonString());
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Remove all stored data (used for clean uninstall / testing).
  Future<bool> clearAll() => _prefs.clear();

  /// Raw access for edge cases (e.g. debug screen).
  SharedPreferences get prefs => _prefs;
}
