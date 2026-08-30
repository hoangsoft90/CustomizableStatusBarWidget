import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Displays an AdMob adaptive banner.
///
/// Returns `SizedBox.shrink()` when [show] is `false` (premium users).
/// Caller must keep a reference to call `dispose()` on the [BannerAd].
class AdBanner extends StatefulWidget {
  /// Whether to show the banner.  Pass `adsService.showBanners`.
  final bool show;

  const AdBanner({super.key, required this.show});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void didUpdateWidget(covariant AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _loadAd();
    } else if (!widget.show && oldWidget.show) {
      _ad?.dispose();
      _ad = null;
      _isLoaded = false;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.show) _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // test ID
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show || !_isLoaded || _ad == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      alignment: Alignment.center,
      child: AdWidget(ad: _ad!),
    );
  }
}
