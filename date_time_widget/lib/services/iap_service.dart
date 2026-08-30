import 'dart:async';
import 'dart:developer' as dev;

import 'package:in_app_purchase/in_app_purchase.dart';

import 'storage_service.dart';

/// Manages the "Remove Ads & Unlock All" in-app purchase.
///
/// Product: one-time, non-consumable.
/// After purchase: `isPremium = true`, all banners hidden, no rewarded prompts.
/// Supports restore on reinstall.
class IapService {
  final StorageService _storage;

  IapService(this._storage);

  // ── Product ID (must match Google Play Console) ──────────
  static const productId = 'remove_ads_unlock_all';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  ProductDetails? _product;
  ProductDetails? get product => _product;

  bool get isPremium => _storage.loadConfig().isPremium;

  // ── Initialise ────────────────────────────────────────────

  Future<void> init() async {
    // Listen for purchase updates (including pending / restored)
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => dev.log('IAP stream error: $e'),
    );

    // Check store availability
    final available = await _iap.isAvailable();
    if (!available) {
      dev.log('IAP store not available');
      return;
    }

    // Query product details
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isNotEmpty) {
      _product = response.productDetails.first;
    } else {
      dev.log('IAP product "$productId" not found in store');
    }
  }

  // ── Purchase flow ─────────────────────────────────────────

  /// Start the purchase flow.  Shows the Google Play billing dialog.
  /// Returns `true` if purchase completed successfully.
  Future<bool> buy() async {
    if (isPremium) return true;
    if (_product == null) {
      dev.log('IAP product not loaded');
      return false;
    }

    final params = PurchaseParam(productDetails: _product!);
    // non-consumable → buyNonConsumable
    final success = await _iap.buyNonConsumable(purchaseParam: params);
    return success;
  }

  /// Restore previous purchases (e.g. after reinstall).
  Future<bool> restore() async {
    if (isPremium) return true;
    await _iap.restorePurchases();
    return isPremium; // may have been set by _onPurchaseUpdate
  }

  // ── Purchase update handler ───────────────────────────────

  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    if (purchase.productID != productId) return;

    if (purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored) {
      await _markPremium();
    }

    // Acknowledge / complete the purchase (required by Google)
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  Future<void> _markPremium() async {
    if (isPremium) return; // already marked

    final config = _storage.loadConfig();
    final allPresetIds = [
      'basic1', 'basic2', 'basic3', 'basic4',
      'basic5', 'basic6', 'premium1', 'premium2',
    ];
    final updated = config.copyWith(
      isPremium: true,
      unlockedPresets: allPresetIds,
    );
    await _storage.saveConfig(updated);
    dev.log('IAP: marked as premium, all presets unlocked');
  }

  // ── Cleanup ───────────────────────────────────────────────

  void dispose() {
    _subscription?.cancel();
  }
}
