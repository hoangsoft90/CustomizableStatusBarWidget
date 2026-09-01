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
/// #3: update() now passes configJson to native via MethodChannel.
class NotificationService {
  static const _channel =
      MethodChannel('io.photoclock.widget/notification');

  final StorageService _storage;

  NotificationService(this._storage);

  /// Current enabled state, persisted in SharedPreferences.
  bool get isEnabled => _loadEnabled();

  // ── Public API ────────────────────────────────────────────

  /// Full flow: show explanation → request permission → start service.
  /// Returns `true` if the service was started.
  Future<bool> enable(BuildContext context) async {
    final proceed = await _showExplanation(context);
    if (!proceed) return false;

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
  ///
  /// #3: Now passes the current config JSON to native.
  Future<void> update() async {
    if (!_loadEnabled()) return;
    final configJson = _storage.loadConfig().toJsonString();
    await _updateNative(configJson: configJson);
  }

  // ── Internal ──────────────────────────────────────────────

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

  /// #3: Pass configJson to native notification service.
  Future<bool> _updateNative({String? configJson}) async {
    try {
      final result = await _channel.invokeMethod<bool>('updateNotification', {
        'configJson': configJson,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Persistence ──────────────────────────────────────────

  static const _enabledKey = 'notificationEnabled';

  bool _loadEnabled() {
    return _storage.prefs.getBool(_enabledKey) ?? false;
  }

  void _saveEnabled(bool value) {
    _storage.prefs.setBool(_enabledKey, value);
    final config = _storage.loadConfig();
    _storage.saveConfig(config.copyWith(notificationEnabled: value));
  }
}
