/// App-wide constants and configuration.
///
/// Set [testAds] to `true` during development to use AdMob test IDs.
/// Set to `false` ONLY when publishing to Play Store with live ad unit IDs.
class AppConstants {
  // ── Ad Mode ──────────────────────────────────────────────
  /// When `true`, uses AdMob test ad unit IDs.
  /// When `false`, uses production ad unit IDs (must be set before release).
  static const bool testAds = true;

  // ── Ad Unit IDs — Test (dev only) ────────────────────────
  // https://developers.google.com/admob/android/test-ads
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';

  // ── Ad Unit IDs — Production (set before release) ────────
  // TODO: Replace these with your actual AdMob ad unit IDs before publishing
  static const String _prodBannerId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodRewardedId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodInterstitialId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';
  static const String _prodAppOpenId = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX';

  // ── Public getters ───────────────────────────────────────
  static String get bannerAdUnitId => testAds ? _testBannerId : _prodBannerId;
  static String get rewardedAdUnitId => testAds ? _testRewardedId : _prodRewardedId;
  static String get interstitialAdUnitId => testAds ? _testInterstitialId : _prodInterstitialId;
  static String get appOpenAdUnitId => testAds ? _testAppOpenId : _prodAppOpenId;

  // ── IAP Product ID ───────────────────────────────────────
  static const String removeAdsProductId = 'remove_ads_unlock_all';

  // ── App Info ─────────────────────────────────────────────
  static const String appName = 'Date & Time Widget';
  static const String appVersion = '1.0.0';
}
