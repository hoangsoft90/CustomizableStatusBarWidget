# Working — Date & Time Widget

> Cập nhật lần cuối: 2026-09-03

## Đã Hoàn Thành

### Session 2026-09-03

- [2026-09-03] **plan9_final.md** — Task 1: Flutter bake 480×480 → 360×160 (`kWidgetBgBakeWidth/Height` trong image_utils.dart; editor_screen + home_screen)
- [2026-09-03] **plan9_final.md** — Task 2: Native decode cap 800 → 400px + hard cap ~400KB raw (`DateTimeWidgetProvider.kt`), giữ `setImageViewBitmap`, không URI/systemui
- [2026-09-03] **plan9_final.md** — Task 3: try/catch quanh `updateAppWidget` + outer guard `renderWidgetInner` (không crash widget host)
- [2026-09-03] **plan9_final.md** — Task 4: Audit 4 XML widget — chỉ FrameLayout/LinearLayout/ImageView/TextView (PASS, không cần sửa)
- [2026-09-03] **plan9_final.md** — Task 5: home_screen bake `catch (_) {}` → debugPrint + SnackBar
- [2026-09-03] **plan9_final.md** — Task 6: `flutter analyze` sạch + 91/91 tests pass; native compile KHÔNG chạy được trên máy này (thiếu Android SDK platforms + hết dung lượng ~/.gradle) — cần verify trên máy có SDK/device
- [2026-09-03] **Code review plan9** — Fix bug class khó tái tạo: scale branch thiếu `coerceAtLeast(1)` (0-dim → createScaledBitmap throw) + sửa comment `maxBakedDimension` lỗi thời
- [2026-09-03] **Push CI** — Commit `4ff7284` "Fix Play widget crash" push lên main → trigger 2 workflow (debug APK + release AAB)
- [2026-09-03] **Log tag spec** — `DateTimeWidgetProvider.kt` L144 đổi tag/message khớp đúng snippet spec (`Log.e("DateTimeWidgetProvider", "Failed to update app widget $widgetId", e)`)
- [2026-09-03] **TAG thống nhất** — Thêm `private const val TAG = "DateTimeWidgetProvider"` (companion object), cả 3 `Log.e` (renderWidget guard, updateAppWidget, applyWidgetBackground) dùng chung 1 TAG
- [2026-09-03] **.project/ updated** — ai-rules (Rule 16: 400px + hard cap; mới 41-42 IPC guard + TAG 1/file), architecture (flow 360×160 + 400px), patterns (pipeline + snippet mới), state (milestones + decisions + known issue native chưa verify)

---

## Trạng Thái Hiện Tại (trước plan9 — giữ để đối chiếu)

## Trạng Thái Hiện Tại

**Version:** 1.0.1+2 (chờ build CI verify)
**Package ID:** `io.photoclock.widget`
**Build:** GitHub Actions ✅ passing (Debug APK + Release AAB)
**Tests:** 91/91 pass ✅
**OpenSpec:** 42 specs
**Ads:** Production IDs, `enableAds=true`, `testAds=false`
**Sentry:** Enabled (error tracking)
**Privacy Policy:** https://all-my-apps-5d52f.web.app/privacy.html
**Release Keystore:** `photoclock-release.jks` in GH Secret ✅
**GH Secrets:** 4 keystore secrets set ✅

## Đã Hoàn Thành

### Session 2026-09-03 (continued)

- [2026-09-03] **Version 1.0.1+2** — Bump pubspec (1.0.0+1 → 1.0.1+2), `AppConstants.appVersion` → '1.0.1', About row trong settings giờ dùng `AppConstants.appName/appVersion` (hết hardcode trôi dạt)

### Session 2026-09-01 (latest)

- [2026-09-01] **plan8_final.md** — Task 1: Bitmap decode + inSampleSize + 800px cap (thay vì URI/FileProvider)
- [2026-09-01] **plan8_final.md** — Task 2: Resize giữ background (onAppWidgetOptionsChanged không xóa)
- [2026-09-01] **plan8_final.md** — Task 3: Bỏ overlay #59000000, thêm text shadow
- [2026-09-01] **plan8_final.md** — Task 4: Save loading (_isSaving) + error reporting
- [2026-09-01] **Code review** — Fix formatting, bitmap lifecycle
- [2026-09-01] **AdMob production** — `enableAds=true`, `testAds=false`, real IDs
- [2026-09-01] **Package rename** — `com.example.date_time_widget` → `io.photoclock.widget`
- [2026-09-01] **OpenSpec update** — 7 specs updated (app-constants, admob-service, ad-banner, editor-screen, home-widget-native, widget-bridge, local-storage)
- [2026-09-01] **Sentry integration** — `sentry_flutter ^9.28.0` + DSN in main.dart
- [2026-09-01] **.project/ Knowledge Items** — ai-rules, README, architecture, state, patterns all updated
- [2026-09-01] **working.md** — Updated with full session progress
- [2026-09-01] **Release keystore** — `photoclock-release.jks`, alias `photoclock`, pass `83793900`, RSA 2048-bit, valid 10000 days
- [2026-09-01] **GH Secrets** — 4 secrets created: KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD
- [2026-09-01] **Release AAB workflow** — `.github/workflows/build-release-aab.yml` with signed keystore
- [2026-09-01] **build.gradle.kts** — Added release signing config + proguard-rules.pro
- [2026-09-01] **R8 fix** — Disabled isMinifyEnabled + isShrinkResources (Flutter incompatible)
- [2026-09-01] **AdMob verified** — enableAds=true, testAds=false confirmed before AAB build

