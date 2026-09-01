import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/clock_config.dart';
import '../models/widget_design.dart';
import '../services/design_storage_service.dart';
import '../services/storage_service.dart';
import '../services/widget_bridge.dart';
import '../utils/image_utils.dart';
import '../widgets/clock_preview.dart';
import 'crop_screen.dart';

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
/// Result returned by EditorScreen when [storage] is null (create flow).
class EditorScreenResult {
  final ClockConfig config;
  final BackgroundConfig background;

  const EditorScreenResult({
    required this.config,
    required this.background,
  });
}

class EditorScreen extends StatefulWidget {
  final ClockConfig config;
  final StorageService? storage;
  final DesignStorageService? designStorage;

  /// Optional existing background to edit (for My Designs flow).
  final BackgroundConfig? initialBackground;

  const EditorScreen({
    super.key,
    required this.config,
    this.storage,
    this.designStorage,
    this.initialBackground,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late ClockConfig _config;
  late BackgroundConfig _background;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessingImage = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    _background = widget.initialBackground ?? const BackgroundConfig();
    _savedConfig = widget.config;
    _savedBackground = _background;
  }

  late ClockConfig _savedConfig;
  late BackgroundConfig _savedBackground;
  bool get _hasChanges =>
      _config != _savedConfig || _background != _savedBackground;

  // ── Helpers ──────────────────────────────────────────────

  void _updateConfig(ClockConfig Function(ClockConfig c) updater) {
    setState(() => _config = updater(_config));
  }

  void _updateBackground(BackgroundConfig Function(BackgroundConfig b) updater) {
    setState(() => _background = updater(_background));
  }

  Color get _parsedColor {
    final hex = _config.color.replaceFirst('#', '');
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    return Colors.white;
  }

  Color get _parsedBackgroundColor {
    final hex = (_background.solidColor ?? '#1A1A2E').replaceFirst('#', '');
    if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
    return const Color(0xFF1A1A2E);
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
      Navigator.of(context).pop(EditorScreenResult(
        config: _savedConfig,
        background: _savedBackground,
      ));
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      _savedConfig = _config;
      _savedBackground = _background;

      if (widget.storage != null) {
        // Global config save flow
        await widget.storage!.saveConfig(_config);

        // Bake background bitmap for native widget
        await _bakeAndSetWidgetBackground();

        WidgetBridge.updateWidgets();
        if (mounted) {
          // Return both config AND background so HomeScreen can persist
          Navigator.of(context).pop(EditorScreenResult(
            config: _config,
            background: _background,
          ));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Config saved')),
          );
        }
      } else {
        // Create-new-design flow — return result to caller
        if (mounted) {
          Navigator.of(context).pop(EditorScreenResult(
            config: _config,
            background: _background,
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Bake the background to a bitmap and push it to the native widget.
  Future<void> _bakeAndSetWidgetBackground() async {
    try {
      // Get all active widget IDs
      final widgetIds = await WidgetBridge.getActiveWidgetIds();
      if (widgetIds.isEmpty) return;

      if (_background.type == BackgroundType.none) {
        // Clear background on all widgets
        for (final widgetId in widgetIds) {
          await WidgetBridge.setWidgetBackground(
            widgetId: widgetId,
            bitmapPath: null,
          );
        }
        return;
      }

      // Bake background at max widget size (480×480)
      final bitmapBytes = await ImageUtils.bakeBackgroundBitmap(
        background: _background,
        width: 480,
        height: 480,
      );
      if (bitmapBytes == null) {
        // Bake returned null (e.g. missing image) — clear bitmap
        for (final widgetId in widgetIds) {
          await WidgetBridge.setWidgetBackground(
            widgetId: widgetId,
            bitmapPath: null,
          );
        }
        return;
      }

      // Save bitmap to disk
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

      // Push to each widget instance
      for (final widgetId in widgetIds) {
        await WidgetBridge.setWidgetBackground(
          widgetId: widgetId,
          bitmapPath: bgFile.path,
        );
      }
    } catch (e, st) {
      debugPrint('bakeAndSetWidgetBackground failed: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update widget background')),
        );
      }
    }
  }

  // ── Background actions ──────────────────────────────────

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      maxHeight: 2400,
    );
    if (picked == null) return;

    setState(() => _isProcessingImage = true);
    try {
      // Read image bytes
      final bytes = await File(picked.path).readAsBytes();

      // Copy and resize source to max 1600px
      final appDir = await getApplicationDocumentsDirectory();
      final designsDir = Directory('${appDir.path}/designs');
      if (!await designsDir.exists()) {
        await designsDir.create(recursive: true);
      }
      final designId = const Uuid().v4();
      final sourcePath = '${designsDir.path}/$designId.jpg';
      await ImageUtils.copyAndResizeSource(
        imageBytes: bytes,
        destinationPath: sourcePath,
      );

      // Open crop screen
      if (!mounted) return;
      final cropResult = await Navigator.of(context).push<CropResult>(
        MaterialPageRoute(
          builder: (_) => CropScreen(imageFile: File(sourcePath)),
        ),
      );

      if (cropResult == null) return;

      // Apply smart defaults for new image background
      setState(() {
        _background = BackgroundConfig(
          type: BackgroundType.image,
          imagePath: sourcePath,
          cropScale: cropResult.scale,
          cropOffsetX: cropResult.offsetX,
          cropOffsetY: cropResult.offsetY,
          blurSigma: 0.0, // Off by default per plan5 §4
          overlayOpacity: 0.35, // Dark overlay 35% per plan5 §4
          overlayMode: OverlayMode.dark,
          autoTextContrast: true,
          textShadow: true,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not process image. Please try another one.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessingImage = false);
    }
  }

  void _removeImage() {
    setState(() {
      _background = const BackgroundConfig();
    });
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
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable controls ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live preview with background
                ClockPreview(config: _config, background: _background),
                const SizedBox(height: 20),

                // ── Background Section ──
                Stack(
                  children: [
                    _SectionTitle('Background'),
                    const SizedBox(height: 8),
                    _BackgroundTypeSelector(
                      selected: _background.type,
                      isProcessing: _isProcessingImage,
                      onChanged: (type) {
                        if (type == BackgroundType.image) {
                          _pickImage();
                        } else {
                          _updateBackground((b) => b.copyWith(type: type));
                        }
                      },
                      onRemoveImage: _background.type == BackgroundType.image
                          ? _removeImage
                          : null,
                    ),
                    if (_isProcessingImage)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black45,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(color: Colors.white),
                                SizedBox(height: 8),
                                Text(
                                  'Preparing image…',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // ── Image-specific controls ──
                if (_background.type == BackgroundType.image) ...[
                  const SizedBox(height: 16),
                  _SectionTitle('Image Adjustments'),
                  const SizedBox(height: 8),

                  // Overlay mode
                  _SectionLabel('Overlay'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _ChoiceChip(
                        label: 'None',
                        selected: _background.overlayMode == OverlayMode.none,
                        onTap: () => _updateBackground(
                            (b) => b.copyWith(overlayMode: OverlayMode.none)),
                      ),
                      const SizedBox(width: 8),
                      _ChoiceChip(
                        label: 'Dark',
                        selected: _background.overlayMode == OverlayMode.dark,
                        onTap: () => _updateBackground(
                            (b) => b.copyWith(overlayMode: OverlayMode.dark)),
                      ),
                      const SizedBox(width: 8),
                      _ChoiceChip(
                        label: 'Light',
                        selected: _background.overlayMode == OverlayMode.light,
                        onTap: () => _updateBackground(
                            (b) => b.copyWith(overlayMode: OverlayMode.light)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Overlay opacity
                  _SectionLabel(
                      'Overlay Opacity: ${(_background.overlayOpacity * 100).round()}%'),
                  Slider(
                    value: _background.overlayOpacity,
                    min: 0.0,
                    max: 0.7,
                    divisions: 14,
                    onChanged: (v) =>
                        _updateBackground((b) => b.copyWith(overlayOpacity: v)),
                  ),
                  const SizedBox(height: 8),

                  // Blur
                  _SectionLabel(
                      'Blur: ${_background.blurSigma > 0 ? _background.blurSigma.round() : "Off"}'),
                  Slider(
                    value: _background.blurSigma,
                    min: 0.0,
                    max: 20.0,
                    divisions: 20,
                    onChanged: (v) =>
                        _updateBackground((b) => b.copyWith(blurSigma: v)),
                  ),
                  const SizedBox(height: 8),

                  // Toggles
                  _ToggleRow(
                    label: 'Auto text contrast',
                    value: _background.autoTextContrast,
                    onChanged: (v) =>
                        _updateBackground((b) => b.copyWith(autoTextContrast: v)),
                  ),
                  _ToggleRow(
                    label: 'Text shadow',
                    value: _background.textShadow,
                    onChanged: (v) =>
                        _updateBackground((b) => b.copyWith(textShadow: v)),
                  ),
                ],

                // ── Solid color picker ──
                if (_background.type == BackgroundType.solid) ...[
                  const SizedBox(height: 12),
                  _SectionLabel('Color'),
                  const SizedBox(height: 8),
                  _ColorPicker(
                    selected: _parsedBackgroundColor,
                    onChanged: (c) => _updateBackground(
                        (b) => b.copyWith(solidColor: _colorToHex(c))),
                  ),
                ],

                // ── Gradient color picker ──
                if (_background.type == BackgroundType.gradient) ...[
                  const SizedBox(height: 12),
                  _SectionLabel('Gradient Colors'),
                  const SizedBox(height: 8),
                  _GradientColorPicker(
                    colors: _background.gradientColors ??
                        ['#1A1A2E', '#16213E'],
                    onChanged: (colors) =>
                        _updateBackground((b) => b.copyWith(gradientColors: colors)),
                  ),
                ],

                const SizedBox(height: 20),

                // ── Date Format ──
                _SectionTitle('Date Format'),
                const SizedBox(height: 8),
                _FormatChips(
                  options: dateFormats,
                  selected: _config.format,
                  onChanged: (v) => _updateConfig((c) => c.copyWith(format: v)),
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
                      onTap: () =>
                          _updateConfig((c) => c.copyWith(timeFormat: 'HH:mm')),
                    ),
                    const SizedBox(width: 8),
                    _ChoiceChip(
                      label: '12 h',
                      selected: _config.timeFormat == 'hh:mm a',
                      onTap: () => _updateConfig(
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
                      _updateConfig((c) => c.copyWith(showDay: v)),
                ),
                _ToggleRow(
                  label: 'Show date',
                  value: _config.showDate,
                  onChanged: (v) =>
                      _updateConfig((c) => c.copyWith(showDate: v)),
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
                            _updateConfig((c) => c.copyWith(fontSize: v)),
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
                _SectionTitle('Text Colour'),
                const SizedBox(height: 8),
                _ColorPicker(
                  selected: _parsedColor,
                  onChanged: (c) =>
                      _updateConfig((cfg) => cfg.copyWith(color: _colorToHex(c))),
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
                          _updateConfig((c) => c.copyWith(alignment: 'left')),
                    ),
                    const SizedBox(width: 8),
                    _AlignButton(
                      icon: Icons.format_align_center,
                      selected: _config.alignment == 'center',
                      onTap: () =>
                          _updateConfig((c) => c.copyWith(alignment: 'center')),
                    ),
                    const SizedBox(width: 8),
                    _AlignButton(
                      icon: Icons.format_align_right,
                      selected: _config.alignment == 'right',
                      onTap: () =>
                          _updateConfig((c) => c.copyWith(alignment: 'right')),
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

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
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

/// Gradient colour picker with 2 color slots.
class _GradientColorPicker extends StatelessWidget {
  final List<String> colors;
  final ValueChanged<List<String>> onChanged;

  const _GradientColorPicker({
    required this.colors,
    required this.onChanged,
  });

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  String _colorToHex(Color c) =>
      '#${c.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  @override
  Widget build(BuildContext context) {
    final c1 = colors.isNotEmpty ? _hexToColor(colors[0]) : Colors.blue;
    final c2 = colors.length > 1 ? _hexToColor(colors[1]) : Colors.purple;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview gradient
        Container(
          height: 40,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [c1, c2]),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('Start: '),
            GestureDetector(
              onTap: () async {
                final c = await _showColorDialog(context, c1);
                if (c != null) {
                  final newColors = List<String>.from(colors);
                  if (newColors.isEmpty) {
                    newColors.add(_colorToHex(c));
                    newColors.add('#16213E');
                  } else {
                    newColors[0] = _colorToHex(c);
                  }
                  onChanged(newColors);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c1,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!),
                ),
              ),
            ),
            const SizedBox(width: 24),
            const Text('End: '),
            GestureDetector(
              onTap: () async {
                final c = await _showColorDialog(context, c2);
                if (c != null) {
                  final newColors = List<String>.from(colors);
                  if (newColors.length < 2) {
                    newColors.add(_colorToHex(c));
                  } else {
                    newColors[1] = _colorToHex(c);
                  }
                  onChanged(newColors);
                }
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: c2,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[400]!),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Color?> _showColorDialog(BuildContext context, Color current) {
    return showDialog<Color>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick colour'),
        content: _ColorPicker(
          selected: current,
          onChanged: (c) => Navigator.of(ctx).pop(c),
        ),
      ),
    );
  }
}

/// Background type selector: None / Solid / Gradient / Image.
class _BackgroundTypeSelector extends StatelessWidget {
  final BackgroundType selected;
  final ValueChanged<BackgroundType> onChanged;
  final VoidCallback? onRemoveImage;
  final bool isProcessing;

  const _BackgroundTypeSelector({
    required this.selected,
    required this.onChanged,
    this.onRemoveImage,
    this.isProcessing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _BgTypeChip(
          icon: Icons.block_outlined,
          label: 'None',
          selected: selected == BackgroundType.none,
          onTap: () => onChanged(BackgroundType.none),
        ),
        _BgTypeChip(
          icon: Icons.color_lens_outlined,
          label: 'Solid',
          selected: selected == BackgroundType.solid,
          onTap: () => onChanged(BackgroundType.solid),
        ),
        _BgTypeChip(
          icon: Icons.gradient,
          label: 'Gradient',
          selected: selected == BackgroundType.gradient,
          onTap: () => onChanged(BackgroundType.gradient),
        ),
        _BgTypeChip(
          icon: Icons.photo_outlined,
          label: 'Image',
          selected: selected == BackgroundType.image,
          onTap: isProcessing ? null : () => onChanged(BackgroundType.image),
          enabled: !isProcessing,
        ),
        if (onRemoveImage != null)
          GestureDetector(
            onTap: onRemoveImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 16, color: Colors.red[700]),
                  const SizedBox(width: 4),
                  Text(
                    'Remove',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BgTypeChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool enabled;

  const _BgTypeChip({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
      ),
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
