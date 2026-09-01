# App Constants & Ad Mode

## Purpose

Centralizes app-wide constants: AdMob ad unit IDs (test vs production), IAP product ID, and app metadata. Two compile-time flags control ad behavior: `enableAds` (master switch) and `testAds` (test vs production IDs).

## Requirements

### R1: enableAds flag (master switch)

`AppConstants.enableAds` is a compile-time `const bool`. When `false`, all ads are completely disabled — no `MobileAds.init()`, no banner load, no rewarded preload, no unlock dialog. When `true`, ads are active and `testAds` determines which ad unit IDs to use.

**Scenario: Ads disabled by default**
- Given no code change
- Then `AppConstants.enableAds == false`
- Reference: `lib/utils/constants.dart:10`

**Scenario: Enable ads**
- Given `AppConstants.enableAds = true`
- When `AppConstants.adsEnabled` is read
- Then it returns `true`
- Reference: `lib/utils/constants.dart:33`

### R2: testAds flag

`AppConstants.testAds` is a compile-time `const bool`. When `true`, all ad unit ID getters return Google test IDs (safe for dev). When `false`, they return production IDs. Ignored when `enableAds == false`.

**Scenario: testAds=false returns production IDs**
- Given `AppConstants.enableAds == true` and `AppConstants.testAds == false`
- When `AppConstants.bannerAdUnitId` is read
- Then it equals `'ca-app-pub-6917313063209470/1100373335'` (production)
- Reference: `lib/utils/constants.dart:14`

### R3: Ad unit ID routing

Four getter methods route to test or production IDs based on `testAds`.

| Getter | Test ID | Production ID | Purpose |
|--------|---------|---------------|---------|
| `bannerAdUnitId` | `ca-app-pub-3940256099942544/6300978111` | `ca-app-pub-6917313063209470/1100373335` | Adaptive banner |
| `rewardedAdUnitId` | `ca-app-pub-3940256099942544/5224354917` | `ca-app-pub-6917313063209470/5224354917` | Rewarded video |
| `interstitialAdUnitId` | `ca-app-pub-3940256099942544/1033173712` | `ca-app-pub-6917313063209470/6447963584` | Interstitial |
| `appOpenAdUnitId` | `ca-app-pub-3940256099942544/9257395921` | `ca-app-pub-6917313063209470/XXXXXXXXXX` | App open (not yet available) |

**Scenario: testAds=true returns Google test IDs**
- Given `AppConstants.testAds == true`
- When `AppConstants.bannerAdUnitId` is read
- Then it equals `'ca-app-pub-3940256099942544/6300978111'`
- Reference: `lib/utils/constants.dart:18-23`

**Scenario: testAds=false returns real production IDs**
- Given `AppConstants.testAds == false`
- When `AppConstants.bannerAdUnitId` is read
- Then it equals `'ca-app-pub-6917313063209470/1100373335'`
- Reference: `lib/utils/constants.dart:26-29`

### R4: IAP product ID

`removeAdsProductId` is a string constant matching the Google Play Console product ID.

**Scenario: Product ID value**
- Given `AppConstants.removeAdsProductId`
- Then it equals `'remove_ads_unlock_all'`
- Reference: `lib/utils/constants.dart:36`

### R5: App metadata

`appName` and `appVersion` are string constants.

**Scenario: App info**
- Given `AppConstants.appName`
- Then it equals `'Date & Time Widget'`
- Given `AppConstants.appVersion`
- Then it equals `'1.0.0'`
- Reference: `lib/utils/constants.dart:39-40`

## Need to clear

1. **`appOpenAdUnitId` production ID is still placeholder `XXXXXXXXXX`** — App Open ads are not yet integrated, so this is unused. Will be updated when App Open ads are added.
