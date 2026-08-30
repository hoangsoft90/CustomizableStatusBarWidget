# Test Suite

## Purpose

Unit tests covering core logic: StorageService, DateFormatter, EditorConfig, NotificationConfig, FloatingBarConfig, Widget model, IAP premium flow, and plan2 fixes. 69 tests total.

## Requirements

### R1: StorageService tests

Tests for save/load round-trip, defaults, and clearAll.

**Scenario: Save then load**
- Given a ClockConfig with custom values
- When `saveConfig(config)` is called, then `loadConfig()`
- Then the loaded config equals the saved config
- Reference: `test/storage_service_test.dart`

**Scenario: Load defaults when empty**
- Given no config saved
- When `loadConfig()` is called
- Then result equals `ClockConfig.defaults()`
- Reference: `test/storage_service_test.dart`

### R2: DateFormatter tests

Tests for time formatting (12h/24h, seconds), date formatting (multiple patterns), day formatting (full/short/uppercase).

**Scenario: 24h time format**
- Given `timeFormat: 'HH:mm'` and time 14:05
- When formatted
- Then result is `'14:05'`
- Reference: `test/date_formatter_test.dart`

**Scenario: 12h time with AM/PM**
- Given `timeFormat: 'hh:mm a'` and time 08:30
- When formatted
- Then result is `'08:30 AM'`
- Reference: `test/date_formatter_test.dart`

### R3: Editor config tests

Tests for ClockConfig copyWith, default values, and format options.

**Scenario: copyWith preserves unchanged fields**
- Given `ClockConfig(format: 'dd/MM', fontSize: 32)`
- When `copyWith(fontSize: 40)` is called
- Then `format` is still `'dd/MM'` and `fontSize` is `40`
- Reference: `test/editor_config_test.dart`

### R4: Notification config tests

Tests for notification-related config fields and their defaults.

**Scenario: Default notification disabled**
- Given `ClockConfig()`
- Then `notificationEnabled == false`
- Reference: `test/notification_config_test.dart`

### R5: Floating bar config tests

Tests for floating bar config sync — JSON serialization/deserialization matching the native ClockData structure.

**Scenario: Config JSON matches native expectations**
- Given a ClockConfig with all fields set
- When serialized to JSON string
- Then native Kotlin `parseClockData()` would produce matching ClockData
- Reference: `test/floating_bar_config_test.dart`

### R6: Widget model tests

Tests for WidgetConfig toMap/fromMap, WidgetSize calculations.

**Scenario: toMap includes widgetSize**
- Given `WidgetConfig(clockConfig: c, size: WidgetSize.fourByTwo)`
- When `toMap()` is called
- Then result contains `'widgetSize': 'fourByTwo'`, `'columns': 4`, `'rows': 2`
- Reference: `test/widget_test.dart`

### R7: IAP premium tests

Tests for premium state transitions and preset unlocking.

**Scenario: Premium unlocks all presets**
- Given a config with `isPremium: false` and only 2 presets unlocked
- When premium is activated
- Then `unlockedPresets` contains all 8 preset IDs
- Reference: `test/iap_premium_test.dart`

### R8: Plan2 fixes tests

21 tests covering the 9 fixes from plan2_final.md:
- Sunday crash guard (dayIdx < 0 → 6)
- Config JSON contains all 8 fields
- Alignment in config
- Locale-aware formatting
- FloatingBar update in-place

**Scenario: Sunday index guard**
- Given `Calendar.DAY_OF_WEEK == Calendar.SUNDAY` (dayIdx = -1)
- When guard is applied
- Then `dayIdxSafe == 6`
- Reference: `test/plan2_fixes_test.dart`

**Scenario: Config has all fields**
- Given `ClockConfig()`
- When `toJson()` is called
- Then the map contains keys: format, timeFormat, showSeconds, showDate, showDay, fontSize, color, alignment, notificationEnabled, floatingBarEnabled, unlockedPresets, isPremium
- Reference: `test/plan2_fixes_test.dart`

### R9: All 69 tests pass

The full test suite runs without failures.

**Scenario: Full suite**
- When `flutter test` is run
- Then 69/69 tests pass
- Reference: CI output
