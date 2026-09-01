# AdMob Service

## Purpose

Manages AdMob ads: Adaptive Banner creation, Rewarded Video preload/show, and preset unlock flow via rewarded ad. All ad unit IDs route through AppConstants (test vs production). Respects `enableAds` master switch — when disabled, all methods short-circuit.

## Requirements

### R0: enableAds guard — all methods short-circuit

Every public method in AdsService checks `AppConstants.enableAds` first. When `false`, no ad SDK initialization, no ad loading, no ad showing.

**Scenario: Ads disabled — init is no-op**
- Given `AppConstants.enableAds == false`
- When `AdsService.init()` is called
- Then `MobileAds.instance.initialize()` is NOT called
- Reference: `lib/services/ads_service.dart:24-27`

**Scenario: Ads disabled — banner returns null**
- Given `AppConstants.enableAds == false`
- When `adsService.createBanner()` is called
- Then it returns `null` immediately
- Reference: `lib/services/ads_service.dart:32-33`

**Scenario: Ads disabled — rewarded returns false**
- Given `AppConstants.enableAds == false`
- When `showRewardedAd()` is called
- Then it returns `false` immediately
- Reference: `lib/services/ads_service.dart:57-59`

**Scenario: Ads disabled — showBanners is false**
- Given `AppConstants.enableAds == false`
- Then `showBanners == false`
- Reference: `lib/services/ads_service.dart:46-48`

**Scenario: Ads disabled — unlockPreset shows no ad**
- Given `AppConstants.enableAds == false`
- When user taps a locked preset
- Then the unlock dialog is NOT shown
- Reference: `lib/services/ads_service.dart:100-103`

### R1: MobileAds initialization

`AdsService.init()` calls `MobileAds.instance.initialize()` once at app start (only when `enableAds == true`).

**Scenario: Init**
- Given `AppConstants.enableAds == true`
- When `AdsService.init()` is awaited
- Then `MobileAds.instance` is initialized
- Reference: `lib/services/ads_service.dart:24-28`

### R2: Banner creation

`createBanner()` creates a `BannerAd` with `AdSize.banner` and auto-loads it. Handles failure by disposing the ad. Returns `null` when ads disabled or premium.

**Scenario: Banner created**
- Given `AppConstants.enableAds == true` and `isPremium == false`
- When `adsService.createBanner()` is called
- Then a `BannerAd` is returned with `adUnitId: AppConstants.bannerAdUnitId`
- And the ad starts loading via `.load()`
- Reference: `lib/services/ads_service.dart:35-45`

### R3: Rewarded ad preload + show

`preloadRewarded()` loads a `RewardedAd`. `showRewardedAd()` shows it and returns `true` if the user watched to completion.

**Scenario: Preload success**
- Given `isPremium == false` and `remainingUnlocksToday() > 0`
- When `preloadRewarded()` completes
- Then `_rewardedAd` is non-null (if ad was available)
- Reference: `lib/services/ads_service.dart:64-76`

**Scenario: Preload skipped when no unlocks remaining**
- Given `remainingUnlocksToday() == 0`
- When `preloadRewarded()` is called
- Then it returns immediately without loading an ad
- Reference: `lib/services/ads_service.dart:66-67`

**Scenario: Show and earn reward**
- Given a preloaded rewarded ad
- When `showRewardedAd()` is called and user watches to completion
- Then the method returns `true`
- Reference: `lib/services/ads_service.dart:82-87`

**Scenario: Ad not available — load+show fallback**
- Given `_rewardedAd == null`
- When `showRewardedAd()` is called
- Then it attempts `preloadRewarded()` then `_showAndEarn(fresh)`
- Reference: `lib/services/ads_service.dart:78-85`

### R4: Race condition prevention

`fullScreenContentCallback` is assigned BEFORE `ad.show()` to prevent a race with fast-dismiss ads.

**Scenario: Callback assignment order**
- Given a loaded RewardedAd
- When `_showAndEarn` is called
- Then `ad.fullScreenContentCallback` is set before `ad.show()` is invoked
- Reference: `lib/services/ads_service.dart:91-102`

### R5: Premium bypass

If `isPremium == true`, all ad methods return immediately without showing ads.

**Scenario: Premium user — no ads**
- Given `isPremium == true`
- When `showRewardedAd()` is called
- Then it returns `false` immediately
- Reference: `lib/services/ads_service.dart:71-73`

### R6: showBanners flag

`showBanners` returns `true` when not premium and ads enabled, `false` when premium or ads disabled.

**Scenario: Free user with ads enabled**
- Given `isPremium == false` and `AppConstants.enableAds == true`
- Then `showBanners == true`
- Reference: `lib/services/ads_service.dart:50-52`

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
- Reference: `lib/services/ads_service.dart:114-156`

**Scenario: No remaining unlocks**
- Given `remainingUnlocksToday() == 0`
- When user taps a locked preset
- Then a SnackBar "No more unlocks today. Try again tomorrow." is shown
- And the ad is not shown
- Reference: `lib/services/ads_service.dart:127-135`

**Scenario: Ad not available**
- Given user taps "Watch" but ad fails to load
- When `showRewardedAd` returns `false`
- Then a SnackBar "Ad not available. Please try again later." is shown
- Reference: `lib/services/ads_service.dart:147-153`

**Scenario: Dialog says "today" not "forever"**
- Given user taps a locked preset with remaining unlocks
- When the confirmation dialog appears
- Then the text reads "Watch a short ad to use this preset today?"
- And it shows the remaining unlocks count
- Reference: `lib/services/ads_service.dart:138-145`

### R8: Cleanup

`dispose()` disposes the cached rewarded ad and sets it to null.

**Scenario: Dispose**
- When `adsService.dispose()` is called
- Then `_rewardedAd?.dispose()` is called and `_rewardedAd` becomes null
- Reference: `lib/services/ads_service.dart:161-164`
