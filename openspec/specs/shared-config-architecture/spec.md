# Shared Config Architecture

## Purpose

Defines how ClockConfig flows between Flutter and native Android. Flutter is the source of truth; config is serialized to JSON and passed via MethodChannel to native, which saves it to a shared SharedPreferences file that all 3 native services read from.

## Requirements

### R1: Config flow — Flutter to Native

```
Flutter saveConfig() → ClockConfig.toJsonString()
  → MethodChannel 'updateWidgets' / 'updateNotification' / 'updateFloatingBar'
  → Native: save to SharedPreferences("status_bar_config"), key "clock_config"
```

**Scenario: Config propagation on save**
- Given user saves new config in EditorScreen
- When `WidgetBridge.updateWidgets(configJson: json)` is called
- Then `DateTimeWidgetProvider.saveConfig(context, json)` writes to SharedPreferences
- And all 3 native services are updated
- Reference: `DateTimeWidgetProvider.kt:43-49`

### R2: Native reads from SharedPreferences

All 3 native services read from the same SharedPreferences file (`"status_bar_config"`) and key (`"clock_config"`).

**Scenario: All services read same config**
- Given SharedPreferences has `{"color":"#FF0000","fontSize":40,...}`
- When DateTimeWidgetProvider reads config
- And NotificationIconService reads config
- And FloatingBarService reads config
- Then all 3 receive identical ClockData
- Reference: `DateTimeWidgetProvider.kt:122-129`, `NotificationIconService.kt:119-122`, `FloatingBarService.kt:301-307`

### R3: JSON parsing in native (regex-based)

Native Kotlin code parses JSON using regex patterns (not a JSON library). Each field is extracted by key via `extract()` helper function.

**Scenario: Parse format field**
- Given JSON: `"format":"dd/MM/yyyy"`
- When `parseClockData` runs
- Then `ClockData.format == "dd/MM/yyyy"`
- Reference: `DateTimeWidgetProvider.kt:131-153`

**Scenario: Parse boolean field**
- Given JSON: `"showSeconds":true`
- When `parseClockData` runs
- Then `ClockData.showSeconds == true`
- Reference: `DateTimeWidgetProvider.kt:137-138`

### R4: ClockData data class duplicated in 3 native files

Each of `DateTimeWidgetProvider`, `NotificationIconService`, and `FloatingBarService` defines its own `ClockData` data class and `parseClockData()` function with identical fields and logic.

**Scenario: All three have same ClockData**
- Given the 3 native Kotlin files
- Then each defines `data class ClockData(format, timeFormat, showSeconds, showDate, showDay, fontSize, color, alignment)`
- Reference: `DateTimeWidgetProvider.kt:169-178`, `NotificationIconService.kt:152-161`, `FloatingBarService.kt:315-324`

### R5: Default config on native side

If SharedPreferences has no config or parse fails, all native services fall back to `ClockData()` defaults (matching Flutter's `ClockConfig.defaults()`).

**Scenario: No config saved**
- Given SharedPreferences is empty
- When any native service reads config
- Then `ClockData()` defaults are used (format: 'EEE dd MMM', fontSize: 32.0, etc.)
- Reference: `DateTimeWidgetProvider.kt:126`, `NotificationIconService.kt:121`, `FloatingBarService.kt:305`

### R6: Bidirectional sync

Config changes from Flutter → native (via MethodChannel). Config is never modified by native and sent back to Flutter — Flutter always holds the canonical version.

**Scenario: One-way flow**
- Given user changes config in Flutter Editor
- When save happens
- Then config flows Flutter → native only
- And native never writes back to Flutter's ClockConfig
- Reference: Cross-cutting: bridges + native services

## Need to clear

1. **ClockData duplication across 3 files** — Each native file has its own `ClockData` + `parseClockData()`. This works correctly but violates DRY. Extracting to a shared utility class is noted as technical debt for v1.1.
