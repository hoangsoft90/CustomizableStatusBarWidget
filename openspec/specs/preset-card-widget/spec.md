# PresetCard Widget

## Purpose

Card displaying a Preset with a mini live ClockPreview and a label bar showing name, lock icon, and check icon. Used in the Presets screen grid.

## Requirements

### R1: Mini preview

The top portion of the card contains a `ClockPreview` widget rendered inside a `ClipRRect` with rounded top corners.

**Scenario: Preview renders preset config**
- Given a PresetCard with `preset.config.fontSize: 28`
- When the card builds
- Then the embedded ClockPreview uses `preset.config` (fontSize 28)
- Reference: `lib/widgets/preset_card.dart:30-33`

### R2: Label bar

Bottom section shows: preset name (max 1 line, ellipsis overflow), optional lock icon, optional check icon.

**Scenario: Free unlocked preset**
- Given `preset.isLocked: false` and `isSelected: false`
- When the card renders
- Then name is visible, no lock icon, no check icon
- Reference: `lib/widgets/preset_card.dart:36-51`

**Scenario: Locked preset**
- Given `preset.isLocked: true`
- When the card renders
- Then a lock icon (`Icons.lock`, size 12) is visible
- Reference: `lib/widgets/preset_card.dart:48-50`

**Scenario: Selected preset**
- Given `isSelected: true`
- When the card renders
- Then a check icon (`Icons.check_circle`) is visible with primary color
- Reference: `lib/widgets/preset_card.dart:51-53`

### R3: Selection border animation

When `isSelected` is true, the card has a 2.5px primary-color border. Transition uses `AnimatedContainer` with 200ms duration.

**Scenario: Selected state**
- Given `isSelected: true`
- When the card builds
- Then `border: Border.all(color: primaryColor, width: 2.5)`
- Reference: `lib/widgets/preset_card.dart:18-24`

**Scenario: Unselected state**
- Given `isSelected: false`
- When the card builds
- Then `borderColor: Colors.transparent`
- Reference: `lib/widgets/preset_card.dart:20-21`

### R4: Tap triggers callback

The entire card is wrapped in a `GestureDetector` calling `onTap`.

**Scenario: Tap fires callback**
- When user taps the card
- Then `onTap()` is invoked
- Reference: `lib/widgets/preset_card.dart:15`
