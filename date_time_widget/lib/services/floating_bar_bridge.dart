import 'package:flutter/services.dart';

/// Bridges Flutter ↔ Native Android floating bar service.
///
/// The floating bar uses `TYPE_APPLICATION_OVERLAY` and sits
/// RIGHT BELOW the real status bar — it does NOT draw on top
/// of System UI (plan1_final.md §0, §5).
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
  static Future<void> update() async {
    try {
      await _channel.invokeMethod<void>('updateFloatingBar');
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
