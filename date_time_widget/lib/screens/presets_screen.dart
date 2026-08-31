import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import '../models/presets.dart';
import '../services/ads_service.dart';
import '../services/reward_service.dart';
import '../services/storage_service.dart';
import '../widgets/preset_card.dart';

/// Screen showing all built-in presets in a grid.
///
/// User taps a preset to select it. Returns the selected [ClockConfig]
/// to the caller via [Navigator.pop].
class PresetsScreen extends StatefulWidget {
  final ClockConfig currentConfig;
  final AdsService? adsService;
  final StorageService? storage;
  final RewardService? rewardService;

  const PresetsScreen({
    super.key,
    required this.currentConfig,
    this.adsService,
    this.storage,
    this.rewardService,
  });

  @override
  State<PresetsScreen> createState() => _PresetsScreenState();
}

class _PresetsScreenState extends State<PresetsScreen> {
  String _selectedId = '';

  @override
  void initState() {
    super.initState();
    // Reset reward state if new day
    widget.rewardService?.resetIfNewDay();
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
    Navigator.of(context).pop(config);
  }

  Future<void> _onLockedTap(String presetId, String name) async {
    final ads = widget.adsService;
    final storage = widget.storage;
    final reward = widget.rewardService;
    if (ads == null || storage == null || reward == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" is locked — watch an ad to unlock.')),
      );
      return;
    }

    final unlocked = await ads.unlockPreset(
      context,
      presetId,
      widget.currentConfig,
      isFreePreset: false,
    );
    if (unlocked && mounted) {
      setState(() => _selectedId = presetId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"$name" unlocked for today!')),
      );
      Navigator.of(context).pop(preset.config);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reward = widget.rewardService;

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
            final isFreePreset = !preset.isLocked;
            final isUsable = reward != null
                ? reward.canUsePreset(
                    preset.id,
                    isPremium: widget.currentConfig.isPremium,
                    isFreePreset: isFreePreset,
                  )
                : (isFreePreset || widget.currentConfig.isPremium);

            return PresetCard(
              preset: preset,
              isSelected: _selectedId == preset.id,
              onTap: isUsable
                  ? () => _onSelect(preset.id, preset.config)
                  : () => _onLockedTap(preset.id, preset.name),
            );
          },
        ),
      ),
    );
  }
}
