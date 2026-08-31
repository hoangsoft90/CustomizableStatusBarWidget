# Editor Screen

## Purpose

Full customization screen where the user modifies every aspect of the clock display. Changes are reflected immediately in a live preview. Config is saved to SharedPreferences on explicit Save action.

## Requirements

### R1: Live preview at top

A `ClockPreview` widget renders the current config at the top of the scrollable area, updating instantly on every change.

**Scenario: Preview updates on color change**
- Given user taps a new color swatch
- When `_update` is called
- Then ClockPreview immediately re-renders with the new color
- Reference: `lib/screens/editor_screen.dart:107-109`

### R2: Date format selection

9 predefined format options displayed as ChoiceChip grid:

```
EEE dd MMM, dd/MM/yyyy, MM/dd/yyyy, yyyy-MM-dd,
EEEE dd MMMM, EEEE MMMM d, dd MMM yyyy, MMM d, d MMMM
```

**Scenario: Format selection**
- Given current format is `'EEE dd MMM'`
- When user taps `'dd/MM/yyyy'`
- Then `_config.format` becomes `'dd/MM/yyyy'`
- Reference: `lib/screens/editor_screen.dart:6-16`, `111-115`

### R3: Time format toggle

Two options: `'HH:mm'` (24h) and `'hh:mm a'` (12h), displayed as ChoiceChips.

**Scenario: Switch to 12h**
- Given current `timeFormat = 'HH:mm'`
- When user taps "12 h"
- Then `timeFormat` becomes `'hh:mm a'`
- Reference: `lib/screens/editor_screen.dart:117-130`

### R4: Display toggles

Two Switch rows:
- "Show day of week" → `showDay`
- "Show date" → `showDate`

Note: "Show seconds" toggle was removed in plan3_final.md Task A — seconds are no longer supported (caused double-seconds bug on Android native).

**Scenario: Toggle day**
- Given `showDay = false`
- When user toggles "Show day of week" on
- Then `showDay = true`
- Reference: `lib/screens/editor_screen.dart:132-143`

### R5: Font size slider

Slider range: 14–48, 34 divisions. Current value displayed numerically.

**Scenario: Slider updates fontSize**
- Given `fontSize = 32`
- When user drags slider to 40
- Then `fontSize = 40.0`
- Reference: `lib/screens/editor_screen.dart:148-163`

### R6: Color picker

12 predefined color swatches in a Wrap grid. Selected swatch has a colored border.

**Scenario: Color selection**
- Given current color is `'#FFFFFF'`
- When user taps the blue swatch (`#2196F3`)
- Then `color` becomes `'#2196F3'`
- Reference: `lib/screens/editor_screen.dart:23-35`, `166-169`

### R7: Alignment selector

Three icon buttons: left, center, right. Selected button has primary color highlight.

**Scenario: Alignment change**
- Given `alignment = 'center'`
- When user taps the left-align icon
- Then `alignment = 'left'`
- Reference: `lib/screens/editor_screen.dart:172-186`

### R8: Save persists and syncs

Tapping Save writes config to StorageService, then calls `WidgetBridge.updateWidgets()`. Returns the saved ClockConfig to the caller via `Navigator.pop`.

**Scenario: Save and return**
- Given user modified `fontSize` to 40
- When user taps "Save"
- Then `storage.saveConfig(config)` is awaited
- And `WidgetBridge.updateWidgets()` is called
- And `Navigator.pop(config)` returns the updated config
- And a SnackBar "Config saved" is shown
- Reference: `lib/screens/editor_screen.dart:97-105`

### R9: Back with unsaved changes shows dialog

If the user modified any field since last save (or since opening the editor), pressing back shows "Discard changes?" dialog with "Keep editing" and "Discard" options.

**Scenario: Discard changes**
- Given user changed `fontSize` but did not save
- When user presses back
- Then a dialog "Discard changes?" appears
- When user taps "Discard"
- Then `Navigator.pop(_savedConfig)` returns the original config
- Reference: `lib/screens/editor_screen.dart:81-95`

**Scenario: No changes — direct pop**
- Given user opened editor but changed nothing
- When user presses back
- Then `Navigator.pop(_config)` is called immediately (no dialog)
- Reference: `lib/screens/editor_screen.dart:82-85`

### R10: Banner placement at bottom

No banner is placed in the Editor screen (per plan §3 — banner must not cover preview). The body is a single `Column` with `Expanded(ListView(...))` and no `AdBanner` child.

**Scenario: No AdBanner in editor tree**
- When EditorScreen renders
- Then there is no `AdBanner` widget in the widget tree
- Reference: `lib/screens/editor_screen.dart:107` (body Column contains only Expanded ListView)

## Need to clear

1. **`_savedConfig` is declared with `late` after `initState` uses it** — Dart allows this but the declaration order is reversed from typical style. Code compiles and works correctly.
