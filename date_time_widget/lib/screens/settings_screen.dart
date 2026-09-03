import 'dart:async';

import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../services/ads_service.dart';
import '../services/iap_service.dart';
import '../services/storage_service.dart';
import '../services/widget_bridge.dart';
import '../utils/constants.dart';
import '../widgets/ad_banner.dart';

/// Settings screen with IAP "Remove Ads & Unlock All".
///
/// Banner is placed at the very bottom, never overlapping content (plan §3).
class SettingsScreen extends StatefulWidget {
  final StorageService storage;
  final AdsService adsService;
  final IapService iapService;

  const SettingsScreen({
    super.key,
    required this.storage,
    required this.adsService,
    required this.iapService,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const bool kShowPremiumUi = false;
  late ClockConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.storage.loadConfig();
    // Periodically refresh config in case IAP purchase completes in background
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _refreshConfig(),
    );
  }

  late Timer _refreshTimer;

  void _refreshConfig() {
    final fresh = widget.storage.loadConfig();
    if (fresh != _config && mounted) {
      setState(() => _config = fresh);
      WidgetBridge.updateWidgets();
    }
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  // ── IAP ───────────────────────────────────────────────────
  String _buyButtonText(ProductDetails? product) {
    if (_config.isPremium) return 'Premium Active';
    if (product != null) return 'Buy — ${product.price}';
    return 'Buy Premium';
  }

  Future<void> _onBuyPremium() async {
    if (_config.isPremium) return;

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final success = await widget.iapService.buy();

    if (mounted) Navigator.of(context).pop(); // dismiss loading

    if (success && mounted) {
      setState(() => _config = widget.storage.loadConfig());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Premium activated! All ads removed.')),
      );
    }
  }

  Future<void> _onRestore() async {
    final restored = await widget.iapService.restore();
    if (restored && mounted) {
      setState(() => _config = widget.storage.loadConfig());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase restored successfully.')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No previous purchase found.')),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isPremium = _config.isPremium;
    final product = widget.iapService.product;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Premium section (hidden until IAP is live) ──
                if (kShowPremiumUi)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isPremium
                                    ? Icons.workspace_premium
                                    : Icons.remove_circle_outline,
                                color: isPremium ? Colors.amber : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isPremium
                                      ? 'Premium Active'
                                      : 'Remove Ads & Unlock All',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (isPremium)
                            Text(
                              'Thank you! All ads are removed and every preset '
                              'is unlocked.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            )
                          else ...[
                            Text(
                              '• Remove all banners\n'
                              '• No more "watch ad" prompts\n'
                              '• Unlock every preset instantly',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _onBuyPremium,
                                child: Text(_buyButtonText(product)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _onRestore,
                                child: const Text('Restore Purchase'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // ── About ──
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    subtitle: Text('${AppConstants.appName} v${AppConstants.appVersion}'),
                  ),
                ),
              ],
            ),
          ),

          // ── Banner (only if not premium) ──
          AdBanner(show: widget.adsService.showBanners),
        ],
      ),
    );
  }
}
