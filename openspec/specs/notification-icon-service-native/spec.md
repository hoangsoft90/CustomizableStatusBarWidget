# Notification Icon Service (Native Android)

## Purpose

Manages a persistent status-bar notification showing the current day number (e.g. "30") as a small monochrome icon, with full date/time in the expanded notification body. Uses `NotificationCompat` with a low-priority ongoing notification.

## Requirements

### R1: Notification channel

Creates a notification channel with `IMPORTANCE_LOW`, no badge, no vibration, no sound.

**Scenario: Channel creation**
- When `start()` or `update()` is called
- Then a `NotificationChannel` with ID `"date_time_icon"` is created (API 26+)
- Reference: `NotificationIconService.kt:123-133`

### R2: Small icon — day number bitmap

`createDayBitmap(text)` renders the day number (e.g. "30") onto a 64×64 ARGB_8888 bitmap with white text, centered.

**Scenario: 2-digit day**
- Given day is 30
- When `createDayBitmap("30")` is called
- Then a 64×64 bitmap with "30" in 38f text size is returned
- Reference: `NotificationIconService.kt:104-118`

**Scenario: 3-digit month (edge case)**
- Given text is "100"
- When `createDayBitmap` is called
- Then text size is 30f (smaller for 3+ chars)
- Reference: `NotificationIconService.kt:113`

### R3: Notification content

- Small icon: day number bitmap
- Large icon: same day number bitmap
- Content title: full date (e.g. "Sunday, 30 August 2026")
- Content text: time (e.g. "14:05")
- BigTextStyle with expanded text showing both date and time
- `setOngoing(true)`, `PRIORITY_LOW`, `CATEGORY_STATUS`

**Scenario: Full notification**
- Given day=30, time=14:05
- When `buildNotification` creates the notification
- Then content title is the full date string
- And content text is the time string
- Reference: `NotificationIconService.kt:80-99`

### R4: Locale-aware formatting

Uses `SimpleDateFormat("EEEE, d MMMM yyyy", Locale.getDefault())` for date and `SimpleDateFormat(timePattern, Locale.getDefault())` for time.

**Scenario: French locale**
- Given device locale is French
- When notification is built
- Then date is formatted in French (e.g. "dimanche, 30 août 2026")
- Reference: `NotificationIconService.kt:63-72`

### R5: Config respects all 8 ClockData fields

Reads `format`, `timeFormat`, `showSeconds`, `showDate`, `showDay`, `fontSize`, `color`, `alignment` from "status_bar_config" SharedPreferences.

**Scenario: showSeconds=true**
- Given config with `showSeconds: true`, `timeFormat: 'HH:mm'`
- When notification is built
- Then time includes seconds (pattern becomes `HH:mm:ss`)
- Reference: `NotificationIconService.kt:73-78`

### R6: start/stop/update lifecycle

- `start(context)`: create channel → notify → save enabled=true
- `stop(context)`: cancel notification → save enabled=false
- `update(context)`: if enabled, re-build and re-notify
- `isEnabled(context)`: reads from SharedPreferences

**Scenario: Stop clears notification**
- When `stop(context)` is called
- Then `nm.cancel(NOTIFICATION_ID)` removes the notification
- Reference: `NotificationIconService.kt:39-42`

### R7: saveConfig from Flutter

`saveConfig(context, json)` writes config to SharedPreferences and triggers `update()`.

**Scenario: Config update from Flutter**
- Given new config JSON from MethodChannel
- When `saveConfig` is called
- Then config is saved and notification is re-rendered
- Reference: `NotificationIconService.kt:51-55`

### R8: Samsung icon clipping fix

Bitmap has 6px padding to prevent clipping on Samsung devices. Text size reduced from 44f→38f and 34f→30f.

**Scenario: Samsung padding**
- When `createDayBitmap` creates the bitmap
- Then the text is drawn with padding accounted for (effective drawable area is 52×52)
- Reference: `NotificationIconService.kt:104-118`

## Need to clear

1. **Bitmap padding is implicit** — the 6px padding mentioned in QA is achieved by the text size and canvas positioning, not an explicit `canvas.translate()` or padding rect. The fix from QA review reduced text sizes rather than adding canvas translation.
