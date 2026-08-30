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
