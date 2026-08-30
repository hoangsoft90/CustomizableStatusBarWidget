# Notification Service (Flutter)

## Purpose

Handles the full notification-icon flow from the Flutter side: permission explanation dialog, POST_NOTIFICATIONS runtime permission request, and start/stop native NotificationIconService via MethodChannel.

## Requirements

### R1: Enable flow — explanation → permission → start

`enable(context)` shows an explanation dialog, then requests permission, then starts native service.

**Scenario: Full enable flow**
- Given notification is not enabled
- When `enable(context)` is called
- Then a dialog "Enable Date Icon" is shown explaining what the notification does
- When user taps "Enable"
- Then `Permission.notification.request()` is called
- If granted, `_channel.invokeMethod('startNotification')` is called
- And enabled state is saved to SharedPreferences
- Reference: `lib/services/notification_service.dart:28-44`

**Scenario: User declines explanation**
- When user taps "Not now" in the explanation dialog
- Then `enable()` returns `false` and no permission is requested
- Reference: `lib/services/notification_service.dart:30-32`

**Scenario: Permission denied**
- Given explanation was accepted but permission is denied
- When `_requestPermission()` returns `false`
- Then a SnackBar "Notification permission denied..." is shown
- And `enable()` returns `false`
- Reference: `lib/services/notification_service.dart:36-42`

### R2: Disable flow

`disable()` stops the native service and saves disabled state.

**Scenario: Disable**
- When `disable()` is called
- Then `_channel.invokeMethod('stopNotification')` is called
- And `_saveEnabled(false)` persists the state
- Reference: `lib/services/notification_service.dart:47-50`

### R3: Update passes configJson

`update()` passes the current ClockConfig as JSON string to native via MethodChannel.

**Scenario: Update with config**
- Given notification is enabled
- When `update()` is called
- Then `_channel.invokeMethod('updateNotification', {'configJson': configJson})` is called
- Reference: `lib/services/notification_service.dart:55-60`

**Scenario: Update when disabled — no-op**
- Given notification is disabled
- When `update()` is called
- Then nothing happens (early return)
- Reference: `lib/services/notification_service.dart:54`

### R4: isEnabled reads from SharedPreferences

`isEnabled` reads a boolean from SharedPreferences key `'notificationEnabled'`.

**Scenario: Default is false**
- Given no value saved
- When `isEnabled` is read
- Then it returns `false`
- Reference: `lib/services/notification_service.dart:93-95`
