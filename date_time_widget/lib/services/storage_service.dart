import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/clock_config.dart';
import '../models/widget_design.dart';

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

  // ── BackgroundConfig ────────────────────────────────────

  static const String _backgroundKey = 'widget_background';

  /// Load the persisted [BackgroundConfig], or return default
  /// (none) if nothing has been saved yet.
  BackgroundConfig loadBackground() {
    final jsonString = _prefs.getString(_backgroundKey);
    if (jsonString == null) return const BackgroundConfig();
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return BackgroundConfig.fromJson(map);
    } catch (_) {
      return const BackgroundConfig();
    }
  }

  /// Persist [BackgroundConfig] to shared preferences.
  Future<bool> saveBackground(BackgroundConfig background) {
    return _prefs.setString(_backgroundKey, jsonEncode(background.toJson()));
  }

  // ── Helpers ──────────────────────────────────────────────

  /// Remove all stored data (used for clean uninstall / testing).
  Future<bool> clearAll() => _prefs.clear();

  /// Raw access for edge cases (e.g. debug screen).
  SharedPreferences get prefs => _prefs;
}
