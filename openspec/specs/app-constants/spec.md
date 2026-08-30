# App Constants & Ad Mode

## Purpose

Centralizes app-wide constants: AdMob ad unit IDs (test vs production), IAP product ID, and app metadata. The `testAds` flag controls which set of ad IDs is used.

## Requirements

### R1: testAds flag

`AppConstants.testAds` is a compile-time `const bool`. When `true`, all ad unit ID getters return test IDs. When `false`, they return production IDs.

**Scenario: Default is test mode**
- Given no code change
- Then `AppConstants.testAds == true`
- Reference: `lib/utils/constants.dart:10`

### R2: Ad unit ID routing

Four getter methods route to test or production IDs based on `testAds`.

| Getter | Test ID | Purpose |
|--------|---------|---------|
| `bannerAdUnitId` | `ca-app-pub-3940256099942544/6300978111` | Adaptive banner |
| `rewardedAdUnitId` | `ca-app-pub-3940256099942544/5224354917` | Rewarded video |
| `interstitialAdUnitId` | `ca-app-pub-3940256099942544/1033173712` | Interstitial |
| `appOpenAdUnitId` | `ca-app-pub-3940256099942544/9257395921` | App open |

**Scenario: testAds=true returns Google test IDs**
- Given `AppConstants.testAds == true`
- When `AppConstants.bannerAdUnitId` is read
- Then it equals `'ca-app-pub-3940256099942544/6300978111'`
- Reference: `lib/utils/constants.dart:14-23`

**Scenario: Production IDs are placeholder**
- Given `AppConstants.testAds == false`
- When `AppConstants.bannerAdUnitId` is read
- Then it equals `'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'` (placeholder)
- Reference: `lib/utils/constants.dart:26-29`

### R3: IAP product ID

`removeAdsProductId` is a string constant matching the Google Play Console product ID.

**Scenario: Product ID value**
- Given `AppConstants.removeAdsProductId`
- Then it equals `'remove_ads_unlock_all'`
- Reference: `lib/utils/constants.dart:32`

### R4: App metadata

`appName` and `appVersion` are string constants.

**Scenario: App info**
- Given `AppConstants.appName`
- Then it equals `'Date & Time Widget'`
- Given `AppConstants.appVersion`
- Then it equals `'1.0.0'`
- Reference: `lib/utils/constants.dart:35-36`

## Need to clear

1. **Production ad IDs are placeholder `XXXXXXXXXX`** — app will crash or show no ads if `testAds` is set to `false` without replacing these first. No compile-time warning.
