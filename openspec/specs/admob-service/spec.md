# AdMob Service

## Purpose

Manages AdMob ads: Adaptive Banner creation, Rewarded Video preload/show, and preset unlock flow via rewarded ad. All ad unit IDs route through AppConstants (test vs production).

## Requirements

### R1: MobileAds initialization

`AdsService.init()` calls `MobileAds.instance.initialize()` once at app start.

**Scenario: Init**
- When `AdsService.init()` is awaited
- Then `MobileAds.instance` is initialized
- Reference: `lib/services/ads_service.dart:24-26`

### R2: Banner creation

`createBanner()` creates a `BannerAd` with `AdSize.banner` and auto-loads it. Handles failure by disposing the ad.

**Scenario: Banner created**
- When `adsService.createBanner()` is called
- Then a `BannerAd` is returned with `adUnitId: AppConstants.bannerAdUnitId`
- And the ad starts loading via `.load()`
- Reference: `lib/services/ads_service.dart:32-42`

### R3: Rewarded ad preload + show

`preloadRewarded()` loads a `RewardedAd`. `showRewardedAd()` shows it and returns `true` if the user watched to completion.

**Scenario: Preload success**
- Given `isPremium == false` and `remainingUnlocksToday() > 0`
- When `preloadRewarded()` completes
- Then `_rewardedAd` is non-null (if ad was available)
- Reference: `lib/services/ads_service.dart:50-62`

**Scenario: Preload skipped when no unlocks remaining**
- Given `remainingUnlocksToday() == 0`
- When `preloadRewarded()` is called
- Then it returns immediately without loading an ad
- Reference: `lib/services/ads_service.dart:52-53`

**Scenario: Show and earn reward**
- Given a preloaded rewarded ad
- When `showRewardedAd()` is called and user watches to completion
- Then the method returns `true`
- Reference: `lib/services/ads_service.dart:68-73`

**Scenario: Ad not available — load+show fallback**
- Given `_rewardedAd == null`
- When `showRewardedAd()` is called
- Then it attempts `preloadRewarded()` then `_showAndEarn(fresh)`
- Reference: `lib/services/ads_service.dart:64-71`

### R4: Race condition prevention

`fullScreenContentCallback` is assigned BEFORE `ad.show()` to prevent a race with fast-dismiss ads.

**Scenario: Callback assignment order**
- Given a loaded RewardedAd
- When `_showAndEarn` is called
- Then `ad.fullScreenContentCallback` is set before `ad.show()` is invoked
- Reference: `lib/services/ads_service.dart:77-88`

### R5: Premium bypass

If `isPremium == true`, all ad methods return immediately without showing ads.

**Scenario: Premium user — no ads**
- Given `isPremium == true`
- When `showRewardedAd()` is called
- Then it returns `false` immediately
- Reference: `lib/services/ads_service.dart:57-58`

### R6: showBanners flag

`showBanners` returns `true` when not premium, `false` when premium.

**Scenario: Free user**
- Given `isPremium == false`
- Then `showBanners == true`
- Reference: `lib/services/ads_service.dart:46`

### R7: unlockPreset flow (daily reward)

Full flow: check remaining unlocks → show confirmation dialog ("today" wording) → showRewarded ad → if earned, call `rewardService.unlockToday(presetId)`. If no remaining unlocks, stops preload and shows message.

Note: In plan3_final.md Task B, this was changed from permanent unlock (`unlockedPresets`) to daily unlock via `RewardService`.

**Scenario: Unlock success**
- Given user taps a locked preset
- And `remainingUnlocksToday() > 0`
- And user watches ad to completion
- When `unlockPreset` returns
- Then `rewardService.unlockToday(presetId)` was called
- And the preset is usable for the rest of today
- Reference: `lib/services/ads_service.dart:100-142`

**Scenario: No remaining unlocks**
- Given `remainingUnlocksToday() == 0`
- When user taps a locked preset
- Then a SnackBar "No more unlocks today. Try again tomorrow." is shown
- And the ad is not shown
- Reference: `lib/services/ads_service.dart:113-121`

**Scenario: Ad not available**
- Given user taps "Watch" but ad fails to load
- When `showRewardedAd` returns `false`
- Then a SnackBar "Ad not available. Please try again later." is shown
- Reference: `lib/services/ads_service.dart:133-139`

**Scenario: Dialog says "today" not "forever"**
- Given user taps a locked preset with remaining unlocks
- When the confirmation dialog appears
- Then the text reads "Watch a short ad to use this preset today?"
- And it shows the remaining unlocks count
- Reference: `lib/services/ads_service.dart:124-131`

### R8: Cleanup

`dispose()` disposes the cached rewarded ad and sets it to null.

**Scenario: Dispose**
- When `adsService.dispose()` is called
- Then `_rewardedAd?.dispose()` is called and `_rewardedAd` becomes null
- Reference: `lib/services/ads_service.dart:147-150`
