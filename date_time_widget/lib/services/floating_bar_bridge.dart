import 'package:flutter/services.dart';

/// Bridges Flutter ↔ Native Android floating bar service.
///
/// #3: Now passes the config JSON to native via MethodChannel.
/// Native saves it to "status_bar_config" SharedPreferences.
class FloatingBarBridge {
  static const _channel =
      MethodChannel('com.example.date_time_widget/floating_bar');

  /// Check if SYSTEM_ALERT_WINDOW permission is granted.
  static Future<bool> hasOverlayPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open the system "Display over other apps" settings screen.
  static Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } on PlatformException catch (_) {}
  }

  /// Start the floating bar foreground service.
  static Future<void> start() async {
    try {
      await _channel.invokeMethod<void>('startFloatingBar');
    } on PlatformException catch (_) {}
  }

  /// Stop the floating bar foreground service.
  static Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stopFloatingBar');
    } on PlatformException catch (_) {}
  }

  /// Restart the service to pick up config changes.
  ///
  /// [configJson] — the ClockConfig serialized as JSON string.
  /// If null, native reads from its own SharedPreferences.
  static Future<void> update({String? configJson}) async {
    try {
      await _channel.invokeMethod<void>('updateFloatingBar', {
        'configJson': configJson,
      });
    } on PlatformException catch (_) {}
  }

  /// Check if the service is currently enabled.
  static Future<bool> isEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFloatingBarEnabled');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
