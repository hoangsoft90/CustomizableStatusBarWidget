# Presets Screen

## Purpose

Displays all 8 built-in presets in a 2-column grid. User taps a preset to select it (applies the config). Locked presets trigger the rewarded ad unlock flow via RewardService (daily unlock, max 2/day).

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

### R3: Locked preset unlock flow (daily reward)

Tapping a locked preset calls `adsService.unlockPreset()` which shows the "Watch a short ad to use this preset today?" dialog. If the user watches the ad and earns the reward, `rewardService.unlockToday(presetId)` is called. The preset is usable for the rest of today only.

Note: In plan3_final.md Task B, this changed from permanent unlock to daily unlock.

**Scenario: Unlock via rewarded ad**
- Given user taps "Sunset Gradient" (premium1, locked)
- And user is not premium
- And `remainingUnlocksToday() > 0`
- When `unlockPreset` returns `true`
- Then config is reloaded from storage
- And a SnackBar '"Sunset Gradient" unlocked for today!' is shown
- Reference: `lib/screens/presets_screen.dart:51-63`

### R4: Initial selection matching

On screen open, the current config is compared against all presets to pre-select the matching one. Also calls `rewardService.resetIfNewDay()` to reset daily unlocks if needed.

**Scenario: Pre-select matching preset**
- Given current config matches `basic3`'s config exactly
- When PresetsScreen initializes
- Then `_selectedId == 'basic3'`
- Reference: `lib/screens/presets_screen.dart:26-31`

**Scenario: Daily reset on screen open**
- When PresetsScreen initializes
- Then `rewardService.resetIfNewDay()` is called
- Reference: `lib/screens/presets_screen.dart:28`

### R5: Premium and free preset bypass

If `currentConfig.isPremium == true` OR the preset is free (`!preset.isLocked`), all presets are treated as accessible regardless of `RewardService` state.

**Scenario: Premium user sees all unlocked**
- Given `currentConfig.isPremium = true`
- When checking if preset `premium1` is accessible
- Then `isUsable == true`
- Reference: `lib/screens/presets_screen.dart:77-82`

**Scenario: Free preset always accessible**
- Given a preset with `isLocked: false`
- When checking accessibility
- Then `isUsable == true` regardless of reward state
- Reference: `lib/screens/presets_screen.dart:77-82`

### R6: PresetCard rendering

Each preset is rendered as a `PresetCard` widget showing a mini live preview and a label bar with name, lock icon, and check icon.

**Scenario: Locked preset shows lock icon**
- Given a preset with `isLocked: true` and not accessible via RewardService
- When `PresetCard` renders
- Then a lock icon is visible
- Reference: `lib/widgets/preset_card.dart:48-50`

### R7: Constructor accepts rewardService

PresetsScreen accepts an optional `RewardService` parameter. If null, falls back to basic `isFreePreset || isPremium` logic.

**Scenario: With RewardService**
- Given `rewardService` is provided
- When checking preset accessibility
- Then `rewardService.canUsePreset()` is used
- Reference: `lib/screens/presets_screen.dart:16`

**Scenario: Without RewardService (fallback)**
- Given `rewardService` is null
- When checking preset accessibility
- Then fallback: `isFreePreset || currentConfig.isPremium`
- Reference: `lib/screens/presets_screen.dart:79-81`
