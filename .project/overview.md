# Project Overview

## Purpose

**Date & Time Widget** là app Android giúp user thấy ngày, giờ trên 3 lớp:
1. **Home Screen Widget** — widget đặt trên màn hình chính
2. **Notification Icon** — icon số ngày trong notification bar
3. **Floating Bar** — thanh nổi đặt ngay dưới status bar (optional)

**Positioning:** "Always see the day, date & time — home widget + status bar icon."

**KHÔNG hứa:** "thay đổi status bar", "giống Samsung", "status bar mod" — dễ gây review 1 sao.

## Tech Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| **Framework** | Flutter | latest stable (SDK ^3.13.1) |
| **Language (App)** | Dart | 3.13.1+ |
| **Language (Native)** | Kotlin | JVM 17 |
| **Target SDK** | Android API 36 | Google Play requirement từ 31/8/2026 |
| **Min SDK** | From Flutter default | — |
| **Build** | Gradle (Kotlin DSL) | AGP from Flutter plugin |
| **CI/CD** | GitHub Actions | flutter-action + Java 17 |

## Dependencies (Whitelist)

| Package | Purpose |
|---------|---------|
| `shared_preferences` | Local config persistence |
| `google_mobile_ads` | Banner + Rewarded ads |
| `in_app_purchase` | Remove Ads IAP |
| `flutter_local_notifications` | Notification scheduling |
| `permission_handler` | Runtime permission requests |

**KHÔNG dùng:** Firebase, backend, cloud sync, account system.

## Monetization

| Revenue Stream | Status | Notes |
|----------------|--------|-------|
| **AdMob Banner** | ✅ Integrated | Home + Settings screens, test mode |
| **AdMob Rewarded** | ✅ Integrated | Unlock premium presets daily |
| **IAP Remove Ads** | ✅ Integrated | One-time purchase, non-consumable |
| **Interstitial** | P2 only | Chỉ sau khi Save config |

**Hard rule:** TUYỆT ĐỐI KHÔNG ads trên Widget / Notification / Floating Bar.

## Platform

| | |
|---|---|
| **Primary** | Android only (Flutter + Native Kotlin) |
| **iOS** | Chưa hỗ trợ (cần rewrite native layer) |
| **App name store** | Date & Time Widget |
| **Category** | Tools |
| **Tags** | clock, widget, home screen, date, time |

## Privacy & Compliance

| Item | Status | URL |
|------|--------|-----|
| Privacy Policy | ✅ | https://hoangsoft90.github.io/CustomizableStatusBarWidget/ |
| app-ads.txt | ✅ | https://all-my-apps-5d52f.web.app/app-ads.txt |
| AdMob test mode | ✅ | `testAds = true` in constants.dart |
| Data Safety form | ⬜ Pending | Play Console |
| Content Rating | ⬜ Pending | Play Console |
