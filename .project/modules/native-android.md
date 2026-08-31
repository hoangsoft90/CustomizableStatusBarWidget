# Native Android (Kotlin)

## MainActivity (`MainActivity.kt`)

MethodChannel hub — routes Flutter calls to native services.

**Channels:**
- `com.example.date_time_widget/widget` → `WidgetBridge`
- `com.example.date_time_widget/notification` → `NotificationService`
- `com.example.date_time_widget/floating_bar` → `FloatingBarBridge`
- `com.example.date_time_widget/deep_link` → Flutter callback

**Lifecycle:**
- `onCreate()` — registers MethodChannel handlers
- `onResume()` — registers TimeTickService receiver
- `onPause()` — unregisters TimeTickService receiver

**Config save:** All channels save JSON to `"status_bar_config"` SharedPreferences, then trigger respective service update.

## DateTimeWidgetProvider (`DateTimeWidgetProvider.kt`)

Home screen AppWidgetProvider.

**Layouts:** `widget_2x1`, `widget_3x1`, `widget_4x1`, `widget_4x2`

**Static methods:**
- `updateAllWidgets(context)` — renders all widget instances
- `onTick(context)` — called by TimeTickService
- `saveConfig(context, json)` — saves config + updates all

**Config:** Reads from `"status_bar_config"` SharedPreferences via `parseClockData()` (regex-based).

**Features:**
- Locale-aware formatting via `SimpleDateFormat`
- Tap opens app (deep link to Editor)
- Color, font size applied per layout

## NotificationIconService (`NotificationIconService.kt`)

Persistent notification showing day number as monochrome icon.

**Static methods:**
- `start(context)` / `stop(context)` / `update(context)` / `saveConfig(context, json)` / `isEnabled(context)`

**Icon:** 64x64 px bitmap with day number text. Uses `IconCompat.createWithBitmap()`.

**Notification:**
- Channel: `"date_time_icon"` (IMPORTANCE_LOW)
- Small icon: day number bitmap
- Title: full date (e.g., "Sunday, 30 August 2026")
- Text: time (e.g., "08:35")
- BigTextStyle with expanded body
- Ongoing (can't be swiped away)

## FloatingBarService (`FloatingBarService.kt`)

Foreground service drawing overlay below status bar.

**Static methods:**
- `start(context)` / `stop(context)` / `update(context)` / `updateOverlay(context)` / `saveConfig(context, json)` / `isEnabled(context)`

**Overlay:**
- Type: `TYPE_APPLICATION_OVERLAY` (does NOT draw on status bar)
- Position: right below status bar (y = statusBarHeight)
- Transparent background, no input focus
- In-place update via `"UPDATE_OVERLAY"` action

**View:** LinearLayout with day + date + spacer + time TextViews. Alignment applied via `Gravity`.

**Foreground notification:** Required for Android 14+. Channel `"floating_bar"`.

## TimeTickService (`TimeTickService.kt`)

Dynamically registered BroadcastReceiver for `ACTION_TIME_TICK`.

**On tick:** Calls `DateTimeWidgetProvider.onTick()` which updates all 3 services.

**Registration:** Registered in `MainActivity.onResume()`, unregistered in `onPause()`.

**Why not AlarmManager:** Battery efficient, OEM-friendly, no exact alarm permission needed.

## BootReceiver (`BootReceiver.kt`)

Listens for `BOOT_COMPLETED` broadcast.

**On boot:**
1. Checks if notification was enabled → restarts NotificationIconService
2. Checks if floating bar was enabled → restarts FloatingBarService
3. Triggers widget update

## AndroidManifest.xml

**Permissions:**
- `RECEIVE_BOOT_COMPLETED` — boot receiver
- `POST_NOTIFICATIONS` — Android 13+ notification permission
- `SYSTEM_ALERT_WINDOW` — overlay permission
- `INTERNET` — AdMob + network
- `WAKE_LOCK` — foreground service

**Components:**
- `DateTimeWidgetProvider` — AppWidget with resize 2x1 to 4x2
- `NotificationIconService` — Service
- `FloatingBarService` — Foreground service
- `TimeTickService` — BroadcastReceiver
- `BootReceiver` — BOOT_COMPLETED receiver

**Meta-data:**
- `com.google.android.gms.ads.APPLICATION_ID` — test App ID
- `android.appwidget.provider` — widget XML resources

## Layout XMLs

| File | Size | Notes |
|------|------|-------|
| `widget_2x1.xml` | 180dp × 110dp | Minimal |
| `widget_3x1.xml` | 250dp × 110dp | Medium |
| `widget_4x1.xml` | 320dp × 110dp | Wide |
| `widget_4x2.xml` | 320dp × 220dp | Tall |

All layouts have: `widget_day`, `widget_date`, `widget_time` TextViews.

## Network Security Config

`res/xml/network_security_config.xml` — allows cleartext HTTP for development/testing.

**Production:** Should restrict to HTTPS only per Play Store policy.
