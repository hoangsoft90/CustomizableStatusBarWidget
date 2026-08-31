# Flutter Services

## StorageService (`lib/services/storage_service.dart`)

Wraps `SharedPreferences` for ClockConfig persistence.

**Methods:**
- `StorageService.create()` — async factory, loads SharedPreferences
- `loadConfig()` → `ClockConfig` — reads JSON from key `"clock_config"`, falls back to defaults
- `saveConfig(ClockConfig)` → `bool` — writes JSON, returns success
- `clearAll()` — removes saved config (test helper)

**Key pattern:** Always reads fresh from SharedPreferences (no cached instance).

## AdsService (`lib/services/ads_service.dart`)

Manages AdMob: Banner creation, Rewarded preload/show, daily preset unlock.

**Constructor:** `AdsService(StorageService storage, RewardService reward)`

**Methods:**
- `static init()` — initializes MobileAds SDK
- `createBanner()` → `BannerAd` — auto-loads, caller manages lifecycle
- `showBanners` → `bool` — `!isPremium`
- `preloadRewarded()` — loads RewardedAd (skipped if no remaining unlocks)
- `showRewardedAd()` → `Future<bool>` — shows ad, returns true if earned
- `unlockPreset(context, presetId, config, {isFreePreset})` → `Future<bool>` — full unlock flow with dialog
- `dispose()` — cleanup

**Race condition fix:** `fullScreenContentCallback` set BEFORE `ad.show()`.

**Daily unlock flow:**
1. Check `canUsePreset()` → if already usable, return true
2. Check `remainingUnlocksToday()` → if 0, show message, return false
3. Show dialog "Watch a short ad to use this preset today?"
4. Show rewarded ad
5. On earned → `rewardService.unlockToday(presetId)`

## IapService (`lib/services/iap_service.dart`)

Manages "Remove Ads & Unlock All" one-time purchase.

**Product ID:** `remove_ads_unlock_all`

**Methods:**
- `init()` — listens to purchase stream, queries product details
- `buy()` → `Future<bool>` — shows Google Play billing dialog
- `restore()` → `Future<bool>` — restores previous purchases
- `isPremium` → `bool` — reads from storage
- `dispose()` — cancels stream

**`_markPremium()`:** Only sets `isPremium: true` (no longer sets `unlockedPresets`).

## RewardService (`lib/services/reward_service.dart`)

Daily reward entitlement for preset unlocking.

**Constructor:** `RewardService(SharedPreferences prefs)`

**Methods:**
- `resetIfNewDay()` — resets state if date changed
- `canUsePreset(id, {isPremium, isFreePreset})` → `bool`
- `remainingUnlocksToday()` → `int` (0-2)
- `unlockToday(presetId)` → `Future<bool>` — records unlock, reads fresh state

**Business rules:**
- Free preset → always true
- Premium → always true
- Already unlocked today → true
- Remaining unlocks > 0 → true (ad will be shown)
- No remaining → false

## WidgetBridge (`lib/services/widget_bridge.dart`)

Flutter → Native bridge for home screen widget.

**Methods:**
- `static updateWidgets({String? configJson})` — sends config to all widget instances

## NotificationService (`lib/services/notification_service.dart`)

Flutter → Native bridge for notification icon.

**Methods:**
- `static start()` / `stop()` / `update()` / `saveConfig(json)`

## FloatingBarBridge (`lib/services/floating_bar_bridge.dart`)

Flutter → Native bridge for floating bar overlay.

**Methods:**
- `static start()` / `stop()` / `update({String? configJson})`
