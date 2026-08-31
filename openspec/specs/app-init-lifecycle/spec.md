# App Init & Lifecycle

## Purpose

`main.dart` orchestrates app initialization (Storage, RewardService, Ads, IAP), lifecycle management via WidgetsBindingObserver, deep link handling, and Material3 theming.

## Requirements

### R1: Initialization order

`main()` runs:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `StorageService.create()` — async, loads SharedPreferences
3. `SharedPreferences.getInstance()` — for RewardService
4. `RewardService(prefs)` — creates reward service instance
5. `rewardService.resetIfNewDay()` — async, resets daily unlocks if new day
6. `AdsService.init()` — async, initializes MobileAds
7. `AdsService(storage, rewardService)` — creates service instance with reward dependency
8. `IapService(storage)` — creates service instance
9. `IapService.init()` — async, listens to purchase stream + queries products
10. `runApp(DateWidgetApp(...))`

**Scenario: Init completes**
- When `main()` runs
- Then all 4 services (Storage, Reward, Ads, IAP) are initialized before `runApp`
- Reference: `lib/main.dart:7-25`

### R2: WidgetsBindingObserver

`_DateWidgetAppState` mixes in `WidgetsBindingObserver` to detect `AppLifecycleState.detached` and dispose services.

**Scenario: App detached**
- Given the app is being killed by the OS
- When `didChangeAppLifecycleState(detached)` fires
- Then `iapService.dispose()` and `adsService.dispose()` are called
- Reference: `lib/main.dart:48-50`

### R3: Deep link handler

Listens to `com.example.date_time_widget/deep_link` MethodChannel. On `'openEditor'`, waits 500ms then calls `_homeKey.currentState?.openEditorFromDeepLink()`.

**Scenario: Deep link received**
- Given the app is running on HomeScreen
- When MethodChannel receives `'openEditor'`
- Then after 500ms delay, `openEditorFromDeepLink()` is called
- Reference: `lib/main.dart:52-56`

### R4: Material3 theming

App uses `ThemeData` with `ColorScheme.fromSeed(seedColor: Color(0xFF1A73E8))`, `useMaterial3: true`. Supports both light and dark themes via `ThemeMode.system`.

**Scenario: System dark mode**
- Given device is in dark mode
- When the app renders
- Then `darkTheme` is used with `brightness: Brightness.dark`
- Reference: `lib/main.dart:62-74`

### R5: dispose cleans up

`dispose()` removes the WidgetsBindingObserver and disposes IAP and Ads services.

**Scenario: Widget disposed**
- When `_DateWidgetAppState.dispose()` runs
- Then `removeObserver`, `iapService.dispose()`, `adsService.dispose()` are called in order
- Reference: `lib/main.dart:36-40`
