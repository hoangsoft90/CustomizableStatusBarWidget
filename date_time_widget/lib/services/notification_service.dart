import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import 'storage_service.dart';

/// Handles the full notification-icon flow from the Flutter side:
///
/// 1. Check if notification permission is granted (Android 13+).
/// 2. Show an explanation dialog before requesting.
/// 3. Request POST_NOTIFICATIONS permission.
/// 4. Start / stop the native [NotificationIconService] via MethodChannel.
///
/// On pre-Android-13 devices the permission is granted at install time,
/// so we skip straight to starting the service.
class NotificationService {
  static const _channel =
      MethodChannel('com.example.date_time_widget/notification');

  final StorageService _storage;

  NotificationService(this._storage);

  /// Current enabled state, persisted in SharedPreferences.
  bool get isEnabled => _loadEnabled();

  // ── Public API ────────────────────────────────────────────

  /// Full flow: show explanation → request permission → start service.
  /// Returns `true` if the service was started.
  ///
  /// [context] is needed to show the explanation dialog.
  Future<bool> enable(BuildContext context) async {
    // 1. Show explanation
    final proceed = await _showExplanation(context);
    if (!proceed) return false;

    // 2. Request permission (Android 13+)
    final granted = await _requestPermission();
    if (!granted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission denied. You can enable it later in Settings.',
            ),
          ),
        );
      }
      return false;
    }

    // 3. Start native service
    final started = await _startNative();
    if (started) {
      _saveEnabled(true);
    }
    return started;
  }

  /// Stop the native notification service.
  Future<void> disable() async {
    await _stopNative();
    _saveEnabled(false);
  }

  /// Refresh the notification content (e.g. after config change).
  Future<void> update() async {
    if (!_loadEnabled()) return;
    await _updateNative();
  }

  // ── Internal ──────────────────────────────────────────────

  /// Show a clear explanation of what the notification does.
  /// Returns `true` if user taps "Enable", `false` otherwise.
  Future<bool> _showExplanation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.notifications_active_outlined, size: 36),
        title: const Text('Enable Date Icon'),
        content: const Text(
          'A small, persistent date icon will appear in your status bar.\n\n'
          '• Shows the current day number (e.g. "30")\n'
          '• Pull down to see full day, date & time\n'
          '• Updates automatically every minute\n'
          '• Can be disabled any time from the app',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Enable'),
          ),
        ],
      ),
    );
    return result == true;
  }

  /// Request POST_NOTIFICATIONS permission (Android 13+).
  Future<bool> _requestPermission() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    final result = await Permission.notification.request();
    return result.isGranted;
  }

  Future<bool> _startNative() async {
    try {
      final result = await _channel.invokeMethod<bool>('startNotification');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _stopNative() async {
    try {
      final result = await _channel.invokeMethod<bool>('stopNotification');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _updateNative() async {
    try {
      final result = await _channel.invokeMethod<bool>('updateNotification');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Persistence ──────────────────────────────────────────

  static const _enabledKey = 'notificationEnabled';

  bool _loadEnabled() {
    // Try SharedPreferences first (Flutter side)
    return _storage.prefs.getBool(_enabledKey) ?? false;
  }

  void _saveEnabled(bool value) {
    _storage.prefs.setBool(_enabledKey, value);
    // Also update ClockConfig
    final config = _storage.loadConfig();
    _storage.saveConfig(config.copyWith(notificationEnabled: value));
  }
}
