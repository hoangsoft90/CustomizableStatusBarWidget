import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../models/clock_config.dart';
import '../utils/constants.dart';
import 'reward_service.dart';
import 'storage_service.dart';

/// Manages AdMob ads: Adaptive Banner + Rewarded Video.
///
/// - Banner is shown on Home and Settings screens (never on Editor — plan §3).
/// - Rewarded Video is used to unlock premium presets for today's use.
/// - All ads are skipped when `ClockConfig.isPremium == true`.
///
/// Uses **test ad unit IDs** during development.  NEVER use live IDs
/// for testing — risk of Google Play account suspension.
class AdsService {
  final StorageService _storage;
  final RewardService _reward;

  AdsService(this._storage, this._reward);

  bool get _isPremium => _storage.loadConfig().isPremium;

  // ── Initialise ────────────────────────────────────────────

  /// Call once at app start.  Safe to call multiple times.
  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }

  // ── Banner ────────────────────────────────────────────────

  /// Create an adaptive banner [AdWidget].  Caller is responsible for
  /// placing it in the widget tree and calling `dispose()` when done.
  BannerAd createBanner() {
    return BannerAd(
      adUnitId: AppConstants.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner failed: ${error.message}');
          ad.dispose();
        },
      ),
    )..load();
  }

  /// Whether banners should be shown (premium users see no ads).
  bool get showBanners => !_isPremium;

  // ── Rewarded ──────────────────────────────────────────────

  RewardedAd? _rewardedAd;

  /// Pre-load a rewarded ad so it's ready when the user taps "Watch".
  Future<void> preloadRewarded() async {
    if (_isPremium) return;
    // Don't preload if no remaining unlocks
    if (_reward.remainingUnlocksToday() <= 0) return;
    await RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _setRewardedCallbacks(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded load failed: ${error.message}');
          _rewardedAd = null;
        },
      ),
    );
  }

  /// Show the rewarded ad.  Returns `true` if the user watched to
  /// completion (earned reward), `false` otherwise.
  ///
  /// If no ad is loaded yet, attempts to load and show in one step.
  /// If [isPremium], returns `false` immediately (no ads shown).
  Future<bool> showRewardedAd() async {
    if (_isPremium) return false;

    final ad = _rewardedAd;
    if (ad == null) {
      // Try to load + show
      await preloadRewarded();
      final fresh = _rewardedAd;
      if (fresh == null) return false;
      return _showAndEarn(fresh);
    }

    return _showAndEarn(ad);
  }

  Future<bool> _showAndEarn(RewardedAd ad) async {
    var rewardEarned = false;
    final completer = Completer<bool>();

    // Set callbacks BEFORE show() to avoid race with fast-dismiss ads
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        if (!rewardEarned && !completer.isCompleted) {
          completer.complete(false);
        }
        preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        rewardEarned = true;
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future;
  }

  void _setRewardedCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewarded();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
      },
    );
  }

  // ── Unlock preset ─────────────────────────────────────────

  /// Attempt to unlock [presetId] via rewarded ad for today.
  ///
  /// Flow:
  /// 1. Show "Watch a short ad to use this preset today" dialog
  /// 2. User taps "Watch" → showRewardedAd()
  /// 3. If earned → rewardService.unlockToday(presetId)
  /// 4. If not earned (dismissed / failed) → nothing changes
  ///
  /// Returns `true` if the preset was unlocked for today.
  Future<bool> unlockPreset(
    BuildContext context,
    String presetId,
    ClockConfig currentConfig, {
    required bool isFreePreset,
  }) async {
    if (currentConfig.isPremium) return true;
    if (isFreePreset) return true;
    if (_reward.canUsePreset(presetId,
        isPremium: currentConfig.isPremium, isFreePreset: isFreePreset)) {
      // Already unlocked today
      return true;
    }

    final remaining = _reward.remainingUnlocksToday();
    if (remaining <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No more unlocks today. Try again tomorrow.'),
          ),
        );
      }
      return false;
    }

    // Step 1: Confirmation dialog
    final watch = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.lock_open, size: 36),
        title: const Text('Unlock Preset'),
        content: Text(
          'Watch a short ad to use this preset today?\n'
          '$remaining unlock${remaining == 1 ? '' : 's'} remaining today.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Watch'),
          ),
        ],
      ),
    );

    if (watch != true) return false;

    // Step 2: Show ad
    final earned = await showRewardedAd();

    // Step 3: Record unlock in RewardService (reads fresh state from storage)
    if (earned) {
      return await _reward.unlockToday(presetId);
    }

    // Ad not available or dismissed — give user feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad not available. Please try again later.'),
        ),
      );
    }

    return false;
  }

  // ── Cleanup ───────────────────────────────────────────────

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
