# AdBanner Widget

## Purpose

Displays an AdMob adaptive banner. Returns `SizedBox.shrink()` when `show` is `false` (premium users). Manages BannerAd lifecycle internally.

## Requirements

### R1: Conditional rendering

When `show == false`, renders `SizedBox.shrink()` — no ad is loaded or displayed.

**Scenario: Premium user sees no banner**
- Given `show: false`
- When AdBanner builds
- Then the widget is `SizedBox.shrink()`
- Reference: `lib/widgets/ad_banner.dart:55-57`

### R2: Auto-load on mount

When `show == true` during `initState`, `_loadAd()` is called immediately.

**Scenario: Banner loads on creation**
- Given `show: true`
- When AdBanner is created
- Then a BannerAd is created with `AppConstants.bannerAdUnitId` and `.load()` is called
- Reference: `lib/widgets/ad_banner.dart:34-36`

### R3: Reload on show toggle

When `show` changes from `false` to `true` (via `didUpdateWidget`), the ad is reloaded. When changing from `true` to `false`, the ad is disposed.

**Scenario: Show toggled on**
- Given `show` was `false`, now `true`
- When `didUpdateWidget` fires
- Then `_loadAd()` is called
- Reference: `lib/widgets/ad_banner.dart:26-28`

**Scenario: Show toggled off**
- Given `show` was `true`, now `false`
- When `didUpdateWidget` fires
- Then `_ad?.dispose()` is called and state is reset
- Reference: `lib/widgets/ad_banner.dart:29-32`

### R4: Dispose on unmount

When the widget is removed from the tree, `_ad?.dispose()` is called.

**Scenario: Widget disposed**
- Given a BannerAd is loaded
- When AdBanner is removed from widget tree
- Then `_ad.dispose()` is called
- Reference: `lib/widgets/ad_banner.dart:51-54`

### R5: Renders AdWidget when loaded

When the ad is loaded and `show` is true, renders a `google_mobile_ads.AdWidget` with the ad's dimensions.

**Scenario: Loaded ad renders**
- Given `_isLoaded == true` and `_ad != null`
- When AdBanner builds
- Then `AdWidget(ad: _ad!)` is rendered in a Container sized to the ad
- Reference: `lib/widgets/ad_banner.dart:59-65`
