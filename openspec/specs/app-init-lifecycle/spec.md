# App Init & Lifecycle

## Purpose

`main.dart` orchestrates app initialization (Storage, RewardService, Ads, IAP), lifecycle management via WidgetsBindingObserver, deep link handling, and Material3 theming.

## Requirements

### R1: Initialization order

`main()` runs:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `StorageService.create()` — async, loads SharedPreferences
3. `SharedPreferences.getInstance()` — for RewardService
4. `DesignStorageService.create()` — async, loads designs list from SharedPreferences
5. `RewardService(prefs)` — creates reward service instance
6. `rewardService.resetIfNewDay()` — async, resets daily unlocks if new day
7. `AdsService.init()` — async, initializes MobileAds
8. `AdsService(storage, rewardService)` — creates service instance with reward dependency
9. `IapService(storage)` — creates service instance
10. `IapService.init()` — async, listens to purchase stream + queries products
11. `runApp(DateWidgetApp(...))`

**Scenario: Init completes**
- When `main()` runs
- Then all 5 services (Storage, DesignStorage, Reward, Ads, IAP) are initialized before `runApp`
- Reference: `lib/main.dart:7-27`

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

### R6: DateWidgetApp accepts designStorage

`DateWidgetApp` constructor now includes `designStorage` parameter, passed to `HomeScreen`.

**Scenario: DesignStorageService passed to HomeScreen**
- Given `DateWidgetApp(designStorage: designStorage, ...)` is created
- When `HomeScreen` is constructed
- Then `designStorage: widget.designStorage` is passed
- Reference: `lib/main.dart:88-94`

### R5: dispose cleans up

`dispose()` removes the WidgetsBindingObserver and disposes IAP and Ads services.

**Scenario: Widget disposed**
- When `_DateWidgetAppState.dispose()` runs
- Then `removeObserver`, `iapService.dispose()`, `adsService.dispose()` are called in order
- Reference: `lib/main.dart:36-40`
