import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import '../models/widget_design.dart';
import '../utils/date_formatter.dart';

/// Live clock preview that updates every second.
///
/// Reads format from [ClockConfig] and renders the time, date, and day
/// of week using [DateFormatter].
///
/// Optionally renders a [BackgroundConfig] behind the text.
class ClockPreview extends StatefulWidget {
  final ClockConfig config;
  final BackgroundConfig background;

  const ClockPreview({
    super.key,
    required this.config,
    this.background = const BackgroundConfig(),
  });

  @override
  State<ClockPreview> createState() => _ClockPreviewState();
}

class _ClockPreviewState extends State<ClockPreview> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color get _textColor {
    final hex = widget.config.color.replaceFirst('#', '');
    if (hex.length == 6) {
      return Color(int.parse('FF$hex', radix: 16));
    }
    return Colors.white;
  }

  TextAlign get _alignment {
    switch (widget.config.alignment) {
      case 'left':
        return TextAlign.left;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.center;
    }
  }

  /// Build the container decoration based on background type.
  BoxDecoration _backgroundDecoration() {
    final bg = widget.background;

    switch (bg.type) {
      case BackgroundType.solid:
        final hex = (bg.solidColor ?? '#1A1A2E').replaceFirst('#', '');
        final color = Color(int.parse('FF$hex', radix: 16));
        return BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        );

      case BackgroundType.gradient:
        final colors = bg.gradientColors
                ?.map((hex) {
                  final h = hex.replaceFirst('#', '');
                  return Color(int.parse('FF$h', radix: 16));
                })
                .toList() ??
            [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
        return BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        );

      case BackgroundType.image:
        // Image backgrounds use a Stack with image + overlay layers
        return BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        );

      case BackgroundType.none:
        return BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        );
    }
  }

  /// Build background image widget.
  Widget _buildBackgroundImage() {
    final path = widget.background.imagePath;
    if (path == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      ),
    );
  }

  /// Build overlay on top of background image.
  Widget _buildOverlay() {
    final bg = widget.background;
    Color overlayColor;

    switch (bg.overlayMode) {
      case OverlayMode.dark:
        overlayColor = Colors.black;
        break;
      case OverlayMode.light:
        overlayColor = Colors.white;
        break;
      case OverlayMode.none:
        return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: overlayColor.withValues(alpha: bg.overlayOpacity),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  /// Build text shadow for readability over images.
  List<Shadow>? get _textShadows {
    if (!widget.background.textShadow) return null;
    return const [
      Shadow(
        color: Colors.black54,
        blurRadius: 8,
        offset: Offset(1, 1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final display = DateFormatter.buildDisplay(_now, widget.config);
    final fontSize = widget.config.fontSize;
    final isImageBg = widget.background.type == BackgroundType.image;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: _backgroundDecoration(),
      child: isImageBg
          ? ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Background image layer
                  Positioned.fill(child: _buildBackgroundImage()),

                  // Overlay layer
                  if (widget.background.overlayOpacity > 0)
                    Positioned.fill(child: _buildOverlay()),

                  // Text content
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    child: _buildTextContent(display, fontSize),
                  ),
                ],
              ),
            )
          : _buildTextContent(display, fontSize),
    );
  }

  Widget _buildTextContent(ClockDisplay display, double fontSize) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Day of week
        if (display.day.isNotEmpty)
          Text(
            display.day,
            textAlign: _alignment,
            style: TextStyle(
              fontSize: fontSize * 0.55,
              fontWeight: FontWeight.w500,
              color: _textColor,
              shadows: _textShadows,
            ),
          ),

        // Date
        if (display.date.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: display.day.isNotEmpty ? 4 : 0),
            child: Text(
              display.date,
              textAlign: _alignment,
              style: TextStyle(
                fontSize: fontSize * 0.6,
                fontWeight: FontWeight.w400,
                color: _textColor.withValues(alpha: 0.85),
                shadows: _textShadows,
              ),
            ),
          ),

        // Time
        Padding(
          padding: EdgeInsets.only(
            top: (display.day.isNotEmpty || display.date.isNotEmpty) ? 8 : 0,
          ),
          child: Text(
            display.time,
            textAlign: _alignment,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: _textColor,
              letterSpacing: 1.2,
              shadows: _textShadows,
            ),
          ),
        ),
      ],
    );
  }
}
