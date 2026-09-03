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
| **plan5_final.md** — Phase 1-6 | ✅ Done | Models, Background UI, Widget BG, My Designs, Share, QA |
| **plan6_final.md** — Bug A + Bug B | ✅ Done | HomeScreen bg param, editor color picker, FileProvider + bitmap |
| **plan7_final.md** — Task 1-3.5 | ✅ Done | Loading state, cache-busting, MethodChannel BG sync |
| **plan8_final.md** — Task 1-4 | ✅ Done | Bitmap decode, resize preserve, text shadow, save loading |
| **OpenSpec baseline** | ✅ Done | 42 specs (7 updated for plan6-8) |
| **Package ID change** | ✅ Done | `com.example.date_time_widget` → `io.photoclock.widget` |
| **AdMob production** | ✅ Done | `enableAds=true`, `testAds=false`, real IDs |
| **Sentry integration** | ✅ Done | Error tracking enabled |
| **GitHub Actions build** | ✅ Done | Debug APK workflow |
| **Google Play assets** | ✅ Done | Privacy policy, app-ads.txt, chplay.md, icon, feature graphic |
| **User guide** | ✅ Done | Deployed to Firebase Hosting |
| **targetSdkVersion 36** | ✅ Done | Google Play requirement |
| **AI-rules + Knowledge Items** | ✅ Done | Updated for plan6-8 changes |
| **Release AAB workflow** | ✅ Done | `.github/workflows/build-release-aab.yml` + signed keystore |
| **Release keystore** | ✅ Done | `photoclock-release.jks`, alias `photoclock`, pass `83793900` |
| **GH Secrets (keystore)** | ✅ Done | 4 secrets: KEYSTORE_BASE64, KEYSTORE_PASSWORD, KEY_ALIAS, KEY_PASSWORD |
| **R8 fix** | ✅ Done | Disabled isMinifyEnabled + isShrinkResources (Flutter incompatible) |
| **AdMob verified** | ✅ Done | enableAds=true, testAds=false confirmed before AAB build |
| **plan9_final.md** — Task 1-6 | ✅ Done | Play widget crash fix: bake 360×160, native 400px cap + ~400KB hard cap, try/catch IPC guards |
| **plan9 log tag thống nhất** | ✅ Done | `TAG = "DateTimeWidgetProvider"` dùng cho mọi Log.e trong file |

## Todo List (Remaining)

### Before Release
- [ ] Build debug APK on device (Task 5 plan8 — smoke test 10 cases)
- [x] Release keystore + GH Secrets — Done
- [ ] Data Safety form trên Play Console
- [ ] Content Rating questionnaire
- [ ] Store listing screenshots (4 ảnh)
- [ ] Feature Graphic upload to Play Console
- [ ] appOpenAdUnitId production ID (not yet available from AdMob)

### P1 Features (Sau MVP)
- [ ] Test Floating Bar trên Android 15+ thật
- [ ] Thêm preset theo mùa/tuần
- [ ] Multiple widget instance với style khác nhau

### P2 Features (Nếu có data)
- [ ] Interstitial ads (sau khi Save config)
- [ ] Notification shade companion
- [ ] Dark/Light theme riêng cho widget

### Tech Debt
- [ ] Extract ClockData to shared Kotlin util (DRY)
- [ ] Widget alignment support (layout XML variants cho Android < 12)
- [ ] TimeTickService auto-stop khi user tắt hết features
- [ ] Persist BackgroundConfig to SharedPreferences (lost on restart)
- [ ] Native blur support (Flutter preview only)
- [ ] Auto text contrast computation (flag stored but not active)
- [ ] Remove legacy `file_paths.xml` + FileProvider (plan8 removed URI approach)

## Known Issues

| Issue | Severity | Status | Notes |
|-------|----------|--------|-------|
| Widget alignment not applied | Low | Known | `setViewLayoutGravity` needs API 31+ |
| ClockData duplicated in 3 Kotlin files | Low | Known | Tech debt, works correctly |
| `parseClockData` uses regex | Low | Known | Fragile but acceptable for flat config |
| `formatTime` replaces ALL `a` characters | Low | Known | Edge case if format contains literal "a" |
| BackgroundConfig not persisted | Medium | Known | Lost on app restart unless re-applied |
| Blur only in Flutter preview | Low | Known | Native widget shows raw bitmap |
| Auto text contrast not computed | Low | Known | Flag stored but not active |
| onAppWidgetOptionsChanged needs app running | Low | Known | Background lost if app killed + resize |
| White text on white BG unreadable | Medium | Known | Text shadow helps but not sufficient for all cases |
| appOpenAdUnitId placeholder | Low | Known | App Open ads not yet integrated |
| Native compile chưa verify trên máy local | Medium | In progress | plan9 Kotlin thay đổi chưa compile được (thiếu Android SDK platform + hết dung lượng); chờ verify qua CI/GitHub Actions hoặc máy có SDK |

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
| Bitmap thay vì URI/systemui (plan8) | Avoids FileProvider complexity, Binder IPC safe with 800px cap | plan8 §1 |
| Bake 480×480 → 360×160 + native 400px cap + ~400KB hard cap (plan9) | 480/800px vượt Binder limit → TransactionTooLargeException crash widget host (Play) | plan9 §Task 1-2 |
| IPC guard quanh updateAppWidget + renderWidget (plan9) | Transaction fail không được crash widget host / abort onUpdate loop | plan9 §Task 3 |
| Resize giữ background (plan8) | User expects BG persists across resize | plan8 §2 |
| Text shadow thay vì overlay (plan8) | More flexible, works on any background | plan8 §3 |
| enableAds=true production (latest) | Real ads for monetization | Session update |
| Package ID io.photoclock.widget | Professional branding, not tied to username | Session update |
| Sentry for error tracking | Catch native + Flutter crashes | Session update |
| shared BG_PREFS namespace (plan6) | Single background shared by all widget instances | plan6 §3 |
| Cache-busting via timestamp (plan7) | Prevents stale bitmap after image change | plan7 §3.5 |
| Release keystore fixed (not rotated) | Play Store requires same signing key | Session update |
| R8 disabled for release | Flutter deferred components incompatible with R8 | Session update |
| Release signing via GH Secrets | Avoids hardcoding keystore in repo | Session update |

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
| #9-10 | ✅ | plan3 + plan5 changes |
| #11+ | ✅ | plan6-8 + package rename + Sentry |
| Release AAB #1 | ❌ | R8 minification crash (Play Core classes missing) |
| Release AAB #2 | ✅ | Disabled isMinifyEnabled + isShrinkResources |
