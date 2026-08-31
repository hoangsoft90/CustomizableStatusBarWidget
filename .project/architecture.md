# Architecture

## Design Principle

**Flutter is the gatekeeper.** All config changes originate in Flutter UI, serialized to JSON, and pushed to Native via MethodChannel. Native services read from their own SharedPreferences (`"status_bar_config"`) — never from Flutter's SharedPreferences directly.

## 3-Layer Display Architecture

```
┌──────────────────────────────────────────────────┐
│                   FLUTTER APP                     │
│                                                   │
│  EditorScreen → ClockConfig → StorageService      │
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
│  │(AppWidget)      │(NotifManager)    │(Overlay)│ │
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

**Legacy fields removed (plan3_final.md):**
- `showSeconds` — removed, `normalizeTimeFormat()` strips `:ss` from old JSON
- `unlockedPresets` — replaced by `RewardState` in separate SharedPreferences key

## RewardState Model (separate persistence)

```dart
RewardState({
  date: 'yyyy-MM-dd',     // Local date for reset detection
  unlockCount: 0,          // Ads watched today (max 2)
  unlockedToday: [],       // Preset IDs usable today
})
```

Stored in SharedPreferences key `"reward_state"`, separate from ClockConfig.

## Native Services Detail

### DateTimeWidgetProvider (AppWidget)
- 4 layouts: `widget_2x1`, `widget_3x1`, `widget_4x1`, `widget_4x2`
- Reads config from `"status_bar_config"` SharedPreferences
- Uses `SimpleDateFormat` for locale-aware formatting
- Updates via `TimeTickService` (ACTION_TIME_TICK) or MethodChannel

### NotificationIconService
- Persistent notification with day number as monochrome bitmap icon
- Full date/time in expanded notification body
- Uses `IconCompat.createWithBitmap()` for custom icon
- Creates notification channel `"date_time_icon"` (IMPORTANCE_LOW)

### FloatingBarService
- Foreground service with `TYPE_APPLICATION_OVERLAY`
- Positioned right below status bar (offset = statusBarHeight)
- Transparent background, no input focus
- In-place update via `UPDATE_OVERLAY` action (no stop/start cycle)

### TimeTickService
- Dynamically registered `BroadcastReceiver` for `ACTION_TIME_TICK`
- On tick: updates Widget + Notification + FloatingBar
- Registered in `MainActivity.onResume()`, unregistered in `onPause()`

### BootReceiver
- Listens `BOOT_COMPLETED`
- Restarts NotificationIconService + FloatingBarService if enabled
- Triggers widget update

## SharedPreferences Keys

| Key | File | Content |
|-----|------|---------|
| `clock_config` | `FlutterSharedPreferences` | ClockConfig JSON (Flutter) |
| `clock_config` | `status_bar_config` | ClockConfig JSON (Native, synced) |
| `flutter.notification_enabled` | `FlutterSharedPreferences` | bool |
| `flutter.floatingBarEnabled` | `FlutterSharedPreferences` | bool |
| `reward_state` | `FlutterSharedPreferences` | RewardState JSON |

## MethodChannel

| Channel | Direction | Methods |
|---------|-----------|---------|
| `com.example.date_time_widget/widget` | Flutter→Native | `updateWidgets(configJson)` |
| `com.example.date_time_widget/notification` | Flutter→Native | `start()`, `stop()`, `update()`, `saveConfig(json)` |
| `com.example.date_time_widget/floating_bar` | Flutter→Native | `start()`, `stop()`, `update(configJson)` |
| `com.example.date_time_widget/deep_link` | Native→Flutter | `openEditor` |
