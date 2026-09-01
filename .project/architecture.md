# Architecture

## Design Principle

**Flutter is the gatekeeper.** All config changes originate in Flutter UI, serialized to JSON, and pushed to Native via MethodChannel. Native services read from their own SharedPreferences (`"status_bar_config"`) — never from Flutter's SharedPreferences directly.

## 3-Layer Display Architecture

```
┌──────────────────────────────────────────────────┐
│                   FLUTTER APP                     │
│                                                   │
│  EditorScreen → ClockConfig → StorageService      │
│                   + BackgroundConfig               │
│                    ↓                               │
│            ClockConfig.toJsonString()              │
│                    ↓                               │
│  ┌──────────────┬──────────────┬──────────────┐  │
│  │WidgetBridge  │NotifService  │FloatBridge   │  │
│  │(MethodChan.) │(MethodChan.) │(MethodChan.) │  │
│  └──────┬───────┴──────┬───────┴──────┬───────┘  │
└─────────┼──────────────┼──────────────┼───────────┘
          ↓              ↓              ↓
┌──────────────────────────────────────────────────┐
│              NATIVE ANDROID (Kotlin)               │
│                                                    │
│  MainActivity (MethodChannel hub)                  │
│      ↓ save to "status_bar_config" SharedPreferences│
│                                                    │
│  ┌─────────────────┬──────────────────┬─────────┐ │
│  │DateTimeWidget   │NotificationIcon  │Floating │ │
│  │Provider         │Service           │BarSvc   │ │
│  │(AppWidget+BG)   │(NotifManager)    │(Overlay)│ │
│  └─────────────────┴──────────────────┴─────────┘ │
│                                                    │
│  TimeTickService (ACTION_TIME_TICK → update all 3) │
│  BootReceiver (BOOT_COMPLETED → restart all)       │
└──────────────────────────────────────────────────┘
```

## Config Sync Flow

```
User saves in Editor
  → ClockConfig.toJsonString()
  → WidgetBridge.updateWidgets(configJson: json)
  → NotificationService.update()
  → FloatingBarBridge.update(configJson: json)
       ↓ MethodChannel.invokeMethod('saveConfig', json)
Native: MainActivity receives JSON
  → save to SharedPreferences("status_bar_config", key="clock_config")
  → DateTimeWidgetProvider.saveConfig() → updateAllWidgets()
  → NotificationIconService.saveConfig() → update()
  → FloatingBarService.saveConfig() → update()
```

## Background Bitmap Flow (plan5-8)

```
User picks image in Editor
  → ImageUtils.copyAndResizeSource() (max 1600px)
  → CropScreen for zoom+pan
  → bakeBackgroundBitmap() (per-widget size, max 480px)
  → Save to app documents/widget_bg/bg_{millis}.png
  → WidgetBridge.setWidgetBackground(widgetId, bitmapPath)
       ↓ MethodChannel
Native: MainActivity receives path
  → SharedPreferences("widget_background", key="bg_bitmap_path")
  → DateTimeWidgetProvider.renderWidget() → applyWidgetBackground()
  → BitmapFactory.decodeFile() + inSampleSize + 800px cap
  → RemoteViews.setImageViewBitmap()
```

## ClockConfig Model (10 fields)

```dart
ClockConfig({
  format: 'EEE dd MMM',      // Date pattern
  timeFormat: 'HH:mm',       // HH:mm or hh:mm a (NO seconds)
  showDate: true,             // Show date line
  showDay: true,              // Show day-of-week line
  fontSize: 32,               // Base font size
  color: '#FFFFFF',           // Hex color
  alignment: 'center',        // left/center/right
  notificationEnabled: false, // Notification icon active
  floatingBarEnabled: false,  // Floating bar active
  isPremium: false,           // IAP purchased
})
```

## BackgroundConfig Model

```dart
BackgroundConfig({
  type: BackgroundType.none,  // none/solid/gradient/image
  solidColor: '#000000',
  gradientColors: [Color(0xFF000000), Color(0xFF434343)],
  gradientAngle: 135,
  imagePath: null,            // Path to cropped source image
  overlayMode: OverlayMode.dark,
  overlayOpacity: 0.35,
  blurSigma: 0,
  textShadow: true,
  autoTextContrast: false,
})
```

