import 'package:flutter/services.dart';

import '../models/clock_config.dart';

/// Bridges Flutter ↔ Native Android widget.
///
/// When the user saves a new [ClockConfig] in the Editor, call
/// [updateWidgets] to trigger an immediate refresh of every home-screen
/// widget instance.
///
/// #3: Now passes the config JSON to native via MethodChannel.
/// Native saves it to "status_bar_config" SharedPreferences.
class WidgetBridge {
  static const _channel = MethodChannel('com.example.date_time_widget/widgets');

  /// Tell the native [DateTimeWidgetProvider] to re-read config and
  /// redraw every widget instance now.
  ///
  /// [configJson] — the ClockConfig serialized as JSON string.
  /// If null, native reads from its own SharedPreferences.
  static Future<void> updateWidgets({String? configJson}) async {
    try {
      await _channel.invokeMethod<void>('updateWidgets', {
        'configJson': configJson,
      });
    } on PlatformException catch (_) {
      // Widget channel not available (e.g. running on iOS simulator)
    }
  }

  /// Save baked bitmap path for a specific widget instance.
  ///
  /// [widgetId] — the Android AppWidget ID.
  /// [bitmapPath] — absolute path to the baked PNG file, or null to clear.
  static Future<void> setWidgetBackground({
    required int widgetId,
    required String? bitmapPath,
  }) async {
    try {
      await _channel.invokeMethod<void>('setWidgetBackground', {
        'widgetId': widgetId,
        'bitmapPath': bitmapPath,
      });
    } on PlatformException catch (_) {
      // Widget channel not available
    }
  }

  /// Get all active widget IDs.
  static Future<List<int>> getActiveWidgetIds() async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('getActiveWidgetIds');
      return result?.cast<int>() ?? [];
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Ask the OS to open the widget picker so the user can add our widget
  /// to their home screen.  Returns `true` if the picker was opened.
  static Future<bool> requestWidgetPick() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestWidgetPick');
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }
}
