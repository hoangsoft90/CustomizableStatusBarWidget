# Working — Date & Time Widget

> Cập nhật lần cuối: 2026-08-30

## Trạng Thái Hiện Tại

**Version:** 1.0.0+1 (chưa release)
**Build:** GitHub Actions ✅ passing
**Tests:** 91/91 pass ✅
**Package ID:** `com.example.date_time_widget` (tạm)

## Đã Hoàn Thành

- [2026-08-30] **plan3_final.md** — Task A: Remove showSeconds (fix bug 08:35:42:42)
- [2026-08-30] **plan3_final.md** — Task B: Daily Reward Entitlement (RewardService, max 2/day)
- [2026-08-30] **plan3_final.md** — Task C: Rewrite tests (69 → 91 tests)
- [2026-08-30] **OpenSpec baseline** — 31 specs created
- [2026-08-30] **.project/ Knowledge Items** — architecture, patterns, state, AI rules
- [2026-08-30] **Memory files** — CLAUDE.md, context.md, working.md, operating_rules.md
- [2026-08-30] **plan2_final.md** — 9 fixes (Sunday crash, config sync, locale, alignment, etc.)
- [2026-08-30] **App icon** — Clock-themed, all densities
- [2026-08-30] **targetSdkVersion 36** + network security config
- [2026-08-30] **AdMob test_ads flag** in constants.dart
- [2026-08-30] **Privacy Policy** — GitHub Pages
- [2026-08-30] **app-ads.txt** — Firebase Hosting
- [2026-08-30] **chplay.md** — Store listing draft (JotBird)
- [2026-08-30] **GitHub Actions workflow** — Debug APK build
- [2026-08-29] **Prompt 7** — Floating Bar (P1 overlay service)
- [2026-08-29] **Prompt 6** — AdMob + IAP integration
- [2026-08-29] **Prompt 5** — Notification icon + boot receiver
- [2026-08-29] **Prompt 4** — Android Widget (4 sizes)
- [2026-08-29] **Prompt 3** — Editor screen + 8 presets
- [2026-08-29] **Prompt 2** — Home screen + live preview
- [2026-08-29] **Prompt 1** — Models + StorageService

## Todo — Trước Khi Release

- [ ] Đổi package ID từ `com.example` sang org thật
- [ ] Thay production AdMob IDs (flip `testAds = false`)
- [ ] Upload keystore release signing
- [ ] Data Safety form trên Play Console
- [ ] Content Rating questionnaire
- [ ] Store listing screenshots (4 ảnh)
- [ ] Feature Graphic (1024x500)

## Todo — P1 Features

- [ ] Test Floating Bar trên Android 15+ thật
- [ ] Thêm preset theo mùa/tuần
- [ ] Share preset dưới dạng ảnh
- [ ] Multiple widget instance

## Todo — Tech Debt

- [ ] Extract ClockData to shared Kotlin util
- [ ] Widget alignment support (layout XML variants)
- [ ] TimeTickService auto-stop

## Known Issues

| Issue | Severity | Status |
|-------|----------|--------|
| Widget alignment not applied on Android < 12 | Low | Known |
| ClockData duplicated in 3 Kotlin files | Low | Known |
| `parseClockData` uses regex | Low | Known |
| `formatTime` replaces ALL `a` chars | Low | Known |

## Build History

| Run | Status | Fix |
|-----|--------|-----|
| #1 | ❌ | SDK version mismatch |
| #2 | ✅ | — |
| #3 | ❌ | Core library desugaring |
| #4 | ✅ | — |
| #5 | ❌ | Kotlin compilation errors |
| #6 | ✅ | — |
| #7 | ❌ | XML parsing (unescaped &) |
| #8 | ✅ | — |
| #9+ | ✅ | All plan3 changes |
