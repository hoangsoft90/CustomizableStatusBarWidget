# TimeTick Service (Native Android)

## Purpose

ForegroundService that registers a dynamic BroadcastReceiver for `Intent.ACTION_TIME_TICK`. On each tick, updates all three services (Widget, Notification, FloatingBar) via `DateTimeWidgetProvider.onTick()`. Replaces the previous AlarmManager approach.

## Requirements

### R1: Dynamic broadcast receiver

Registers a `BroadcastReceiver` for `ACTION_TIME_TICK` in `onStartCommand`. Registered dynamically (not in AndroidManifest) because API 26+ prohibits implicit broadcast receivers for this intent.

**Scenario: Receiver registered**
- When `onStartCommand` runs
- Then `registerReceiver(tickReceiver, filter)` is called
- And the receiver listens for `Intent.ACTION_TIME_TICK`
- Reference: `TimeTickService.kt:55-73`

**Scenario: API 33+ not-exported flag**
- Given device is Android 13+ (TIRAMISU)
- When receiver is registered
- Then `Context.RECEIVER_NOT_EXPORTED` flag is passed
- Reference: `TimeTickService.kt:68-69`

### R2: Tick updates all services

On `ACTION_TIME_TICK`, calls `DateTimeWidgetProvider.onTick(context)` which cascades to update all three services.

**Scenario: Tick received**
- When `onReceive` fires with `ACTION_TIME_TICK`
- Then `DateTimeWidgetProvider.onTick(context)` is called
- And `Log.d(TAG, "TIME_TICK received — updating all services")` is logged
- Reference: `TimeTickService.kt:62-65`

### R3: Initial update on start

`onStartCommand` calls `DateTimeWidgetProvider.onTick(this)` immediately after registering the receiver, to sync all services on service start.

**Scenario: Service start**
- When `onStartCommand` runs
- Then `DateTimeWidgetProvider.onTick(this)` is called for initial sync
- Reference: `TimeTickService.kt:53`

### R4: Foreground notification

Service shows a MIN priority ongoing notification "Date & Time Widget — Keeping your widgets in sync".

**Scenario: Foreground notification**
- When service starts
- Then `startForeground(NOTIFICATION_ID, notification)` is called with `PRIORITY_MIN`
- Reference: `TimeTickService.kt:46-47`

### R5: Cleanup on destroy

`onDestroy` unregisters the tick receiver.

**Scenario: Service destroyed**
- When `onDestroy` runs
- Then `unregisterReceiver(tickReceiver)` is called (with try-catch)
- Reference: `TimeTickService.kt:76-78`

### R6: start/stop static methods

`TimeTickService.start(context)` and `stop(context)` manage the service lifecycle via Intent.

**Scenario: Start from BootReceiver**
- Given device just rebooted
- When `TimeTickService.start(context)` is called
- Then the service starts via `startForegroundService` (API 26+) or `startService`
- Reference: `TimeTickService.kt:24-30`

## Need to clear

1. **No auto-stop mechanism** — the service runs indefinitely (START_STICKY) until the app process is killed. There is no logic to stop it when all features (notification, widget, floating bar) are disabled. This is noted as a known limitation.
