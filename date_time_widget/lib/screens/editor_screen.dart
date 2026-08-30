import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import '../services/storage_service.dart';
import '../services/widget_bridge.dart';
import '../widgets/clock_preview.dart';

/// Format options available in the editor.
const List<String> dateFormats = [
  'EEE dd MMM', // Sun 30 Aug
  'dd/MM/yyyy', // 30/08/2026
  'MM/dd/yyyy', // 08/30/2026
  'yyyy-MM-dd', // 2026-08-30
  'EEEE, dd MMMM', // Sunday, 30 August
  'EEEE, MMMM d', // Sunday, August 30
  'dd MMM yyyy', // 30 Aug 2026
  'MMM d', // Aug 30
  'd MMMM', // 30 August
];

/// Swatches for the colour picker.
const List<Color> colorSwatches = [
  Colors.white,
  Colors.black,
  Color(0xFF2196F3), // Blue
  Color(0xFF00BCD4), // Cyan
  Color(0xFF4CAF50), // Green
  Color(0xFFFFC107), // Amber
  Color(0xFFFF9800), // Orange
  Color(0xFFFF5722), // Deep Orange
  Color(0xFFE91E63), // Pink
  Color(0xFF9C27B0), // Purple
  Color(0xFF795548), // Brown
  Color(0xFF9E9E9E), // Grey
];

/// Editor screen — lets the user customise every aspect of the clock
/// and immediately see the result in a live [ClockPreview].
///
/// Layout is designed so that a future AdMob banner at the very bottom
/// never overlaps the preview (see plan §3 note).
class EditorScreen extends StatefulWidget {
  final ClockConfig config;
  final StorageService storage;

  const EditorScreen({
    super.key,
    required this.config,
    required this.storage,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late ClockConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _savedConfig = widget.config;
  }

  late ClockConfig _savedConfig;
  bool get _hasChanges => _config != _savedConfig;

  // ── Helpers ──────────────────────────────────────────────

  void _update(ClockConfig Function(ClockConfig c) updater) {
    setState(() => _config = updater(_config));
  }

  Color get _parsedColor {
    final hex = _config.color.replaceFirst('#', '');
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    return Colors.white;
  }

  String _colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  Future<void> _onBack() async {
    if (!_hasChanges) {
      Navigator.of(context).pop(_config);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text('You have unsaved changes. Discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep editing'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.of(context).pop(_savedConfig);
    }
  }

  Future<void> _save() async {
    await widget.storage.saveConfig(_config);
    _savedConfig = _config;
    WidgetBridge.updateWidgets();
    if (mounted) {
      Navigator.of(context).pop(_config);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Config saved')),
      );
    }
  }

  // ── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _onBack,
        ),
        actions: [
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable controls ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live preview (always visible at top)
                ClockPreview(config: _config),
                const SizedBox(height: 20),

                // ── Date Format ──
                _SectionTitle('Date Format'),
                const SizedBox(height: 8),
                _FormatChips(
                  options: dateFormats,
                  selected: _config.format,
                  onChanged: (v) => _update((c) => c.copyWith(format: v)),
                ),
                const SizedBox(height: 20),

                // ── Time Format ──
                _SectionTitle('Time Format'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ChoiceChip(
                      label: '24 h',
                      selected: _config.timeFormat == 'HH:mm',
                      onTap: () => _update(
                          (c) => c.copyWith(timeFormat: 'HH:mm')),
                    ),
                    const SizedBox(width: 8),
                    _ChoiceChip(
                      label: '12 h',
                      selected: _config.timeFormat == 'hh:mm a',
                      onTap: () => _update(
                          (c) => c.copyWith(timeFormat: 'hh:mm a')),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Toggles ──
                _SectionTitle('Display'),
                const SizedBox(height: 8),
                _ToggleRow(
                  label: 'Show day of week',
                  value: _config.showDay,
                  onChanged: (v) =>
                      _update((c) => c.copyWith(showDay: v)),
                ),
                _ToggleRow(
                  label: 'Show date',
                  value: _config.showDate,
                  onChanged: (v) =>
                      _update((c) => c.copyWith(showDate: v)),
                ),
                _ToggleRow(
                  label: 'Show seconds',
                  value: _config.showSeconds,
                  onChanged: (v) =>
                      _update((c) => c.copyWith(showSeconds: v)),
                ),
                const SizedBox(height: 20),

                // ── Font Size ──
                _SectionTitle('Font Size'),
                Row(
                  children: [
                    const Icon(Icons.text_decrease, size: 18),
                    Expanded(
                      child: Slider(
                        value: _config.fontSize,
                        min: 14,
                        max: 48,
                        divisions: 34,
                        label: _config.fontSize.round().toString(),
                        onChanged: (v) =>
                            _update((c) => c.copyWith(fontSize: v)),
                      ),
                    ),
                    const Icon(Icons.text_increase, size: 18),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 36,
                      child: Text(
                        '${_config.fontSize.round()}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Colour ──
                _SectionTitle('Colour'),
                const SizedBox(height: 8),
                _ColorPicker(
                  selected: _parsedColor,
                  onChanged: (c) =>
                      _update((cfg) => cfg.copyWith(color: _colorToHex(c))),
                ),
                const SizedBox(height: 20),

                // ── Alignment ──
                _SectionTitle('Alignment'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _AlignButton(
                      icon: Icons.format_align_left,
                      selected: _config.alignment == 'left',
                      onTap: () =>
                          _update((c) => c.copyWith(alignment: 'left')),
                    ),
                    const SizedBox(width: 8),
                    _AlignButton(
                      icon: Icons.format_align_center,
                      selected: _config.alignment == 'center',
                      onTap: () =>
                          _update((c) => c.copyWith(alignment: 'center')),
                    ),
                    const SizedBox(width: 8),
                    _AlignButton(
                      icon: Icons.format_align_right,
                      selected: _config.alignment == 'right',
                      onTap: () =>
                          _update((c) => c.copyWith(alignment: 'right')),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helper widgets ────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .titleSmall
          ?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

class _FormatChips extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const _FormatChips({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final opt in options)
          ChoiceChip(
            label: Text(opt, style: const TextStyle(fontSize: 12)),
            selected: selected == opt,
            onSelected: (_) => onChanged(opt),
          ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

/// Simple colour picker: a grid of predefined swatches.
/// No external library needed — within whitelist constraint.
class _ColorPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onChanged;

  const _ColorPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final c in colorSwatches)
          GestureDetector(
            onTap: () => onChanged(c),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: c,
                shape: BoxShape.circle,
                border: Border.all(
                  color: c.toARGB32() == selected.toARGB32()
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey[300]!,
                  width: c.toARGB32() == selected.toARGB32() ? 3 : 1,
                ),
                boxShadow: c.toARGB32() == Colors.white.toARGB32()
                    ? null
                    : [
                        BoxShadow(
                          color: c.withValues(alpha: 0.3),
                          blurRadius: 4,
                        ),
                      ],
              ),
            ),
          ),
      ],
    );
  }
}

class _AlignButton extends StatelessWidget {
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _AlignButton({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[600],
        ),
      ),
    );
  }
}
