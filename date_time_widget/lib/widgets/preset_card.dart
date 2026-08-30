import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../widgets/clock_preview.dart';

/// A card displaying a [Preset] with a mini live preview.
///
/// Used in the presets grid for quick-selection.
class PresetCard extends StatelessWidget {
  final Preset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const PresetCard({
    super.key,
    required this.preset,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mini preview
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(10)),
                child: ClockPreview(config: preset.config),
              ),
            ),

            // Label bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.6),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(10),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      preset.name,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (preset.isLocked)
                    const Icon(Icons.lock, size: 12, color: Colors.grey),
                  if (isSelected)
                    Icon(Icons.check_circle,
                        size: 14,
                        color: Theme.of(context).colorScheme.primary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
