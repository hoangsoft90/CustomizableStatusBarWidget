# IAP Service

## Purpose

Manages the "Remove Ads & Unlock All" one-time, non-consumable in-app purchase via `in_app_purchase` package. After purchase: `isPremium = true`, all banners hidden, no rewarded prompts. Supports restore on reinstall.

## Requirements

### R1: Initialization

`IapService.init()` listens to `purchaseStream`, checks store availability, and queries product details.

**Scenario: Store available**
- Given the device has Google Play Store
- When `init()` completes
- Then `_product` is populated with product details
- Reference: `lib/services/iap_service.dart:28-42`

**Scenario: Store not available**
- Given the device has no Play Store (e.g. emulator without GMS)
- When `init()` completes
- Then `_product` is null and a log message is emitted
- Reference: `lib/services/iap_service.dart:36-38`

### R2: Buy flow

`buy()` shows the Google Play billing dialog. Returns `true` if purchase completed.

**Scenario: Successful purchase**
- Given `_product` is loaded and `isPremium == false`
- When `buy()` is called and user completes purchase
- Then `_handlePurchase` sets `isPremium = true`
- And the purchase is acknowledged via `completePurchase`
- Reference: `lib/services/iap_service.dart:48-56`

**Scenario: Already premium**
- Given `isPremium == true`
- When `buy()` is called
- Then it returns `true` immediately
- Reference: `lib/services/iap_service.dart:49`

### R3: Restore flow

`restore()` calls `_iap.restorePurchases()`. The stream handler processes restored purchases.

**Scenario: Restore finds previous purchase**
- Given a previous purchase exists on the account
- When `restore()` is called
- Then `_onPurchaseUpdate` processes the restored purchase
- And `isPremium` becomes `true`
- Reference: `lib/services/iap_service.dart:59-62`

### R4: Purchase handler

`_handlePurchase` processes purchases: if status is `purchased` or `restored` and productID matches, calls `_markPremium()`. Always calls `completePurchase` if `pendingCompletePurchase`.

**Scenario: Purchase status purchased**
- Given a purchase with `status: PurchaseStatus.purchased` and matching `productID`
- When `_handlePurchase` runs
- Then `_markPremium()` is called
- And `_iap.completePurchase(purchase)` is called
- Reference: `lib/services/iap_service.dart:70-78`

### R5: _markPremium sets isPremium only

`_markPremium()` sets `isPremium: true`. It no longer sets `unlockedPresets` — reward state is tracked separately in `RewardService`.

Note: In plan3_final.md Task B, the `unlockedPresets: allPresetIds` line was removed. Premium users bypass all lock checks via `isPremium` flag alone.

**Scenario: Mark premium**
- When `_markPremium()` is called
- Then config has `isPremium: true`
- And the config does NOT contain `unlockedPresets` (field removed from ClockConfig)
- Reference: `lib/services/iap_service.dart:81-88`

**Scenario: Idempotent**
- Given `isPremium` is already `true`
- When `_markPremium()` is called
- Then nothing changes (early return)
- Reference: `lib/services/iap_service.dart:82`

### R6: Stream leak prevention

`dispose()` cancels the purchase stream subscription. Called from `WidgetsBindingObserver.didChangeAppLifecycleState(detached)`.

**Scenario: App detached**
- Given the app is being killed
- When `didChangeAppLifecycleState(detached)` fires
- Then `iapService.dispose()` is called
- Reference: `lib/main.dart:48-50`
