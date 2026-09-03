/// App-wide constants and configuration.
///
/// Ad flags:
/// - [enableAds]: master switch — `false` = no ads anywhere in the app.
/// - [testAds]: `true` = AdMob test IDs (dev), `false` = production IDs.
/// When [enableAds] is `false`, [testAds] is ignored.
class AppConstants {
  // ── Ad Flags ─────────────────────────────────────────────
  /// Master switch for all ads. Set `false` to disable completely.
  static const bool enableAds = true;

  /// When `true`, uses AdMob test ad unit IDs (safe for dev).
  /// When `false`, uses production ad unit IDs.
  /// Ignored when [enableAds] is `false`.
  static const bool testAds = false;

  // ── Ad Unit IDs — Test (dev only) ────────────────────────
  // https://developers.google.com/admob/android/test-ads
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/9257395921';

  // ── Ad Unit IDs — Production ─────────────────────────────
  static const String _prodBannerId = 'ca-app-pub-6917313063209470/1100373335';
  static const String _prodRewardedId = 'ca-app-pub-6917313063209470/5224354917';
  static const String _prodInterstitialId = 'ca-app-pub-6917313063209470/6447963584';
  static const String _prodAppOpenId = 'ca-app-pub-6917313063209470/XXXXXXXXXX';

  // ── Public getters ───────────────────────────────────────
  /// Returns `false` if ads are disabled, otherwise respects testAds flag.
  static bool get adsEnabled => enableAds;

  static String get bannerAdUnitId => testAds ? _testBannerId : _prodBannerId;
  static String get rewardedAdUnitId => testAds ? _testRewardedId : _prodRewardedId;
  static String get interstitialAdUnitId => testAds ? _testInterstitialId : _prodInterstitialId;
  static String get appOpenAdUnitId => testAds ? _testAppOpenId : _prodAppOpenId;

  // ── IAP Product ID ───────────────────────────────────────
  static const String removeAdsProductId = 'remove_ads_unlock_all';

  // ── App Info ─────────────────────────────────────────────
  static const String appName = 'Date & Time Widget';
  static const String appVersion = '1.0.1';
}
