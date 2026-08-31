# Context — Date & Time Widget

> Cập nhật lần cuối: 2026-08-31

## Mục đích

App Android giúp user thấy ngày, giờ trên 3 lớp:
1. **Home Screen Widget** — widget đặt trên màn hình chính (P0)
2. **Notification Icon** — icon số ngày trong notification bar (P0)
3. **Floating Bar** — thanh nổi ngay dưới status bar (P1, optional)

**Positioning:** "Always see the day, date & time — home widget + status bar icon."

## Tech Stack

| Layer | Technology |
|-------|-----------|
| App framework | Flutter (Dart SDK ^3.13.1) |
| Native layer | Kotlin (JVM 17) |
| Persistence | SharedPreferences (offline, no backend) |
| Ads | Google Mobile Ads (Banner + Rewarded) |
| IAP | in_app_purchase (Remove Ads) |
| Notifications | flutter_local_notifications |
| Permissions | permission_handler |
| Build | GitHub Actions (Flutter stable + Java 17) |
| Target | Android API 36 |
| Image picking | image_picker ^1.1.2 |
| Image processing | dart:ui (canvas rendering) |
| File storage | path_provider ^2.1.5 |
| Sharing | share_plus ^10.1.4 |
| ID generation | uuid ^4.5.1 |

## Kiến Trúc Quan Trọng

### Config Sync (One-Direction)

```
Flutter UI → ClockConfig.toJsonString() → MethodChannel
  → Native saves to SharedPreferences("status_bar_config")
  → 3 native services read from same key
```

**Quyết định:** Flutter là gatekeeper duy nhất. Native không tự gọi lại Flutter. Mỗi native file có own `ClockData` + `parseClockData()` (tech debt đã known).

### RewardState (Separate Persistence)

```
ClockConfig (display settings)     → key "clock_config"
RewardState (daily unlock tracking) → key "reward_state"
```

**Quyết định:** Tách riêng vì reward có lifecycle khác (reset hàng ngày). ClockConfig không có `unlockedPresets` nữa.

### Display Architecture

```
DateTimeWidgetProvider  ← AppWidget (4 sizes, ImageView background)
NotificationIconService ← Persistent notification (bitmap icon)
FloatingBarService      ← Foreground service + overlay
TimeTickService         ← ACTION_TIME_TICK receiver (updates all 3)
BootReceiver            ← BOOT_COMPLETED (restart services)
```

### Design Personalization (plan5)

```
WidgetDesign (ClockConfig + BackgroundConfig)
  ↓
DesignStorageService (CRUD, quota 3, SharedPreferences JSON list)
  ↓
EditorScreen (Background: None/Solid/Gradient/Image)
  ↓ pick image → CropScreen (zoom+pan) → smart defaults
  ↓
ClockPreview (Stack: image → overlay → text)
  ↓ apply
HomeScreen._openMyDesigns()
  → saveConfig() → WidgetBridge.updateWidgets()
  → notifService.update() → FloatingBarBridge.update()
  ↓ bake
WidgetBridge.setWidgetBackground(widgetId, bitmapPath)
  → Native: BitmapFactory.decodeFile → RemoteViews.setImageViewBitmap
```

**Bitmap caching:** Per `(designId, widgetId)`. Cleared on `onAppWidgetOptionsChanged` (user resize).

## Quyết Định Kiến Trúc Đã Chốt

| # | Quyết định | Lý do | Tham chiếu |
|---|-----------|-------|------------|
| 1 | Không vẽ đè status bar thật | Blocked since Android 8.0 | plan1 §0 |
| 2 | Notification icon chỉ hiện số ngày | Icon slot nhỏ, monochrome | plan1 §0 |
| 3 | Floating Bar đặt DƯỚI status bar | Không vi phạm System UI | plan1 §0 |
| 4 | No seconds support | Android unreliable per-second tick | plan3 Task A |
| 5 | Daily reward (not permanent unlock) | Better recurring revenue | plan3 Task B |
| 6 | ACTION_TIME_TICK (not AlarmManager) | Battery efficient | plan2 #5 |
| 7 | In-place overlay update | No service restart flicker | plan2 #8 |
| 8 | No ads outside app | Google Play policy | plan1 §4 |
| 9 | No backend/account | Offline-first, simpler | plan1 scope |
| 10 | JSON regex parsing (not JSON lib) | Config flat, no extra deps | Known tradeoff |
| 11 | Bitmap baked per widgetId (not shared) | Different sizes need different crops | plan5 §2.2 |
| 12 | 480×480px max for baked bitmaps | Android 12+ bitmap memory limit | plan5 §2.3 |
| 13 | Background not in SharedPreferences | Stored in WidgetDesign list only | plan5 design decision |

## Tech Debt Đã Known

1. ClockData duplication across 3 Kotlin files (DRY violation)
2. Widget alignment not applied (RemoteViews limitation)
3. TimeTickService no auto-stop
4. `parseClockData` uses regex (fragile for nested JSON)
5. `formatTime` replaces ALL `a` characters
6. BackgroundConfig not persisted to SharedPreferences (lost on restart)
7. Native blur not implemented (Flutter preview only)
8. Auto text contrast flag stored but not actively computed
