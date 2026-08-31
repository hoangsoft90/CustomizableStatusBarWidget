# Home Screen

## Purpose

Entry point screen after app launch. Displays a live clock preview and provides access to all features via grouped action buttons. Supports deep link from home-screen widget tap.

## Requirements

### R1: Live preview at top

A `ClockPreview` widget is displayed at the top of the screen, rendering the current time/date/day from the loaded ClockConfig.

**Scenario: Preview shows current config**
- Given a saved config with `fontSize: 40`, `color: '#FF0000'`
- When HomeScreen loads
- Then ClockPreview renders with `fontSize: 40` and red text
- Reference: `lib/screens/home_screen.dart:103`

### R2: Action buttons grouped by section

Buttons are organized under 4 section headers in order:
1. **STATUS BAR** — "Enable/Disable Notification"
2. **HOME SCREEN** — "Add Widget"
3. **CUSTOMIZE** — "Customize", "Presets"
4. **FLOATING BAR** — "Enable/Disable Floating Bar"
5. **Settings** (no section header)

**Scenario: Section order**
- Given HomeScreen is rendered
- When user scrolls through the ListView
- Then section headers appear in the order: STATUS BAR, HOME SCREEN, CUSTOMIZE, FLOATING BAR
- Reference: `lib/screens/home_screen.dart:108-168`

### R3: Notification toggle

Tapping "Enable Notification" triggers the full permission flow (explanation dialog → POST_NOTIFICATIONS request → start native service). Tapping "Disable Notification" stops the service. Button label and icon change based on state.

**Scenario: Enable notification**
- Given notification is currently disabled
- When user taps "Enable Notification"
- Then `_notifService.enable(context)` is called
- And on success, button text changes to "Disable Notification"
- And a SnackBar "Notification icon enabled" is shown
- Reference: `lib/screens/home_screen.dart:128-140`

**Scenario: Disable notification**
- Given notification is currently enabled
- When user taps "Disable Notification"
- Then `_notifService.disable()` is called
- And a SnackBar "Notification icon disabled" is shown
- Reference: `lib/screens/home_screen.dart:130-136`

### R4: Add Widget shows dialog

Tapping "Add Widget" shows an AlertDialog instructing the user to long-press home screen → Widgets → find "Date & Time Widget". Does NOT open the widget picker programmatically.

**Scenario: Add Widget dialog**
- When user taps "Add Widget"
- Then a dialog appears with instructions
- Reference: `lib/screens/home_screen.dart:142-155`

### R5: Floating bar toggle with permission check

Tapping "Enable Floating Bar" shows an explanation dialog first ("This does NOT modify your phone's status bar"), then checks `SYSTEM_ALERT_WINDOW` permission. If not granted, opens system settings. If granted, starts the foreground service.

**Scenario: First enable — permission not granted**
- Given overlay permission is not granted
- When user taps "Enable Floating Bar" and confirms
- Then system "Display over other apps" settings is opened
- And a SnackBar instructs to grant permission and tap again
- Reference: `lib/screens/home_screen.dart:158-198`

**Scenario: Enable with permission**
- Given overlay permission is granted
- When user taps "Enable Floating Bar" and confirms
- Then `FloatingBarBridge.start()` is called
- And config is updated with `floatingBarEnabled: true`
- Reference: `lib/screens/home_screen.dart:185-194`

### R6: Deep link from widget

`openEditorFromDeepLink()` is a public method on `HomeScreenState` called via MethodChannel when the user taps the home-screen widget. It opens the Editor screen.

**Scenario: Widget tap triggers editor**
- Given the app is running on HomeScreen
- When a deep link with `open_editor=true` is received
- Then `_openEditor()` is called automatically
- Reference: `lib/screens/home_screen.dart:64`

### R7: Config sync after editor/presets

After returning from EditorScreen or PresetsScreen with an updated ClockConfig, HomeScreen updates all three display layers.

**Scenario: Config update propagates**
- Given user saves new config in Editor
- When HomeScreen receives the updated ClockConfig
- Then `WidgetBridge.updateWidgets(configJson)` is called
- And `_notifService.update()` is called
- And `FloatingBarBridge.update(configJson)` is called
- Reference: `lib/screens/home_screen.dart:70-77`

### R8: Banner ad at bottom

An `AdBanner` widget is placed at the very bottom of the screen, below the ListView, visible only when not premium.

**Scenario: Banner visible for free users**
- Given `adsService.showBanners == true`
- When HomeScreen renders
- Then `AdBanner(show: true)` is in the widget tree
- Reference: `lib/screens/home_screen.dart:171`

### R9: Constructor accepts rewardService

HomeScreen accepts a `RewardService` parameter and passes it to PresetsScreen.

**Scenario: RewardService passed to PresetsScreen**
- Given HomeScreen is rendered with `rewardService`
- When user opens Presets screen
- Then `PresetsScreen(rewardService: widget.rewardService)` is constructed
- Reference: `lib/screens/home_screen.dart:76-80`
