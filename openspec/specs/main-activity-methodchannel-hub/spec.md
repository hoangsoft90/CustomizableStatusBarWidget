# MainActivity MethodChannel Hub

## Purpose

FlutterActivity subclass that registers 4 MethodChannel handlers, manages overlay permission, and handles deep link intents. Serves as the bridge between Flutter Dart code and native Android services.

## Requirements

### R1: 4 MethodChannels registered

| Channel | Purpose |
|---------|---------|
| `com.example.date_time_widget/widgets` | Home-screen widget updates |
| `com.example.date_time_widget/notification` | Notification icon control |
| `com.example.date_time_widget/floating_bar` | Floating bar control |
| `com.example.date_time_widget/deep_link` | Widget tap → editor |

**Scenario: All channels registered**
- When `configureFlutterEngine` runs
- Then all 4 MethodChannel handlers are set
- Reference: `MainActivity.kt:17-20`

### R2: Widget channel — updateWidgets

Handles `updateWidgets` method: if `configJson` is provided, calls `DateTimeWidgetProvider.saveConfig()`; otherwise calls `updateAllWidgets()`.

**Scenario: With configJson**
- Given Flutter sends `updateWidgets` with `{'configJson': '{"format":"dd/MM"}'}`
- When the handler processes it
- Then `DateTimeWidgetProvider.saveConfig(this, configJson)` is called
- Reference: `MainActivity.kt:30-36`

**Scenario: Without configJson**
- Given Flutter sends `updateWidgets` with `{'configJson': null}`
- When the handler processes it
- Then `DateTimeWidgetProvider.updateAllWidgets(this)` is called
- Reference: `MainActivity.kt:34-35`

### R3: Notification channel — start/stop/update

Handles `startNotification`, `stopNotification`, `updateNotification`, `isNotificationEnabled`.

**Scenario: startNotification**
- When `'startNotification'` is called
- Then `NotificationIconService.start(this)` runs
- Reference: `MainActivity.kt:42-44`

**Scenario: updateNotification with configJson**
- When `'updateNotification'` is called with `configJson`
- Then `NotificationIconService.saveConfig(this, configJson)` runs
- Reference: `MainActivity.kt:48-52`

### R4: Floating bar channel — full lifecycle

Handles `startFloatingBar`, `stopFloatingBar`, `updateFloatingBar`, `isFloatingBarEnabled`, `hasOverlayPermission`, `requestOverlayPermission`.

**Scenario: hasOverlayPermission**
- Given API level >= M
- When `'hasOverlayPermission'` is called
- Then `Settings.canDrawOverlays(this)` is returned
- Reference: `MainActivity.kt:69-71`

**Scenario: requestOverlayPermission**
- Given overlay permission is not granted
- When `'requestOverlayPermission'` is called
- Then system settings `ACTION_MANAGE_OVERLAY_PERMISSION` is opened
- Reference: `MainActivity.kt:73-75`, `82-90`

### R5: Deep link channel

Registers a MethodChannel for `deep_link`. On `onNewIntent`, if `open_editor` extra is true, invokes `openEditor` on the Flutter side.

**Scenario: Widget tap deep link**
- Given user taps the home-screen widget
- When the app receives intent with `open_editor=true`
- Then `deepLinkChannel.invokeMethod("openEditor", null)` is called
- Reference: `MainActivity.kt:94-99`

### R6: TimeTickService starts on app launch

`configureFlutterEngine` calls `TimeTickService.start(this)` to ensure the tick service is always running when the app is open.

**Scenario: App launch**
- When `configureFlutterEngine` runs
- Then `TimeTickService.start(this)` is called
- Reference: `MainActivity.kt:78`