## RewardState Model (separate persistence)

```dart
RewardState({
  date: 'yyyy-MM-dd',     // Local date for reset detection
  unlockCount: 0,          // Ads watched today (max 2)
  unlockedToday: [],       // Preset IDs usable today
})
```

## SharedPreferences Namespaces

| Namespace | Key | Content |
|-----------|-----|---------|
| `FlutterSharedPreferences` | `clock_config` | ClockConfig JSON (Flutter) |
| `FlutterSharedPreferences` | `reward_state` | RewardState JSON |
| `FlutterSharedPreferences` | `notification_enabled` | bool |
| `FlutterSharedPreferences` | `floatingBarEnabled` | bool |
| `status_bar_config` | `clock_config` | ClockConfig JSON (Native, synced) |
| `widget_background` | `bg_bitmap_path` | Bitmap file path (Native) |

## MethodChannel

| Channel | Direction | Methods |
|---------|-----------|---------|
| `io.photoclock.widget/widgets` | Flutter→Native | `updateWidgets(configJson)`, `setWidgetBackground(widgetId, path)`, `getActiveWidgetIds()` |
| `io.photoclock.widget/notification` | Flutter→Native | `start()`, `stop()`, `update()`, `saveConfig(json)` |
| `io.photoclock.widget/floating_bar` | Flutter→Native | `start()`, `stop()`, `update(configJson)` |
| `io.photoclock.widget/deep_link` | Native→Flutter | `openEditor` |

## Native Services Detail

### DateTimeWidgetProvider (AppWidget)
- 4 layouts: `widget_2x1`, `widget_3x1`, `widget_4x1`, `widget_4x2`
- All use `FrameLayout` root with `ImageView#widget_background` + text shadow
- Reads config from `"status_bar_config"` SharedPreferences
- Reads bitmap path from `"widget_background"` SharedPreferences
- `applyWidgetBackground()`: BitmapFactory.decodeFile + inSampleSize + 800px cap + setImageViewBitmap
- `onAppWidgetOptionsChanged()`: re-renders WITHOUT clearing background
- Updates via `TimeTickService` (ACTION_TIME_TICK) or MethodChannel

### NotificationIconService
- Persistent notification with day number as monochrome bitmap icon
- Full date/time in expanded notification body
- Creates notification channel `"date_time_icon"` (IMPORTANCE_LOW)

### FloatingBarService
- Foreground service with `TYPE_APPLICATION_OVERLAY`
- Positioned right below status bar (offset = statusBarHeight)
- In-place update via `UPDATE_OVERLAY` action (no stop/start cycle)

### TimeTickService
- Dynamically registered `BroadcastReceiver` for `ACTION_TIME_TICK`
- On tick: updates Widget + Notification + FloatingBar

### BootReceiver
- Listens `BOOT_COMPLETED`
- Restarts NotificationIconService + FloatingBarService if enabled
- Triggers widget update

## Design Storage (plan5)

### DesignStorageService
- CRUD for `WidgetDesign` objects in SharedPreferences
- Quota: max 3 designs (free), unlimited (premium)
- Each design has: id, name, clock (ClockConfig), background (BackgroundConfig), createdAt

### My Designs Screen
- List saved designs with thumbnail preview
- Create new design → EditorScreen (storage=null)
- Apply design → updates ClockConfig + BackgroundConfig + all surfaces
- Rename/delete designs

### Share Service
- Render clock preview to PNG (1080×540) with background
- System share sheet via `share_plus`

## Release Build Architecture

### Signing Config (build.gradle.kts)
- Keystore: `photoclock-release.jks`, alias `photoclock`, password `83793900`
- Stored in GH Secret as base64 (`KEYSTORE_BASE64`)
- At build time: decoded to `/tmp/release.jks` → used by `signingConfigs.release`
- R8 disabled: `isMinifyEnabled = false`, `isShrinkResources = false`

### Workflows
| Workflow | File | Trigger | Output |
|----------|------|---------|--------|
| Debug APK | `build-debug-apk.yml` | push to main | `app-debug.apk` (unsigned) |
| Release AAB | `build-release-aab.yml` | push to main | `app-release.aab` (signed) |

### Proguard Rules
`proguard-rules.pro` referenced in build.gradle.kts but R8 is disabled — rules are a safety net for future re-enablement.
