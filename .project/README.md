# Date & Time Widget — Knowledge Items

> Auto-generated knowledge base for the **CustomizableStatusBarWidget** project.
> Last updated: 2026-08-30

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
| **App name** | Date & Time Widget |
| **Package ID** | `com.example.date_time_widget` |
| **Version** | 1.0.0+1 (chưa release) |
| **Repo** | https://github.com/hoangsoft90/CustomizableStatusBarWidget |
| **Build** | GitHub Actions (Flutter latest stable + Java 17) |
| **Target** | Android (SDK 36, minSdk from Flutter) |
| **Contact** | haibasoftware@gmail.com |

## Architecture at a Glance

```
┌─────────────────────────────────────────────────┐
│                   FLUTTER                        │
│  ClockConfig ←→ StorageService (SharedPreferences)│
│       ↕ MethodChannel (JSON)                     │
├─────────────────────────────────────────────────┤
│               NATIVE ANDROID (Kotlin)            │
│  DateTimeWidgetProvider (AppWidget)              │
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
│   ├── main.dart                    # App entry, DI
│   ├── models/
│   │   ├── clock_config.dart        # Core config (10 fields)
│   │   ├── preset.dart              # Preset model
│   │   ├── presets.dart             # 8 built-in presets
│   │   ├── reward_state.dart        # Daily reward tracking
│   │   └── widget_config.dart       # Widget size mapping
│   ├── screens/
│   │   ├── home_screen.dart         # Main screen + deep link
│   │   ├── editor_screen.dart       # Customize clock
│   │   ├── presets_screen.dart      # Grid of presets
│   │   └── settings_screen.dart     # IAP + About
│   ├── widgets/
│   │   ├── clock_preview.dart       # Live clock display
│   │   ├── preset_card.dart         # Preset grid card
│   │   └── ad_banner.dart           # AdMob banner
│   ├── services/
│   │   ├── storage_service.dart     # SharedPreferences CRUD
│   │   ├── ads_service.dart         # AdMob Banner + Rewarded
│   │   ├── iap_service.dart         # In-app purchase
│   │   ├── reward_service.dart      # Daily reward logic
│   │   ├── notification_service.dart# Flutter→Native bridge
│   │   ├── widget_bridge.dart       # Flutter→Widget bridge
│   │   └── floating_bar_bridge.dart # Flutter→Overlay bridge
│   └── utils/
│       ├── date_formatter.dart      # Time/date/day formatting
│       └── constants.dart           # Ad unit IDs, test_ads flag
├── android/app/src/main/kotlin/.../
│   ├── MainActivity.kt              # MethodChannel hub
│   ├── DateTimeWidgetProvider.kt    # Home screen widget
│   ├── NotificationIconService.kt   # Persistent notification
│   ├── FloatingBarService.kt        # Overlay foreground service
│   ├── TimeTickService.kt           # ACTION_TIME_TICK receiver
│   └── BootReceiver.kt              # Reboot recovery
└── test/                            # 91 unit tests
```
