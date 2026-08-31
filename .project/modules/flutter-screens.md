# Flutter Screens

## HomeScreen (`lib/screens/home_screen.dart`)

Entry point. Live preview + grouped action buttons.

**Constructor params:** `storage`, `adsService`, `iapService`, `rewardService`

**Sections (in order):**
1. **STATUS BAR** — Enable/Disable Notification
2. **HOME SCREEN** — Add Widget (shows dialog instructions)
3. **CUSTOMIZE** — Customize (→ EditorScreen), Presets (→ PresetsScreen)
4. **FLOATING BAR** — Enable/Disable Floating Bar
5. **Settings** — (→ SettingsScreen)

**Deep link:** `openEditorFromDeepLink()` called via MethodChannel when widget tapped.

**Config sync:** After returning from Editor/Presets, updates all 3 native services.

**Banner:** `AdBanner` at bottom, hidden when premium.

## EditorScreen (`lib/screens/editor_screen.dart`)

Full customization with live preview.

**Controls:**
- Date format: 9 ChoiceChip options
- Time format: 24h / 12h toggle
- Display: Show day, Show date (2 toggles)
- Font size: Slider 14-48
- Color: 12 swatches
- Alignment: left/center/right icons

**Layout:** Preview at top, controls below. No banner in editor (plan §3).

**Save:** Writes to StorageService, calls `WidgetBridge.updateWidgets()`, pops with config.

**Back:** Shows "Discard changes?" dialog if modified.

## PresetsScreen (`lib/screens/presets_screen.dart`)

Grid of 8 presets (2 columns).

**Constructor params:** `currentConfig`, `adsService`, `storage`, `rewardService`

**Behavior:**
- Tapping free/unlocked preset → selects + pops
- Tapping locked preset → `adsService.unlockPreset()` with daily reward flow
- Initial selection matches current config against presets
- Calls `rewardService.resetIfNewDay()` on open

## SettingsScreen (`lib/screens/settings_screen.dart`)

IAP section + About + Banner ad.

**Features:**
- Buy "Remove Ads & Unlock All" button
- Restore purchase button
- About card with app info
- Timer refreshes config from SharedPreferences
