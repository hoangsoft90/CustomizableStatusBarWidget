import 'package:flutter/services.dart';

/// Bridges Flutter ↔ Native Android widget.
///
/// When the user saves a new [ClockConfig] in the Editor, call
/// [updateWidgets] to trigger an immediate refresh of every home-screen
/// widget instance — no waiting for the next 60-second alarm cycle.
class WidgetBridge {
  static const _channel = MethodChannel('com.example.date_time_widget/widgets');

  /// Tell the native [DateTimeWidgetProvider] to re-read config and
  /// redraw every widget instance now.
  static Future<void> updateWidgets() async {
    try {
      await _channel.invokeMethod<void>('updateWidgets');
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
