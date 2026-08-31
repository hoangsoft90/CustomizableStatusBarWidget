import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/widget_design.dart';
import '../utils/date_formatter.dart';

/// Preview aspect ratio for shared image (4:2 = 2:1).
const double _previewAspectRatio = 2.0;

/// Target width for shared PNG image.
const int _previewWidth = 1080;

/// Service for rendering a [WidgetDesign] as a PNG image and sharing it.
class ShareService {
  /// Share a design as a PNG image via the system share sheet.
  ///
  /// Renders the design at 1080×540 (2:1 ratio), includes background,
  /// time/date text, and a small watermark.
  static Future<void> shareDesign(BuildContext context, WidgetDesign design) async {
    try {
      // Create a GlobalKey to capture the rendered widget
      final GlobalKey previewKey = GlobalKey();

      // Build the preview widget
      final previewWidget = _SharePreviewWidget(
        key: previewKey,
        design: design,
      );

      // Overlay the widget off-screen to render it
      final overlay = Overlay.of(context);
      final entry = OverlayEntry(
        builder: (_) => Positioned(
          left: -2000, // Off-screen
          top: -2000,
          child: Material(
            type: MaterialType.transparency,
            child: previewWidget,
          ),
        ),
      );

      overlay.insert(entry);

      // Wait for the widget to render
      await Future.delayed(const Duration(milliseconds: 100));

      // Capture as image
      final boundary = previewKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        entry.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 1.0);
      entry.remove();

      // Convert to PNG bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();

      if (byteData == null) return;

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/design_share.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      // Share via system share sheet
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png')],
        subject: 'My clock design — ${design.name}',
        text: 'Check out my clock design! Created with Photo Clock Widget.',
      );
    } catch (_) {
      // Share failed silently — no crash
    }
  }
}

/// Off-screen widget that renders a design preview for screenshot capture.
///
/// This widget is temporarily inserted into the overlay tree, captured
/// as a bitmap, then removed. It is never visible to the user.
class _SharePreviewWidget extends StatelessWidget {
  final WidgetDesign design;

  const _SharePreviewWidget({super.key, required this.design});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final display = DateFormatter.buildDisplay(now, design.clock);
    final fontSize = design.clock.fontSize;

    // Parse text color
    final hex = design.clock.color.replaceFirst('#', '');
    final textColor = hex.length == 6
        ? Color(int.parse('FF$hex', radix: 16))
        : Colors.white;

    // Parse alignment
    TextAlign alignment;
    switch (design.clock.alignment) {
      case 'left':
        alignment = TextAlign.left;
      case 'right':
        alignment = TextAlign.right;
      default:
        alignment = TextAlign.center;
    }

    // Background
    BoxDecoration backgroundDecoration;
    switch (design.background.type) {
      case BackgroundType.solid:
        final bgHex = (design.background.solidColor ?? '#1A1A2E')
            .replaceFirst('#', '');
        backgroundDecoration = BoxDecoration(
          color: Color(int.parse('FF$bgHex', radix: 16)),
        );
      case BackgroundType.gradient:
        final colors = design.background.gradientColors
                ?.map((h) => Color(int.parse('FF${h.replaceFirst('#', '')}', radix: 16)))
                .toList() ??
            [const Color(0xFF1A1A2E), const Color(0xFF16213E)];
        backgroundDecoration = BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      default:
        backgroundDecoration = const BoxDecoration(color: Colors.black87);
    }

    return RepaintBoundary(
      child: Container(
        width: _previewWidth.toDouble(),
        height: (_previewWidth / _previewAspectRatio).toDouble(),
        decoration: backgroundDecoration,
        child: Stack(
          children: [
            // Background image
            if (design.background.type == BackgroundType.image &&
                design.background.imagePath != null)
              Positioned.fill(
                child: Image.file(
                  File(design.background.imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),

            // Overlay
            if (design.background.type == BackgroundType.image &&
                design.background.overlayOpacity > 0)
              Positioned.fill(
                child: Container(
                  color: design.background.overlayMode == OverlayMode.dark
                      ? Colors.black
                          .withValues(alpha: design.background.overlayOpacity)
                      : Colors.white
                          .withValues(alpha: design.background.overlayOpacity),
                ),
              ),

            // Text content
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (display.day.isNotEmpty)
                    Text(
                      display.day,
                      textAlign: alignment,
                      style: TextStyle(
                        fontSize: fontSize * 0.55,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        shadows: design.background.textShadow
                            ? const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(1, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  if (display.date.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                          top: display.day.isNotEmpty ? 8 : 0),
                      child: Text(
                        display.date,
                        textAlign: alignment,
                        style: TextStyle(
                          fontSize: fontSize * 0.6,
                          fontWeight: FontWeight.w400,
                          color: textColor.withValues(alpha: 0.85),
                          shadows: design.background.textShadow
                              ? const [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                    offset: Offset(1, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: (display.day.isNotEmpty || display.date.isNotEmpty)
                          ? 16
                          : 0,
                    ),
                    child: Text(
                      display.time,
                      textAlign: alignment,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: 1.2,
                        shadows: design.background.textShadow
                            ? const [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(1, 1),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Watermark (bottom-right corner)
            Positioned(
              bottom: 16,
              right: 16,
              child: Text(
                'Photo Clock Widget',
                style: TextStyle(
                  fontSize: 14,
                  color: textColor.withValues(alpha: 0.4),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
