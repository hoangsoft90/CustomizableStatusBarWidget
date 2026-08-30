# Presets Screen

## Purpose

Displays all 8 built-in presets in a 2-column grid. User taps a preset to select it (applies the config). Locked presets trigger the rewarded ad unlock flow.

## Requirements

### R1: Grid layout

2-column GridView with 12px spacing, `childAspectRatio: 0.85`.

**Scenario: Grid structure**
- Given PresetsScreen is rendered
- Then `GridView.builder` uses `crossAxisCount: 2`
- And `mainAxisSpacing: 12`, `crossAxisSpacing: 12`
- Reference: `lib/screens/presets_screen.dart:38-43`

### R2: Preset selection

Tapping an unlocked preset selects it, calls `WidgetBridge.updateWidgets()`, and pops the screen returning the preset's ClockConfig.

**Scenario: Select free preset**
- Given user taps "Classic White" (basic1, unlocked)
- Then `_selectedId` is set to `'basic1'`
- And `WidgetBridge.updateWidgets()` is called
- And `Navigator.pop(preset.config)` returns the config
- Reference: `lib/screens/presets_screen.dart:45-49`

### R3: Locked preset unlock flow

Tapping a locked preset calls `adsService.unlockPreset()` which shows the "Watch a short ad to unlock" dialog. If the user watches the ad and earns the reward, the preset is permanently unlocked.

**Scenario: Unlock via rewarded ad**
- Given user taps "Sunset Gradient" (premium1, locked)
- And user is not premium
- When `unlockPreset` returns `true`
- Then config is reloaded from storage with the new preset in `unlockedPresets`
- And a SnackBar '"Sunset Gradient" unlocked!' is shown
- Reference: `lib/screens/presets_screen.dart:51-63`

### R4: Initial selection matching

On screen open, the current config is compared against all presets to pre-select the matching one.

**Scenario: Pre-select matching preset**
- Given current config matches `basic3`'s config exactly
- When PresetsScreen initializes
- Then `_selectedId == 'basic3'`
- Reference: `lib/screens/presets_screen.dart:26-31`

### R5: isPremium bypasses lock check

If `currentConfig.isPremium == true`, all presets are treated as unlocked regardless of individual `isLocked` flags.

**Scenario: Premium user sees all unlocked**
- Given `currentConfig.isPremium = true`
- When checking if preset `premium1` is accessible
- Then `isUnlocked == true`
- Reference: `lib/screens/presets_screen.dart:68-70`

### R6: PresetCard rendering

Each preset is rendered as a `PresetCard` widget showing a mini live preview and a label bar with name, lock icon, and check icon.

**Scenario: Locked preset shows lock icon**
- Given a preset with `isLocked: true` and not in `unlockedPresets`
- When `PresetCard` renders
- Then a lock icon is visible
- Reference: `lib/widgets/preset_card.dart:48-50`
