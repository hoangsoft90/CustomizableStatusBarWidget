# Boot Receiver (Native Android)

## Purpose

Listens for `BOOT_COMPLETED` broadcast and re-enables services the user had active before reboot: TimeTickService, NotificationIconService, FloatingBarService, and force-updates all widget instances.

## Requirements

### R1: BOOT_COMPLETED filter

Registered in AndroidManifest with `android.intent.action.BOOT_COMPLETED` intent filter.

**Scenario: Manifest registration**
- Given the app is installed
- When device boots
- Then `BootReceiver.onReceive` is called with `ACTION_BOOT_COMPLETED`
- Reference: `AndroidManifest.xml` (receiver entry)

### R2: Starts TimeTickService

Always starts `TimeTickService` on boot (it's the coordinator for all tick updates).

**Scenario: Boot → TimeTickService**
- Given device just rebooted
- When `onReceive` fires
- Then `TimeTickService.start(context)` is called
- Reference: `BootReceiver.kt:18-22`

### R3: Conditionally restarts NotificationIconService

Only restarts notification if user had it enabled before reboot.

**Scenario: Notification was enabled**
- Given `NotificationIconService.isEnabled(context) == true`
- When boot completes
- Then `NotificationIconService.start(context)` is called
- Reference: `BootReceiver.kt:25-30`

**Scenario: Notification was disabled**
- Given `NotificationIconService.isEnabled(context) == false`
- When boot completes
- Then notification service is NOT started
- Reference: `BootReceiver.kt:25-30`

### R4: Conditionally restarts FloatingBarService

Only restarts floating bar if user had it enabled before reboot.

**Scenario: Floating bar was enabled**
- Given `FloatingBarService.isEnabled(context) == true`
- When boot completes
- Then `FloatingBarService` is started via `startForegroundService` (API 26+) or `startService`
- Reference: `BootReceiver.kt:33-41`

### R5: Force-updates all widgets

Always calls `DateTimeWidgetProvider.updateAllWidgets(context)` to refresh widget displays after boot.

**Scenario: Widget refresh on boot**
- When boot completes
- Then `DateTimeWidgetProvider.updateAllWidgets(context)` is called
- Reference: `BootReceiver.kt:44-48`

### R6: Try-catch safety

Each service restart is wrapped in individual try-catch with `Log.e()` — one failure does not prevent other services from restarting.

**Scenario: Notification service fails**
- Given `NotificationIconService.start()` throws an exception
- When `onReceive` runs
- Then the exception is logged
- And `FloatingBarService` and widget update still execute
- Reference: `BootReceiver.kt:24-49`
