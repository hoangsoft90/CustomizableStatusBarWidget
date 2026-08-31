# Date & Time Widget

Flutter + Native Android app showing day/date/time on 3 layers: home widget, notification icon, floating bar.

## Quick Start

```bash
cd date_time_widget
flutter pub get
flutter test          # 91 tests
flutter analyze       # check errors
```

## Build

**KHÔNG build APK local.** Push to GitHub Actions:
```bash
git add -A && git commit -m "msg" && git push
# APK tự build: https://github.com/hoangsoft90/CustomizableStatusBarWidget/actions
```

## Project Structure

```
date_time_widget/
├── lib/
│   ├── models/        # ClockConfig, Preset, RewardState
│   ├── screens/       # Home, Editor, Presets, Settings
│   ├── widgets/       # ClockPreview, PresetCard, AdBanner
│   ├── services/      # Storage, Ads, IAP, Reward, Bridges
│   └── utils/         # DateFormatter, Constants
├── android/.../kotlin/ # Native: Widget, Notification, FloatingBar, TimeTick, Boot
└── test/              # 91 unit tests
```

## Key Architecture

- **Flutter = gatekeeper.** All config changes → ClockConfig → JSON → MethodChannel → Native.
- **Native reads own SharedPreferences** (`"status_bar_config"`), not Flutter's.
- **ClockConfig = 10 fields** (no showSeconds, no unlockedPresets — removed in plan3).
- **RewardService** tracks daily unlocks (max 2/day), separate from ClockConfig.

## Rules

1. **No features outside plan.** Read plan1/2/3_final.md before coding.
2. **No ads on Widget/Notification/FloatingBar.** Google Play policy.
3. **Whitelist packages only:** shared_preferences, google_mobile_ads, in_app_purchase, flutter_local_notifications, permission_handler.
4. **targetSdk = 36.** Google Play requirement.
5. **Test before reporting done.** 91 tests minimum.

## Plans

| Plan | Status | Content |
|------|--------|---------|
| plan1_final.md | ✅ Done | MVP features, architecture, wireframe |
| plan2_final.md | ✅ Done | 9 fixes (Sunday crash, config sync, locale, etc.) |
| plan3_final.md | ✅ Done | Remove seconds + daily reward + rewrite tests |

## Useful Links

- **Repo:** https://github.com/hoangsoft90/CustomizableStatusBarWidget
- **Actions:** https://github.com/hoangsoft90/CustomizableStatusBarWidget/actions
- **Privacy Policy:** https://hoangsoft90.github.io/CustomizableStatusBarWidget/
- **app-ads.txt:** https://all-my-apps-5d52f.web.app/app-ads.txt
- **Store listing draft:** https://share.jotbird.com/clever-vibrant-pronghorn
- **Contact:** haibasoftware@gmail.com
