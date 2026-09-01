# Date & Time Widget — Knowledge Items

> Auto-generated knowledge base for the **CustomizableStatusBarWidget** project.
> Last updated: 2026-09-01

## Quick Navigation

| File | Nội dung |
|------|----------|
| [`overview.md`](overview.md) | Mục đích app, tech stack, platform, version |
| [`architecture.md`](architecture.md) | Kiến trúc 3 lớp Flutter+Native, config sync, MethodChannel |
| [`patterns.md`](patterns.md) | Coding conventions, patterns, anti-patterns đã tránh |
| [`state.md`](state.md) | Trạng thái hiện tại: todo list, known issues, decisions |
| [`ai-rules.md`](ai-rules.md) | Rules riêng cho AI agent khi làm việc với project này |
| [`modules/`](modules/) | Chi tiết từng module (Flutter + Native) |

## Project Identity

| | |
|---|---|
| **App name** | Photo Clock Widget (package: `io.photoclock.widget`) |
| **Package ID** | `io.photoclock.widget` |
| **Version** | 1.0.0+1 (chưa release) |
| **Repo** | https://github.com/hoangsoft90/CustomizableStatusBarWidget |
| **Build** | GitHub Actions: Debug APK + Release AAB (signed keystore) |
| **Target** | Android (SDK 36, minSdk from Flutter) |
| **Release Keystore** | `photoclock-release.jks` in GH Secret |
| **Contact** | haibasoftware@gmail.com |
| **Sentry DSN** | Configured in `main.dart` |
| **Privacy Policy** | https://all-my-apps-5d52f.web.app/privacy.html |

## Architecture at a Glance

```
┌─────────────────────────────────────────────────┐
│                   FLUTTER                        │
│  ClockConfig ←→ StorageService (SharedPreferences)│
│  BackgroundConfig (per-design)                   │
│  DesignStorageService (My Designs CRUD)          │
│       ↕ MethodChannel (JSON)                     │
├─────────────────────────────────────────────────┤
│               NATIVE ANDROID (Kotlin)            │
│  DateTimeWidgetProvider (AppWidget + Bitmap BG)  │
│  NotificationIconService (Persistent Notif)      │
│  FloatingBarService (Overlay ForegroundService)  │
│  TimeTickService (ACTION_TIME_TICK receiver)     │
│  BootReceiver (BOOT_COMPLETED)                   │
└─────────────────────────────────────────────────┘
```

## Key Files

```
date_time_widget/
├── lib/
│   ├── main.dart                    # App entry, DI, Sentry init
│   ├── models/
│   │   ├── clock_config.dart        # Core config (10 fields)
│   │   ├── preset.dart              # Preset model
│   │   ├── presets.dart             # 8 built-in presets
│   │   ├── reward_state.dart        # Daily reward tracking
│   │   ├── widget_config.dart       # Widget size mapping
│   │   └── widget_design.dart       # Design model (clock + background)
│   ├── screens/
│   │   ├── home_screen.dart         # Main screen + deep link
│   │   ├── editor_screen.dart       # Customize clock + background
│   │   ├── presets_screen.dart      # Grid of presets
│   │   ├── settings_screen.dart     # IAP + About
│   │   ├── crop_screen.dart         # Image crop for background
│   │   └── my_designs_screen.dart   # Saved designs CRUD
│   ├── widgets/
│   │   ├── clock_preview.dart       # Live clock + background display
│   │   ├── preset_card.dart         # Preset grid card
│   │   └── ad_banner.dart           # AdMob banner
│   ├── services/
│   │   ├── storage_service.dart     # SharedPreferences CRUD
│   │   ├── ads_service.dart         # AdMob Banner + Rewarded
│   │   ├── iap_service.dart         # In-app purchase
│   │   ├── reward_service.dart      # Daily reward logic
│   │   ├── notification_service.dart# Flutter→Native bridge
│   │   ├── widget_bridge.dart       # Flutter→Widget bridge
│   │   ├── floating_bar_bridge.dart # Flutter→Overlay bridge
│   │   ├── design_storage_service.dart # My Designs CRUD
│   │   └── share_service.dart       # Render + share PNG
│   └── utils/
│       ├── date_formatter.dart      # Time/date/day formatting
│       ├── constants.dart           # Ad unit IDs, enableAds/testAds flags
│       └── image_utils.dart         # Resize, crop, bitmap operations
├── android/app/src/main/kotlin/io/photoclock/widget/
│   ├── MainActivity.kt              # MethodChannel hub
│   ├── DateTimeWidgetProvider.kt    # Home screen widget + bitmap BG
│   ├── NotificationIconService.kt   # Persistent notification
│   ├── FloatingBarService.kt        # Overlay foreground service
│   ├── TimeTickService.kt           # ACTION_TIME_TICK receiver
│   └── BootReceiver.kt              # Reboot recovery
├── android/app/src/main/res/
│   ├── layout/widget_2x1.xml        # Widget layouts (FrameLayout + ImageView)
│   ├── layout/widget_3x1.xml
│   ├── layout/widget_4x1.xml
│   ├── layout/widget_4x2.xml
│   └── xml/file_paths.xml           # FileProvider paths (legacy, may remove)
└── test/                            # 91 unit tests
```

## Packages Used

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Local config persistence |
| `google_mobile_ads` | AdMob banner + rewarded |
| `in_app_purchase` | Remove Ads IAP |
| `flutter_local_notifications` | Notification icon |
| `permission_handler` | Runtime permissions |
| `image_picker` | Gallery image selection |
| `image_cropper` | Image crop for background |
| `path_provider` | App documents directory |
| `share_plus` | System share sheet |
| `sentry_flutter` | Error tracking |
