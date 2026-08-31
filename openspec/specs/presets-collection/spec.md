# Built-in Presets Collection

## Purpose

Hard-coded list of 8 visual presets (6 free, 2 locked) available for quick-selection in the Presets screen. No dynamic loading, no user-created presets.

## Requirements

### R1: Exactly 8 presets

The `builtInPresets` constant list contains exactly 8 Preset entries.

**Scenario: Count**
- Given the `builtInPresets` list from `lib/models/presets.dart`
- Then `builtInPresets.length == 8`
- Reference: `lib/models/presets.dart:6-88`

### R2: 6 free presets

Six presets have `isLocked: false`.

| id | name | color | timeFormat | notable |
|----|------|-------|------------|---------|
| basic1 | Classic White | #FFFFFF | HH:mm | default |
| basic2 | Modern Black | #000000 | HH:mm | left aligned |
| basic3 | Digital Blue | #2196F3 | HH:mm | 30px font |
| basic4 | Warm Gold | #FFC107 | hh:mm a | 12h format |
| basic5 | Compact | #9E9E9E | HH:mm | fontSize 20 |
| basic6 | Date Only | #FFFFFF | HH:mm | no time shown explicitly |

Note: basic3 previously had `HH:mm:ss` with `showSeconds: true` — changed to `HH:mm` in plan3_final.md Task A (seconds removed due to Android native bug).

**Scenario: Free presets are not locked**
- Given `builtInPresets.where((p) => !p.isLocked)`
- Then the count is 6
- And all have `isLocked: false`
- Reference: `lib/models/presets.dart:8-68`

### R3: 2 locked presets

Two presets have `isLocked: true` and require rewarded ad or premium.

| id | name | color | timeFormat | notable |
|----|------|-------|------------|---------|
| premium1 | Sunset Gradient | #FF5722 | HH:mm | 34px font |
| premium2 | Neon Green | #00E676 | HH:mm | 30px font |

Note: premium2 previously had `HH:mm:ss` with `showSeconds: true` — changed to `HH:mm` in plan3_final.md Task A.

**Scenario: Locked presets require ad or premium**
- Given `builtInPresets.where((p) => p.isLocked)`
- Then the count is 2
- And their IDs are `'premium1'` and `'premium2'`
- Reference: `lib/models/presets.dart:72-87`

### R4: All presets have valid ClockConfig

Every preset's `config` field is a valid ClockConfig with non-empty `format` and `timeFormat`.

**Scenario: No empty format**
- Given every preset in `builtInPresets`
- Then `preset.config.format.isNotEmpty` is `true`
- And `preset.config.timeFormat.isNotEmpty` is `true`
- Reference: `lib/models/presets.dart:8-87`

## Need to clear

1. **basic6 has `showDate: true` and `showDay: true` but its format `'EEEE, dd MMMM yyyy'` already includes both day and date tokens** — the DateFormatter will render this as a single mixed line. The preset's `showDay` flag has no separate effect when the format string contains `EEEE`.
