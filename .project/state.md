# Project State

## Current Status

| Milestone | Status | Notes |
|-----------|--------|-------|
| **Prompt 1** — Models + Storage | ✅ Done | ClockConfig, Preset, StorageService |
| **Prompt 2** — Home Screen + Preview | ✅ Done | ClockPreview, DateFormatter, Home UI |
| **Prompt 3** — Editor + Presets | ✅ Done | Editor screen, 8 presets, live preview |
| **Prompt 4** — Android Widget | ✅ Done | AppWidgetProvider, 4 layouts |
| **Prompt 5** — Notification Icon | ✅ Done | Persistent notification, bitmap icon |
| **Prompt 6** — AdMob + IAP | ✅ Done | Banner, Rewarded, Remove Ads IAP |
| **Prompt 7** — Floating Bar | ✅ Done | Overlay foreground service |
| **Prompt 8** — QA | ✅ Done | 91 tests, QA report |
| **plan2_final.md** — 9 Fixes | ✅ Done | Sunday crash, config sync, locale, etc. |
| **plan3_final.md** — Task A: Remove seconds | ✅ Done | showSeconds removed everywhere |
| **plan3_final.md** — Task B: Daily Reward | ✅ Done | RewardService, max 2/day |
| **plan3_final.md** — Task C: Rewrite tests | ✅ Done | 91 tests pass |
| **OpenSpec baseline** | ✅ Done | 31 specs |
| **GitHub Actions build** | ✅ Done | Debug APK workflow |
| **Google Play assets** | ✅ Done | Privacy policy, app-ads.txt, chplay.md |
| **targetSdkVersion 36** | ✅ Done | Google Play requirement |
| **App icon** | ✅ Done | Clock-themed, all densities |

## Todo List (Remaining)

### Before Release
- [ ] Đổi package ID từ `com.example` sang org thật (e.g., `com.haibasoftware.datetimewidget`)
- [ ] Thay production AdMob IDs trong `constants.dart` (flip `testAds = false`)
- [ ] Upload keystore release signing
- [ ] Data Safety form trên Play Console
- [ ] Content Rating questionnaire
- [ ] Store listing screenshots (4 ảnh)
- [ ] Feature Graphic (1024x500)
- [ ] Store description (đã có trong `chplay.md`)

### P1 Features (Sau MVP)
- [ ] Floating Bar — test trên Android 15+ thật
- [ ] Thêm preset theo mùa/tuần
- [ ] Share preset dưới dạng ảnh
- [ ] Multiple widget instance với style khác nhau

### P2 Features (Nếu có data)
- [ ] Interstitial ads (sau khi Save config)
- [ ] Notification shade companion
- [ ] Dark/Light theme riêng cho widget

### Tech Debt
- [ ] Extract ClockData to shared Kotlin util (DRY)
- [ ] Widget alignment support (layout XML variants cho Android < 12)
- [ ] TimeTickService auto-stop khi user tắt hết features

## Known Issues

| Issue | Severity | Status | Notes |
|-------|----------|--------|-------|
| Widget alignment not applied | Low | Known | `setViewLayoutGravity` needs API 31+, widget uses center by default |
| ClockData duplicated in 3 Kotlin files | Low | Known | Tech debt, works correctly |
| `parseClockData` uses regex | Low | Known | Fragile but acceptable for flat config |
| `formatTime` replaces ALL `a` characters | Low | Known | Edge case if format contains literal "a" |

## Key Decisions Made

| Decision | Rationale | Reference |
|----------|-----------|-----------|
| Flutter is sole gatekeeper for config | One-directional sync, simpler architecture | plan1 §0 |
| Native reads own SharedPreferences | Flutter plugin writes to different file | plan2 #3 |
| No seconds support | Android can't tick per-second reliably | plan3 Task A |
| Daily reward (not permanent unlock) | Better recurring revenue | plan3 Task B |
| RewardState separate from ClockConfig | Clean separation of concerns | plan3 Task B |
| In-place overlay update (not stop/start) | Smoother, no service restart flicker | plan2 #8 |
| ACTION_TIME_TICK (not AlarmManager) | Battery efficient, OEM-friendly | plan2 #5 |
| No ads on Widget/Notification/Overlay | Google Play policy compliance | plan1 §4 |
| Test Ads flag in constants.dart | Safe development, no account risk | plan1 §6 |

## Build History

| Run | Status | Issue |
|-----|--------|-------|
| #1 | ❌ | SDK version mismatch |
| #2 | ✅ | — |
| #3 | ❌ | Core library desugaring |
| #4 | ✅ | — |
| #5 | ❌ | Kotlin compilation errors |
| #6 | ✅ | — |
| #7 | ❌ | XML parsing (unescaped &) |
| #8 | ✅ | — |
| #9 | ✅ | Latest — all plan3 changes |
