# Floating Bar Bridge

## Purpose

Bridges Flutter ↔ Native Android floating bar foreground service. Handles overlay permission check/request, start/stop, config update, and enabled state query.

## Requirements

### R1: hasOverlayPermission

Checks if `SYSTEM_ALERT_WINDOW` permission is granted.

**Scenario: Permission granted**
- Given overlay permission is granted
- When `FloatingBarBridge.hasOverlayPermission()` is called
- Then it returns `true`
- Reference: `lib/services/floating_bar_bridge.dart:13-18`

### R2: requestOverlayPermission

Opens the system "Display over other apps" settings screen.

**Scenario: Request permission**
- When `FloatingBarBridge.requestOverlayPermission()` is called
- Then the MethodChannel invokes `'requestOverlayPermission'`
- And the system settings screen opens
- Reference: `lib/services/floating_bar_bridge.dart:21-25`

### R3: start / stop

Start and stop the floating bar foreground service.

**Scenario: Start**
- When `FloatingBarBridge.start()` is called
- Then `'startFloatingBar'` is invoked on native side
- Reference: `lib/services/floating_bar_bridge.dart:28-32`

**Scenario: Stop**
- When `FloatingBarBridge.stop()` is called
- Then `'stopFloatingBar'` is invoked on native side
- Reference: `lib/services/floating_bar_bridge.dart:35-39`

### R4: update passes configJson

`update(configJson)` invokes `'updateFloatingBar'` with the config JSON string.

**Scenario: Update with config**
- Given `configJson` contains serialized ClockConfig
- When `FloatingBarBridge.update(configJson: configJson)` is called
- Then native side saves config to SharedPreferences and updates overlay in-place
- Reference: `lib/services/floating_bar_bridge.dart:45-52`

### R5: isEnabled query

Returns whether the floating bar service is currently enabled (persisted in SharedPreferences).

**Scenario: Check enabled**
- When `FloatingBarBridge.isEnabled()` is called
- Then the native side reads `FlutterSharedPreferences.floatingBarEnabled`
- Reference: `lib/services/floating_bar_bridge.dart:56-61`
