import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import '../models/presets.dart';
import '../services/ads_service.dart';
import '../services/storage_service.dart';
import '../services/widget_bridge.dart';
import '../widgets/preset_card.dart';

/// Screen showing all built-in presets in a grid.
///
/// User taps a preset to select it. Returns the selected [ClockConfig]
/// to the caller via [Navigator.pop].
class PresetsScreen extends StatefulWidget {
  final ClockConfig currentConfig;
  final AdsService? adsService;
  final StorageService? storage;

  const PresetsScreen({
    super.key,
    required this.currentConfig,
    this.adsService,
    this.storage,
  });

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  String _selectedId = '';

  @override
  void initState() {
    super.initState();
    // Try to match current config to a preset
    for (final p in builtInPresets) {
      if (p.config == widget.currentConfig) {
        _selectedId = p.id;
        break;
      }
    }
  }

  void _onSelect(String presetId, ClockConfig config) {
    setState(() => _selectedId = presetId);
    WidgetBridge.updateWidgets();
    Navigator.of(context).pop(config);
  }

  Future<void> _onLockedTap(String presetId, String name) async {
    final ads = widget.adsService;
    final storage = widget.storage;
    if (ads == null || storage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" is locked — watch an ad to unlock.')),
      );
      return;
    }

    final unlocked = await ads.unlockPreset(context, presetId, widget.currentConfig);
    if (unlocked && mounted) {
      final updatedConfig = storage.loadConfig();
      setState(() => _selectedId = presetId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" unlocked!')),
      );
      WidgetBridge.updateWidgets();
      Navigator.of(context).pop(updatedConfig);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Presets')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: builtInPresets.length,
          itemBuilder: (context, index) {
            final preset = builtInPresets[index];
            final isUnlocked = !preset.isLocked ||
                widget.currentConfig.unlockedPresets.contains(preset.id) ||
                widget.currentConfig.isPremium;

            return PresetCard(
              preset: preset,
              isSelected: _selectedId == preset.id,
              onTap: isUnlocked
                  ? () => _onSelect(preset.id, preset.config)
                  : () => _onLockedTap(preset.id, preset.name),
            );
          },
        ),
      ),
    );
  }
}
