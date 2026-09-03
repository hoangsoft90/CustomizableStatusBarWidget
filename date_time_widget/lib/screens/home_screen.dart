import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/clock_config.dart';
import '../models/widget_design.dart';
import '../services/ads_service.dart';
import '../services/design_storage_service.dart';
import '../services/iap_service.dart';
import '../services/floating_bar_bridge.dart';
import '../services/notification_service.dart';
import '../services/reward_service.dart';
import '../services/storage_service.dart';
import '../services/widget_bridge.dart';
import '../utils/image_utils.dart';
import '../widgets/ad_banner.dart';
import '../widgets/clock_preview.dart';
import 'editor_screen.dart';
import 'my_designs_screen.dart';
import 'presets_screen.dart';
import 'settings_screen.dart';

/// Home screen — entry point after onboarding.
///
/// Displays a live [ClockPreview] and buttons grouped by priority:
///   1. STATUS BAR (Notification) — P0 USP
///   2. HOME SCREEN (Widget) — P0
///   3. FLOATING BAR — P1 optional
class HomeScreen extends StatefulWidget {
  final StorageService storage;
  final AdsService adsService;
  final IapService iapService;
  final RewardService rewardService;
  final DesignStorageService designStorage;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.adsService,
    required this.iapService,
    required this.rewardService,
    required this.designStorage,
  });

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  late ClockConfig _config;
  late NotificationService _notifService;
  BackgroundConfig _background = const BackgroundConfig();

  /// Called from deep link when user taps widget
  void openEditorFromDeepLink() => _openEditor();

  @override
  void initState() {
    super.initState();
    _config = widget.storage.loadConfig();
    _background = widget.storage.loadBackground();
    _notifService = NotificationService(widget.storage);
    widget.adsService.preloadRewarded();
  }

  Future<void> _openEditor() async {
    final result = await Navigator.of(context).push<EditorScreenResult>(
      MaterialPageRoute(
        builder: (_) => EditorScreen(
          config: _config,
          storage: widget.storage,
          designStorage: widget.designStorage,
          initialBackground: _background,
        ),
      ),
    );
    if (result != null && mounted) {
      await widget.storage.saveConfig(result.config);
      await widget.storage.saveBackground(result.background);
      setState(() {
        _config = result.config;
        _background = result.background;
      });
      final configJson = result.config.toJsonString();
      WidgetBridge.updateWidgets(configJson: configJson);
      _notifService.update();
      FloatingBarBridge.update(configJson: configJson);
    }
  }

  Future<void> _openMyDesigns() async {
    final design = await Navigator.of(context).push<WidgetDesign>(
      MaterialPageRoute(
        builder: (_) => MyDesignsScreen(
          designStorage: widget.designStorage,
          isPremium: _config.isPremium,
        ),
      ),
    );
    if (design != null && mounted) {
      // Apply design: save clock config + set background
      await widget.storage.saveConfig(design.clock);
      await widget.storage.saveBackground(design.background);
      setState(() {
        _config = design.clock;
        _background = design.background;
      });
      final configJson = design.clock.toJsonString();
      WidgetBridge.updateWidgets(configJson: configJson);

      // Bake and push background to native widget
      await _bakeAndSetWidgetBackground(design.background);

      _notifService.update();
      FloatingBarBridge.update(configJson: configJson);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Design "${design.name}" applied')),
        );
      }
    }
  }

  /// Bake background bitmap and push to all active native widgets.
  Future<void> _bakeAndSetWidgetBackground(BackgroundConfig bg) async {
    if (bg.type == BackgroundType.none) {
      // Clear background on all widgets
      final widgetIds = await WidgetBridge.getActiveWidgetIds();
      for (final id in widgetIds) {
        await WidgetBridge.setWidgetBackground(
          widgetId: id,
          bitmapPath: null,
        );
      }
      return;
    }

    try {
      final widgetIds = await WidgetBridge.getActiveWidgetIds();
      if (widgetIds.isEmpty) return;

      final bitmapBytes = await ImageUtils.bakeBackgroundBitmap(
        background: bg,
        width: kWidgetBgBakeWidth,
        height: kWidgetBgBakeHeight,
      );
      if (bitmapBytes == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final bgDir = Directory('${appDir.path}/widget_bg');
      if (!await bgDir.exists()) {
        await bgDir.create(recursive: true);
      }
      final bgFile = File('${bgDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.png');
      await bgFile.writeAsBytes(bitmapBytes);

      // Cleanup old bitmap files (best-effort)
      try {
        final oldFiles = bgDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.png') && f.path != bgFile.path);
        for (final f in oldFiles) {
          await f.delete();
        }
      } catch (_) {}

      for (final id in widgetIds) {
        await WidgetBridge.setWidgetBackground(
          widgetId: id,
          bitmapPath: bgFile.path,
        );
      }
    } catch (e, st) {
      // Plan9: don't swallow bake failures silently — log + inform the user.
      debugPrint('home bakeAndSetWidgetBackground failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update widget background')),
        );
      }
    }
  }

  Future<void> _openPresets() async {
    final updated = await Navigator.of(context).push<ClockConfig>(
      MaterialPageRoute(
        builder: (_) => PresetsScreen(
          currentConfig: _config,
          adsService: widget.adsService,
          storage: widget.storage,
          rewardService: widget.rewardService,
        ),
      ),
    );
    if (updated != null && mounted) {
      await widget.storage.saveConfig(updated);
      setState(() => _config = updated);
      final configJson = updated.toJsonString();
      WidgetBridge.updateWidgets(configJson: configJson);
      _notifService.update();
      FloatingBarBridge.update(configJson: configJson);
    }
  }

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

    final hasPermission = await FloatingBarBridge.hasOverlayPermission();
    if (!hasPermission) {
      await FloatingBarBridge.requestOverlayPermission();
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SizedBox(height: 8),

                  // Live preview
                  ClockPreview(config: _config, background: _background),
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

                  // ── Section: STATUS BAR (P0 — USP) ──
                  _SectionHeader('STATUS BAR'),
                  const SizedBox(height: 8),
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

                  // ── Section: HOME SCREEN (P0) ──
                  _SectionHeader('HOME SCREEN'),
                  const SizedBox(height: 8),
                  _ActionButton(
                    icon: Icons.widgets_outlined,
                    label: 'Add Widget',
                    onTap: _onAddWidget,
                  ),
                  const SizedBox(height: 12),

                  // ── Section: CUSTOMIZE ──
                  _SectionHeader('CUSTOMIZE'),
                  const SizedBox(height: 8),
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
                    icon: Icons.photo_library_outlined,
                    label: 'My Designs',
                    onTap: _openMyDesigns,
                    subtitle: 'Custom backgrounds & saved styles',
                  ),
                  const SizedBox(height: 12),

                  // ── Section: FLOATING BAR (P1 — optional) ──
                  _SectionHeader('FLOATING BAR'),
                  const SizedBox(height: 8),
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

                  // ── Settings ──
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

            // AdMob banner
            AdBanner(show: widget.adsService.showBanners),
          ],
        ),
      ),
    );
  }
}

/// Section header for grouping action buttons.
class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.grey[500],
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
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
