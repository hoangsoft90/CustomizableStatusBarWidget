# Widget Bridge

## Purpose

Bridges Flutter ↔ Native Android home-screen widget. When the user saves a new ClockConfig, this service triggers an immediate refresh of every widget instance. Also manages per-widget background bitmap paths.

## Requirements

### R1: updateWidgets passes configJson

`updateWidgets(configJson)` invokes `'updateWidgets'` on the native side with the config JSON string.

**Scenario: With configJson**
- Given `configJson = '{"format":"dd/MM/yyyy",...}'`
- When `WidgetBridge.updateWidgets(configJson: configJson)` is called
- Then the MethodChannel receives `{'configJson': configJson}`
- Reference: `lib/services/widget_bridge.dart:16-23`

**Scenario: Without configJson**
- When `WidgetBridge.updateWidgets()` is called (no argument)
- Then the MethodChannel receives `{'configJson': null}`
- And native side reads from its own SharedPreferences
- Reference: `lib/services/widget_bridge.dart:16-23`

### R2: requestWidgetPick

`requestWidgetPick()` asks the OS to open the widget picker. Currently returns `false` (not implemented on native side).

**Scenario: Request widget pick**
- When `WidgetBridge.requestWidgetPick()` is called
- Then the MethodChannel method `'requestWidgetPick'` is invoked
- And the result is `false`
- Reference: `lib/services/widget_bridge.dart:28-34`

### R3: PlatformException handling

All MethodChannel calls are wrapped in try-catch for `PlatformException`, silently returning on failure (e.g., running on iOS simulator).

**Scenario: Platform not available**
- Given the app is running on a non-Android platform
- When any bridge method is called
- Then `PlatformException` is caught and the method returns default value (false/void)
- Reference: `lib/services/widget_bridge.dart:18-22`, `30-33`

### R4: setWidgetBackground — shared bitmap path (plan5 §3, plan8 §1)

`setWidgetBackground(widgetId, bitmapPath)` saves the baked bitmap file path to a shared SharedPreferences namespace `widget_background` with key `bg_bitmap_path`. This is a single global path (not per-widgetId) because all widget instances share the same background.

**Scenario: Set background path**
- Given `bitmapPath = '/data/.../widget_bg/bg_1234567890.png'`
- When `WidgetBridge.setWidgetBackground(widgetId: 42, bitmapPath: bitmapPath)` is called
- Then native saves path to SharedPreferences namespace `widget_background`, key `bg_bitmap_path`
- And re-renders widget instance 42 via `DateTimeWidgetProvider.renderWidget()`
- Reference: `lib/services/widget_bridge.dart:36-50`

**Scenario: Clear background**
- Given a background path exists in SharedPreferences
- When `WidgetBridge.setWidgetBackground(widgetId: 42, bitmapPath: null)` is called
- Then key `bg_bitmap_path` is removed from SharedPreferences namespace `widget_background`
- And widget falls back to default dark background
- Reference: `lib/services/widget_bridge.dart:36-50`

### R5: getActiveWidgetIds — list all widget instances (plan5 §3)

`getActiveWidgetIds()` returns a list of all active widget IDs from AppWidgetManager.

**Scenario: Get widget IDs**
- Given 2 widget instances on home screen (IDs: 5, 12)
- When `WidgetBridge.getActiveWidgetIds()` is called
- Then the result is `[5, 12]`
- Reference: `lib/services/widget_bridge.dart:50-58`