### Session 2026-08-31

- [2026-08-31] **plan5_final.md** — Phase 1: Models (WidgetDesign, BackgroundConfig) + DesignStorageService + ImageUtils
- [2026-08-31] **plan5_final.md** — Phase 2: Background UI in Editor + CropScreen + ClockPreview backgrounds
- [2026-08-31] **plan5_final.md** — Phase 3: Home Widget native (ImageView in 4 XML layouts)
- [2026-08-31] **plan5_final.md** — Phase 4: My Designs screen (CRUD, quota 3, apply flow)
- [2026-08-31] **plan5_final.md** — Phase 5: Share (render PNG 1080×540, system share sheet)
- [2026-08-31] **plan5_final.md** — Phase 6: QA (static review, QA_PLAN5.md checklist)
- [2026-08-31] **plan6_final.md** — Bug A: HomeScreen bg param + EditorScreen color picker
- [2026-08-31] **plan6_final.md** — Bug B: FileProvider + bitmap render on native widget
- [2026-08-31] **plan7_final.md** — Task 1: Loading state (_isProcessingImage)
- [2026-08-31] **plan7_final.md** — Task 2: Native MethodChannel (getActiveWidgetIds + setWidgetBackground)
- [2026-08-31] **plan7_final.md** — Task 3.5: Cache-busting (timestamped bg filenames)
- [2026-08-31] **OpenSpec baseline** — 31 specs created → expanded to 35

### Session 2026-08-30

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

### Earlier (2026-08-29)

- [2026-08-29] **Prompt 7** — Floating Bar (P1 overlay service)
- [2026-08-29] **Prompt 6** — AdMob + IAP integration
- [2026-08-29] **Prompt 5** — Notification icon + boot receiver
- [2026-08-29] **Prompt 4** — Android Widget (4 sizes)
- [2026-08-29] **Prompt 3** — Editor screen + 8 presets
- [2026-08-29] **Prompt 2** — Home screen + live preview
- [2026-08-29] **Prompt 1** — Models + StorageService

## Todo — Trước Khi Release

- [ ] Build debug APK trên device thật (Task 5 plan8 — smoke test 10 cases)
- [x] Release keystore + GH Secrets — Done
- [ ] Data Safety form trên Play Console
- [ ] Content Rating questionnaire
- [ ] Store listing screenshots (4 ảnh)
- [ ] Feature Graphic upload to Play Console
- [ ] appOpenAdUnitId production ID (chưa có từ AdMob)

## Todo — P1 Features

- [ ] Test Floating Bar trên Android 15+ thật
- [ ] Thêm preset theo mùa/tuần
- [ ] Multiple widget instance với style khác nhau

## Todo — Tech Debt

- [ ] Extract ClockData to shared Kotlin util
- [ ] Widget alignment support (layout XML variants)
- [ ] TimeTickService auto-stop
- [ ] Persist BackgroundConfig to SharedPreferences (currently lost on app restart)
- [ ] Native blur support (currently Flutter preview only)
- [ ] Auto text contrast computation (flag stored but not active)
- [ ] Remove legacy `file_paths.xml` + FileProvider (plan8 removed URI approach)

## Known Issues

| Issue | Severity | Status |
|-------|----------|--------|
| Widget alignment not applied on Android < 12 | Low | Known |
| ClockData duplicated in 3 Kotlin files | Low | Known |
| `parseClockData` uses regex | Low | Known |
| `formatTime` replaces ALL `a` chars | Low | Known |
| BackgroundConfig not persisted (lost on restart) | Medium | Known |
| Blur only in Flutter preview (not native widget) | Low | Known |
| Auto text contrast flag stored but not computed | Low | Known |
| onAppWidgetOptionsChanged needs app running to re-bake | Low | Known |
| White text on white BG readability | Medium | Known |
| appOpenAdUnitId placeholder | Low | Known |

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
| #9-10 | ✅ | plan3 + plan5 changes |
| #11+ | ✅ | plan6-8 + package rename + Sentry |
| Release AAB #1 | ❌ | R8 minification crash (Play Core classes missing) |
| Release AAB #2 | ✅ | Disabled isMinifyEnabled + isShrinkResources |
