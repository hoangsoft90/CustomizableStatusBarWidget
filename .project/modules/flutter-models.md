# Flutter Models

## ClockConfig (`lib/models/clock_config.dart`)

Immutable 10-field model. Core of the entire app.

```dart
const ClockConfig({
  format: 'EEE dd MMM',
  timeFormat: 'HH:mm',        // Only HH:mm or hh:mm a (no seconds)
  showDate: true,
  showDay: true,
  fontSize: 32,
  color: '#FFFFFF',
  alignment: 'center',         // 'left', 'center', 'right'
  notificationEnabled: false,
  floatingBarEnabled: false,
  isPremium: false,
})
```

**Key methods:**
- `normalizeTimeFormat(String)` — strips `:ss` from legacy JSON
- `toJson()` / `fromJson()` / `toJsonString()` / `fromJsonString()`
- `copyWith()` — selective field override
- `==` / `hashCode` — value equality (10 fields)

**Legacy fields removed:**
- `showSeconds` — ignored in fromJson, normalized in timeFormat
- `unlockedPresets` — ignored in fromJson, replaced by RewardState

## Preset (`lib/models/preset.dart`)

```dart
const Preset({
  required String id,
  required String name,
  required String description,
  required ClockConfig config,
  bool isLocked = false,
})
```

**Equality:** Only `id` is compared (not `name`, `description`, `config`).

## Presets Collection (`lib/models/presets.dart`)

8 built-in presets (6 free, 2 locked):

| ID | Name | timeFormat | Color | Notes |
|----|------|-----------|-------|-------|
| basic1 | Classic White | HH:mm | #FFFFFF | Default |
| basic2 | Modern Black | HH:mm | #000000 | Left aligned |
| basic3 | Digital Blue | HH:mm | #2196F3 | 30px |
| basic4 | Warm Gold | hh:mm a | #FFC107 | 12h |
| basic5 | Compact | HH:mm | #9E9E9E | 20px |
| basic6 | Date Only | HH:mm | #FFFFFF | No time shown |
| premium1 | Sunset Gradient | HH:mm | #FF5722 | Locked |
| premium2 | Neon Green | HH:mm | #00E676 | Locked |

## RewardState (`lib/models/reward_state.dart`)

Daily reward tracking, separate from ClockConfig.

```dart
RewardState({
  required String date,        // 'yyyy-MM-dd'
  int unlockCount = 0,         // max 2
  List<String> unlockedToday = const [],
})
```

Persisted in SharedPreferences key `"reward_state"`.

## WidgetConfig (`lib/models/widget_config.dart`)

Maps ClockConfig + WidgetSize enum to Android widget cell dimensions.

| Size | Cells |
|------|-------|
| 2x1 | 180dp × 110dp |
| 3x1 | 250dp × 110dp |
| 4x1 | 320dp × 110dp |
| 4x2 | 320dp × 220dp |
