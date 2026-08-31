# Editor Screen

## Purpose

Full customization screen where the user modifies every aspect of the clock display and background. Changes are reflected immediately in a live preview. Config is saved to SharedPreferences on explicit Save action. Also supports "create new design" flow when `storage` is null.

## Requirements

### R1: Live preview at top

A `ClockPreview` widget renders the current config at the top of the scrollable area, updating instantly on every change. Now includes `background` parameter for background rendering.

**Scenario: Preview updates on color change**
- Given user taps a new color swatch
- When `_updateConfig` is called
- Then ClockPreview immediately re-renders with the new color
- Reference: `lib/screens/editor_screen.dart:107-109`

**Scenario: Preview shows background image**
- Given user picked an image from gallery
- When preview renders
- Then `ClockPreview(config: _config, background: _background)` shows image behind text
- Reference: `lib/screens/editor_screen.dart:219`

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

Note: "Show seconds" toggle was removed in plan3_final.md Task A — seconds are no longer supported.

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

Tapping Save writes config to StorageService (if `storage != null`), then calls `WidgetBridge.updateWidgets()`. Returns the saved ClockConfig to the caller via `Navigator.pop`.

**Scenario: Save and return (global config flow)**
- Given `widget.storage != null`
- When user taps "Save"
- Then `storage.saveConfig(config)` is awaited
- And `WidgetBridge.updateWidgets()` is called
- And `Navigator.pop(config)` returns the updated config
- Reference: `lib/screens/editor_screen.dart:97-115`

**Scenario: Save and return (create design flow)**
- Given `widget.storage == null`
- When user taps "Save"
- Then `Navigator.pop(EditorScreenResult(config, background))` is called
- And no config is saved to SharedPreferences
- Reference: `lib/screens/editor_screen.dart:110-115`

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

### R11: Background section (plan5 §4)

A Background section appears at the top of the editor, below the preview, with 4 type options: None / Solid / Gradient / Image.

**Scenario: Select solid background**
- Given current background type is `none`
- When user taps "Solid" chip
- Then `_background.type` becomes `BackgroundType.solid`
- And a solid color picker appears below
- Reference: `lib/screens/editor_screen.dart:224-232`

**Scenario: Select image background**
- Given user taps "Image" chip
- Then `_pickImage()` is called (gallery picker opens)
- After crop, background type becomes `BackgroundType.image` with smart defaults
- Reference: `lib/screens/editor_screen.dart:226-228`

### R12: Image pick + crop pipeline (plan5 §4)

When user selects Image background, the pipeline runs:
1. `image_picker` opens gallery (max 2400x2400)
2. Source image copied to app documents, resized to max 1600px via `ImageUtils.copyAndResizeSource()`
3. `CropScreen` opens for zoom+pan
4. Smart defaults applied: dark overlay 35%, text shadow on, blur off, autoTextContrast on

**Scenario: Pick and crop image**
- Given user taps "Image" background type
- When gallery picker returns an image
- Then source is saved to `designs/{uuid}.jpg` (resized max 1600px)
- And CropScreen opens
- When user confirms crop
- Then `_background` is set with `type: image`, `overlayOpacity: 0.35`, `overlayMode: dark`, `textShadow: true`
- Reference: `lib/screens/editor_screen.dart:260-298`

### R13: Image adjustment controls

When background type is `image`, additional controls appear:
- Overlay mode: None / Dark / Light (ChoiceChips)
- Overlay opacity: Slider 0–70%
- Blur sigma: Slider 0–20
- Auto text contrast: Toggle
- Text shadow: Toggle

**Scenario: Adjust overlay opacity**
- Given background type is `image` with `overlayOpacity: 0.35`
- When user drags overlay slider to 0.5
- Then `_background.overlayOpacity` becomes `0.5`
- And preview updates immediately
- Reference: `lib/screens/editor_screen.dart:242-260`

### R14: Solid color picker for background

When background type is `solid`, a color picker appears using the same swatch grid as text color.

**Scenario: Pick solid background color**
- Given background type is `solid`
- When user taps a color swatch
- Then `_background.solidColor` is updated
- And preview shows the new solid color background
- Reference: `lib/screens/editor_screen.dart:300-308`

### R15: Gradient color picker

When background type is `gradient`, a gradient picker with 2 color slots (Start/End) and a preview bar appears.

**Scenario: Pick gradient colors**
- Given background type is `gradient`
- When user taps "Start" color circle
- Then a color dialog opens
- When user selects a color
- Then `gradientColors[0]` is updated
- And gradient preview bar updates
- Reference: `lib/screens/editor_screen.dart:312-320`

### R16: Remove image background

When background type is `image`, a "Remove" chip appears next to the type selector. Tapping it resets background to `BackgroundConfig.none()`.

**Scenario: Remove image**
- Given background type is `image`
- When user taps "Remove" chip
- Then `_background` resets to `BackgroundConfig()`
- And image adjustment controls disappear
- Reference: `lib/screens/editor_screen.dart:233-236`

### R17: Create design flow (storage=null)

When `storage` is null (called from MyDesignsScreen for creating new design), Save returns `EditorScreenResult` instead of saving to global SharedPreferences.

**Scenario: Create new design**
- Given `widget.storage == null`
- When user taps "Save"
- Then `Navigator.pop(EditorScreenResult(config: _config, background: _background))` is called
- And no config is written to SharedPreferences
- Reference: `lib/screens/editor_screen.dart:110-115`

## Need to clear

1. **`_savedConfig` is declared with `late` after `initState` uses it** — Dart allows this but the declaration order is reversed from typical style. Code compiles and works correctly.
2. **Image file UUID in editor** — When picking an image, a UUID is generated in `_pickImage()`. If user cancels crop, the source file remains on disk (minor leak). Could be cleaned up on editor dispose.
