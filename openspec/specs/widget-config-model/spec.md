# WidgetConfig Model

## Purpose

Wraps a ClockConfig together with a WidgetSize to describe a specific home-screen widget instance. Used for MethodChannel communication between Flutter and native Android AppWidgetProvider.

## Requirements

### R1: WidgetSize enum with 4 variants

```dart
enum WidgetSize {
  twoByOne(2, 1),
  threeByOne(3, 1),
  fourByOne(4, 1),
  fourByTwo(4, 2);
}
```

**Scenario: Cell dimensions**
- Given `WidgetSize.fourByTwo`
- Then `columns == 2` and `rows == 2`
- And `minWidthDp == 140` (2 × 70)
- And `minHeightDp == 140` (2 × 70)
- Reference: `lib/models/widget_config.dart:13-28`

**Scenario: Label format**
- Given `WidgetSize.threeByOne`
- Then `label == '3×1'`
- Reference: `lib/models/widget_config.dart:28`

### R2: toMap serialization

`toMap()` merges ClockConfig JSON fields with widget-specific metadata (`widgetSize`, `columns`, `rows`).

**Scenario: toMap includes all ClockConfig fields**
- Given a WidgetConfig with a ClockConfig containing `color: '#FF0000'`
- When `toMap()` is called
- Then the result contains `'color': '#FF0000'`
- And also contains `'widgetSize': 'fourByOne'`, `'columns': 4`, `'rows': 1`
- Reference: `lib/models/widget_config.dart:37-42`

### R3: fromMap deserialization

`fromMap` reconstructs a WidgetConfig from a map, defaulting to `WidgetSize.fourByOne` if the size string is unrecognized.

**Scenario: Unknown size defaults to fourByOne**
- Given a map with `'widgetSize': 'unknown_size'`
- When `WidgetConfig.fromMap(map)` is called
- Then `size == WidgetSize.fourByOne`
- Reference: `lib/models/widget_config.dart:44-52`

**Scenario: Valid size parsed correctly**
- Given a map with `'widgetSize': 'twoByOne'`
- When `WidgetConfig.fromMap(map)` is called
- Then `size == WidgetSize.twoByOne`
- Reference: `lib/models/widget_config.dart:44-52`

### R4: Default WidgetSize

The default size when constructing a WidgetConfig is `fourByOne`.

**Scenario: Default construction**
- Given `WidgetConfig(clockConfig: ClockConfig())`
- Then `size == WidgetSize.fourByOne`
- Reference: `lib/models/widget_config.dart:33`
