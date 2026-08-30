# Settings Screen

## Purpose

Displays IAP purchase options (Remove Ads & Unlock All), restore purchase, and app info. Banner ad at the bottom. Periodically refreshes config to reflect background IAP completions.

## Requirements

### R1: Premium section

Shows a Card with purchase status. If not premium: "Remove Ads & Unlock All" title, benefit list, Buy button with price, Restore button. If premium: "Premium Active" with thank-you message.

**Scenario: Not premium**
- Given `_config.isPremium == false`
- When SettingsScreen renders
- Then the Card shows "Remove Ads & Unlock All"
- And a FilledButton with product price (or "Buy Premium" if product not loaded)
- And a TextButton "Restore Purchase"
- Reference: `lib/screens/settings_screen.dart:88-130`

**Scenario: Already premium**
- Given `_config.isPremium == true`
- When SettingsScreen renders
- Then the Card shows "Premium Active" with a thank-you message
- And no Buy/Restore buttons are visible
- Reference: `lib/screens/settings_screen.dart:114-118`

### R2: Buy flow

Tapping Buy shows a loading dialog, calls `iapService.buy()`, then updates state on success.

**Scenario: Successful purchase**
- Given user taps Buy
- When `iapService.buy()` returns `true`
- Then `_config` is refreshed from storage (now `isPremium: true`)
- And a SnackBar "Premium activated! All ads removed." is shown
- Reference: `lib/screens/settings_screen.dart:57-72`

### R3: Restore flow

Tapping Restore calls `iapService.restore()`. Shows success or "no previous purchase" SnackBar.

**Scenario: Restore found**
- Given a previous purchase exists
- When user taps "Restore Purchase"
- Then config is refreshed and SnackBar "Purchase restored successfully." is shown
- Reference: `lib/screens/settings_screen.dart:74-83`

### R4: Periodic config refresh

A `Timer.periodic(2s)` reloads config from SharedPreferences to detect IAP completions that happen while this screen is open.

**Scenario: Background IAP update**
- Given user is on Settings screen
- When IAP purchase completes in background (stream handler sets isPremium)
- Then within 2 seconds, `_config` refreshes and UI updates to show "Premium Active"
- Reference: `lib/screens/settings_screen.dart:33-39`

### R5: Banner ad at bottom

`AdBanner` is placed at the very bottom, below the content area, visible only when not premium.

**Scenario: Banner hidden for premium**
- Given `_config.isPremium == true`
- Then `AdBanner(show: false)` renders nothing
- Reference: `lib/screens/settings_screen.dart:135`

### R6: About card

A simple ListTile showing "About" with subtitle "Date & Time Widget v1.0.0".

**Scenario: About visible**
- When SettingsScreen renders
- Then an "About" ListTile is present in the ListView
- Reference: `lib/screens/settings_screen.dart:133-137`
