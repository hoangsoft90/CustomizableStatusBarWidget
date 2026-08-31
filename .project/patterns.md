# Patterns & Conventions

## Coding Conventions

### Flutter (Dart)

| Pattern | Convention |
|---------|-----------|
| **State management** | `setState` in StatefulWidget (no Riverpod/Bloc) |
| **Dependency injection** | Constructor injection, passed from `main.dart` |
| **Config persistence** | `StorageService` wrapping `SharedPreferences` |
| **JSON serialization** | Manual `toJson()`/`fromJson()` (no code generation) |
| **Naming** | `snake_case` files, `camelCase` variables, `PascalCase` classes |
| **File structure** | Feature-first: `models/`, `screens/`, `widgets/`, `services/`, `utils/` |
| **Test naming** | `test/<feature>_test.dart`, 91 tests total |

### Native Android (Kotlin)

| Pattern | Convention |
|---------|-----------|
| **Config reading** | Each native file has own `ClockData` + `parseClockData()` (JSON regex) |
| **Config storage** | `"status_bar_config"` SharedPreferences (written by Flutter via MethodChannel) |
| **Service communication** | Static methods on companion objects |
| **Update mechanism** | Intent-based (`UPDATE_OVERLAY` action) for in-place updates |
| **Error handling** | `try-catch` with fallback to defaults (never crash) |

## Key Patterns

### 1. JSON Config Pass-Through

Flutter serializes `ClockConfig` → JSON string → MethodChannel → Native parses with regex.

**Why:** SharedPreferences plugin writes to Flutter's own file. Native can't read it directly. JSON string passing is the simplest reliable bridge.

**Pattern:**
```dart
// Flutter side
final configJson = config.toJsonString();
WidgetBridge.updateWidgets(configJson: configJson);
```
```kotlin
// Native side
fun saveConfig(context: Context, json: String) {
    context.getSharedPreferences("status_bar_config", Context.MODE_PRIVATE)
        .edit().putString("clock_config", json).apply()
}
```

### 2. ClockData Duplication (Known Tech Debt)

Each of the 3 native Kotlin files (`DateTimeWidgetProvider`, `NotificationIconService`, `FloatingBarService`) has its own `ClockData` data class and `parseClockData()` function.

**Why:** Native files run in different processes/contexts, can't share Kotlin classes easily. Extracting to shared util is planned for v1.1.

**Status:** Works correctly, violates DRY.

### 3. In-Place Overlay Update

`FloatingBarService.update()` sends an Intent with action `"UPDATE_OVERLAY"` → `onStartCommand` handles it → `updateBarContent()` updates the existing view.

**Why:** Stopping and restarting the foreground service is expensive and may cause flicker. In-place update is smoother.

### 4. Daily Reward Reset

`RewardService.resetIfNewDay()` checks stored date vs today. Called at:
- App start (`main.dart`)
- PresetsScreen open

**Why:** Passive reset avoids complex scheduling. Clock app is usually opened daily.

### 5. Legacy JSON Migration

`ClockConfig.normalizeTimeFormat()` strips `:ss` from old `timeFormat` values. Called in `fromJson()`.

**Why:** v1.0 had `showSeconds` + `HH:mm:ss`. After removing seconds support, old saved configs still have `ss` in `timeFormat`. Auto-normalization prevents crash.

## Anti-Patterns Avoided

| Anti-Pattern | Why Avoided |
|-------------|-------------|
| **AlarmManager for seconds** | Causes hao pin, OEM kills process |
| **Handler.postDelayed loop** | Unreliable on Android, battery drain |
| **TYPE_APPLICATION_OVERLAY on status bar** | Blocked since Android 8.0 |
| **Ads on Widget/Notification** | Google Play policy violation |
| **Firebase/Backend** | Out of scope, offline-first design |
| **State management library** | Overkill for this app size |
| **Code generation for JSON** | Adds build complexity, not needed |

## Known Technical Debt

| Debt | Impact | Planned Fix |
|------|--------|------------|
| ClockData duplication across 3 Kotlin files | Maintenance burden | Extract to shared util in v1.1 |
| Alignment not applied on Widget (RemoteViews) | Widget always centered | Layout XML variants in v1.1 |
| TimeTickService no auto-stop | Runs until app killed | Acceptable for clock app |
| `parseClockData` uses regex (not JSON parser) | Fragile if JSON has nested objects | Acceptable for flat config |
