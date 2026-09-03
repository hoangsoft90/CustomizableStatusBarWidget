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

### 6. Bitmap Background Pipeline (plan5-9)

Editor bakes bitmap dùng chung 360×160 (constants `kWidgetBgBakeWidth/Height` — KHÔNG còn 480×480) → saves to `widget_bg/bg_{millis}.png` → MethodChannel to native → native decodes with `inSampleSize` + 400px max side + hard cap ~400KB raw → `setImageViewBitmap` on RemoteViews.

**Why:** `setImageViewUri` + FileProvider caused Binder IPC issues. `setImageViewBitmap` with controlled size is safer. Plan9 siết budget (400px + ~400KB raw) vì bản 480/800px có thể vượt Binder transaction limit → TransactionTooLargeException crash widget host (lỗi Play thực tế).

**Pattern:**
```dart
// Flutter: bake per-widget size
final bitmap = await bakeBackgroundBitmap(bgConfig, width, height);
final file = await saveBakedBitmap(bitmap, widgetId);
WidgetBridge.setWidgetBackground(widgetId, file.path);
```
```kotlin
// Native: decode + downsample (plan9: 400px max side + hard cap ~400KB raw)
val opts = BitmapFactory.Options().apply { inJustDecodeBounds = true }
BitmapFactory.decodeFile(bgPath, opts)
opts.inSampleSize = calculateInSampleSize(opts, 400, 400)
opts.inJustDecodeBounds = false
val bitmap = BitmapFactory.decodeFile(bgPath, opts)
var bmp = if (maxOf(bitmap.width, bitmap.height) > 400) {
    val scale = 400f / maxOf(bitmap.width, bitmap.height)
    Bitmap.createScaledBitmap(bitmap,
        (bitmap.width * scale).toInt().coerceAtLeast(1),   // clamp >= 1px
        (bitmap.height * scale).toInt().coerceAtLeast(1), true)
} else bitmap
// Hard cap ~400KB raw — scale 85%/step cho tới khi dưới budget
while (bmp.width.toLong() * bmp.height * 4 > 400_000L) {
    val next = Bitmap.createScaledBitmap(bmp,
        (bmp.width * 0.85f).toInt().coerceAtLeast(1),
        (bmp.height * 0.85f).toInt().coerceAtLeast(1), true)
    if (next !== bmp) bmp.recycle()
    bmp = next
}
views.setImageViewBitmap(R.id.widget_background, bmp)
```

### 7. Cache-Busting via Timestamp (plan7)

Bitmap filenames use `bg_{DateTime.now().millisecondsSinceEpoch}.png` instead of fixed `current_bg.png`. Old files cleaned up best-effort.

**Why:** Android widget Launcher caches RemoteViews bitmaps by file path. Same filename = stale bitmap after image change.

### 8. Text Shadow Instead of Overlay (plan8)

TextViews use `shadowColor="#AA000000"` + `shadowDx=0` + `shadowDy=1` instead of a hardcoded `#59000000` overlay on LinearLayout.

**Why:** Overlay darkened ALL backgrounds equally (including already-dark ones). Text shadow is adaptive and preserves background vibrancy.

### 9. enableAds Master Switch (plan8)

`AppConstants.enableAds` is a compile-time const. When `false`, every method in `AdsService` short-circuits immediately — no `MobileAds.init()`, no banner load, no rewarded preload.

**Why:** Clean toggle for development vs production. Prevents accidental ad calls during testing.

### 10. Release Signing via GH Secrets (session)

Keystore file (`photoclock-release.jks`) is base64-encoded and stored in GH Secret `KEYSTORE_BASE64`. At build time, `build.gradle.kts` decodes it to `/tmp/release.jks` and uses it to sign the AAB. Password and alias also from GH Secrets.

**Why:** Avoids hardcoding keystore credentials in repo. Same keystore must be used for all releases (Play Store requirement).

**Pattern:**
```kotlin
// build.gradle.kts
signingConfigs {
    create("release") {
        val ksFile = File("/tmp/release.jks")
        if (!ksFile.exists() && System.getenv("KEYSTORE_BASE64") != null) {
            ksFile.writeBytes(Base64.getDecoder().decode(System.getenv("KEYSTORE_BASE64")))
        }
        keyAlias = System.getenv("KEY_ALIAS") ?: ""
        keyPassword = System.getenv("KEY_PASSWORD") ?: ""
        storeFile = ksFile
        storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
    }
}
```

### 11. R8 Disabled for Flutter Release (session)

Flutter's Gradle plugin auto-enables R8 minification for release builds. R8 fails because Play Core / Flutter deferred components classes are missing. Fix: explicitly set `isMinifyEnabled = false` and `isShrinkResources = false` in the release buildType.

**Why:** Flutter deferred components don't include all classes R8 needs. Until Flutter officially supports R8, it must be disabled.

## Known Technical Debt

| Debt | Impact | Planned Fix |
|------|--------|------------|
| ClockData duplication across 3 Kotlin files | Maintenance burden | Extract to shared util in v1.1 |
| Alignment not applied on Widget (RemoteViews) | Widget always centered | Layout XML variants in v1.1 |
| TimeTickService no auto-stop | Runs until app killed | Acceptable for clock app |
| `parseClockData` uses regex (not JSON parser) | Fragile if JSON has nested objects | Acceptable for flat config |
| Legacy `file_paths.xml` + FileProvider unused | Dead file after plan8 removed URI approach | Remove in cleanup pass |
| White text on white BG readability | Text shadow insufficient for extreme cases | Consider auto-contrast in v1.1 |
