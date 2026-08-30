# ClockConfig Model

## Purpose

Immutable data model representing the full clock display configuration. Serves as the single source of truth for all display layers (Flutter UI, home-screen widget, notification icon, floating bar). Serialized to JSON and shared across Flutter and native Android via SharedPreferences.

## Requirements

### R1: Immutable 12-field model

ClockConfig holds exactly 12 named fields with the following types and defaults:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `format` | `String` | `'EEE dd MMM'` | Date format pattern |
| `timeFormat` | `String` | `'HH:mm'` | Time format pattern |
| `showSeconds` | `bool` | `false` | Show seconds in clock |
| `showDate` | `bool` | `true` | Show date line |
| `showDay` | `bool` | `true` | Show day-of-week line |
| `fontSize` | `double` | `32` | Base font size |
| `color` | `String` | `'#FFFFFF'` | Text color as hex string |
| `alignment` | `String` | `'center'` | Text alignment: left, center, right |
| `notificationEnabled` | `bool` | `false` | Whether notification icon is active |
| `floatingBarEnabled` | `bool` | `false` | Whether floating bar is active |
| `unlockedPresets` | `List<String>` | `['basic1', 'basic2']` | Unlocked preset IDs |
| `isPremium` | `bool` | `false` | Whether user purchased premium IAP |

**Scenario: Default construction**
- Given a fresh app launch with no saved config
- When `ClockConfig.defaults()` is called
- Then the returned instance has all default values as listed above
- Reference: `lib/models/clock_config.dart:34`

**Scenario: Named constructor defaults**
- Given `const ClockConfig()` is used
- Then the result is identical to `ClockConfig.defaults()`
- Reference: `lib/models/clock_config.dart:36`

### R2: JSON serialization round-trip

ClockConfig can be serialized to JSON and deserialized back with lossless round-trip for all 12 fields.

**Scenario: toJson produces correct keys**
- Given a ClockConfig with `format: 'dd/MM/yyyy'`, `fontSize: 28`, `color: '#FF5722'`
- When `toJson()` is called
- Then the resulting map contains keys matching all 12 field names exactly
- And `fontSize` is serialized as a number (double), not a string
- And `unlockedPresets` is serialized as a JSON array of strings
- Reference: `lib/models/clock_config.dart:87-100`

**Scenario: fromJson tolerates missing fields**
- Given a JSON map missing the `showSeconds` key
- When `ClockConfig.fromJson(json)` is called
- Then `showSeconds` defaults to `false`
- And all other present fields are parsed correctly
- Reference: `lib/models/clock_config.dart:47-65`

**Scenario: fromJson handles null values gracefully**
- Given a JSON map where `fontSize` is `null`
- When `ClockConfig.fromJson(json)` is called
- Then `fontSize` defaults to `32`
- Reference: `lib/models/clock_config.dart:53`

**Scenario: fromJsonString round-trips**
- Given a ClockConfig instance
- When `fromJsonString(config.toJsonString())` is called
- Then the result equals the original instance (via `==`)
- Reference: `lib/models/clock_config.dart:70-72`

### R3: copyWith for selective mutation

`copyWith` returns a new instance with only the specified fields overridden; unspecified fields retain their current values.

**Scenario: Single field override**
- Given a ClockConfig with `format: 'HH:mm'` and `fontSize: 32`
- When `copyWith(fontSize: 40)` is called
- Then the result has `fontSize: 40` and `format: 'HH:mm'`
- Reference: `lib/models/clock_config.dart:104-123`

**Scenario: Multiple field override**
- Given any ClockConfig
- When `copyWith(color: '#FF0000', alignment: 'left', showSeconds: true)` is called
- Then all three fields are updated and all other fields remain unchanged
- Reference: `lib/models/clock_config.dart:104-123`

### R4: Value equality

Two ClockConfig instances are equal if and only if all 12 fields match. The `unlockedPresets` list is compared element-by-element (not by reference).

**Scenario: Identical configs are equal**
- Given `a = ClockConfig()` and `b = ClockConfig()`
- Then `a == b` is `true`

**Scenario: Differing single field**
- Given `a = ClockConfig()` and `b = ClockConfig(fontSize: 40)`
- Then `a == b` is `false`

**Scenario: UnlockedPresets compared by value**
- Given `a = ClockConfig(unlockedPresets: ['basic1', 'basic2'])` and `b = ClockConfig(unlockedPresets: ['basic1', 'basic2'])`
- Then `a == b` is `true`
- Reference: `lib/models/clock_config.dart:126-143`

### R5: Constructor is const-eligible

The primary constructor is marked `const`, allowing compile-time constant instances (e.g., default presets).

**Scenario: Const construction**
- Given `const ClockConfig(format: 'dd/MM')`
- Then the instance is a compile-time constant
- Reference: `lib/models/clock_config.dart:36`

## Need to clear

1. **`alignment` field is a String, not an enum** — code uses raw strings `'left'`, `'center'`, `'right'` throughout. This is technically unvalidated: any string value (e.g., `'justify'`) can be passed without compile-time error. Current code handles this via a default fallback to `center` in downstream consumers. Is this intentional flexibility or should it be an enum?
