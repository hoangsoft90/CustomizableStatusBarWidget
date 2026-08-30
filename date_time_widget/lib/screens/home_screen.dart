import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import '../services/ads_service.dart';
import '../services/iap_service.dart';
import '../services/floating_bar_bridge.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../services/widget_bridge.dart';
import '../widgets/ad_banner.dart';
import '../widgets/clock_preview.dart';
import 'editor_screen.dart';
import 'presets_screen.dart';
import 'settings_screen.dart';

/// Home screen — entry point after onboarding.
///
/// Displays a live [ClockPreview] and buttons to Customise, Add Widget,
/// Enable Notification, and Enable Floating Bar.
class HomeScreen extends StatefulWidget {
  final StorageService storage;
  final AdsService adsService;
  final IapService iapService;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.adsService,
    required this.iapService,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late ClockConfig _config;
  late NotificationService _notifService;

  /// Called from deep link when user taps widget
  void openEditorFromDeepLink() => _openEditor();

  @override
  void initState() {
    super.initState();
    _config = widget.storage.loadConfig();
    _notifService = NotificationService(widget.storage);
    // Pre-load rewarded ad for faster unlock flow
    widget.adsService.preloadRewarded();
  }

  Future<void> _openEditor() async {
    final updated = await Navigator.of(context).push<ClockConfig>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          config: _config,
          storage: widget.storage,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _config = updated);
      WidgetBridge.updateWidgets();
      _notifService.update();
      FloatingBarBridge.update();
    }
  }

  Future<void> _openPresets() async {
    final updated = await Navigator.of(context).push<ClockConfig>(
      MaterialPageRoute(
        builder: (_) => PresetsScreen(
          currentConfig: _config,
          adsService: widget.adsService,
          storage: widget.storage,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _config = updated);
      WidgetBridge.updateWidgets();
      _notifService.update();
      FloatingBarBridge.update();
    }
  }

  // ── Placeholder actions (logic added in prompts 5, 7) ──

  void _onAddWidget() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Widget to Home Screen'),
        content: const Text(
          'Long-press an empty area on your home screen,\n'
          'then tap "Widgets" and find "Date & Time Widget".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _onEnableNotification() async {
    if (_notifService.isEnabled) {
      await _notifService.disable();
      setState(() => _config = _config.copyWith(notificationEnabled: false));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification icon disabled')),
        );
      }
    } else {
      final started = await _notifService.enable(context);
      if (started && mounted) {
        setState(() => _config = _config.copyWith(notificationEnabled: true));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification icon enabled')),
        );
      }
    }
  }

  Future<void> _onEnableFloatingBar() async {
    if (_config.floatingBarEnabled) {
      await FloatingBarBridge.stop();
      setState(() => _config = _config.copyWith(floatingBarEnabled: false));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Floating Bar disabled')),
        );
      }
      return;
    }

    // 1. Explanation dialog — make it clear this is NOT modifying system status bar
    if (!mounted) return;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.open_in_browser, size: 36),
        title: const Text('Enable Floating Bar'),
        content: const Text(
          'A small floating bar from this app will appear just below '
          'your status bar, showing day, date & time.\n\n'
          'This does NOT modify your phone\'s status bar. '
          'It is a separate overlay from this app that can be '
          'disabled at any time.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (proceed != true) return;

    // 2. Check overlay permission
    final hasPermission = await FloatingBarBridge.hasOverlayPermission();
    if (!hasPermission) {
      await FloatingBarBridge.requestOverlayPermission();
      // User is taken to system settings — they'll come back
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please grant "Display over other apps" permission, then tap Enable again.',
            ),
          ),
        );
      }
      return;
    }

    // 3. Start service
    await FloatingBarBridge.start();
    setState(() => _config = _config.copyWith(floatingBarEnabled: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Floating Bar enabled')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date & Time Widget'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable content ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),

                  // Live preview
                  ClockPreview(config: _config),
                  const SizedBox(height: 24),

                  // Tagline
                  Text(
                    'Always see the day, date & time',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action buttons ──
                  _ActionButton(
                    icon: Icons.palette_outlined,
                    label: 'Customize',
                    onTap: _openEditor,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.style_outlined,
                    label: 'Presets',
                    onTap: _openPresets,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.widgets_outlined,
                    label: 'Add Widget',
                    onTap: _onAddWidget,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: _notifService.isEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_outlined,
                    label: _notifService.isEnabled
                        ? 'Disable Notification'
                        : 'Enable Notification',
                    onTap: _onEnableNotification,
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: _config.floatingBarEnabled
                        ? Icons.open_in_browser
                        : Icons.open_in_browser_outlined,
                    label: _config.floatingBarEnabled
                        ? 'Disable Floating Bar'
                        : 'Enable Floating Bar',
                    onTap: _onEnableFloatingBar,
                    subtitle: 'Optional — sits below status bar',
                  ),
                  const SizedBox(height: 12),
                  _ActionButton(
                    icon: Icons.settings_outlined,
                    label: 'Settings',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SettingsScreen(
                          storage: widget.storage,
                          adsService: widget.adsService,
                          iapService: widget.iapService,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // ── AdMob banner ──
            AdBanner(show: widget.adsService.showBanners),
          ],
        ),
      ),
    );
  }
}

/// Simple action button with icon and label.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
