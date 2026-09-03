import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import '../models/widget_design.dart';

/// Maximum dimension (width or height) for source images stored in app documents.
/// Plan5 §3: "max cạnh 1600px".
const int maxSourceDimension = 1600;

/// Absolute ceiling for generic resizing helpers (see [resizeForWidget]).
/// Plan9: the widget-background bake path no longer uses this — it uses
/// [kWidgetBgBakeWidth]/[kWidgetBgBakeHeight] (360×160, Binder-safe).
const int maxBakedDimension = 480;

/// Baked widget-background size pushed to native widgets.
/// Plan9: raw ARGB must stay well under the RemoteViews/Binder limit
/// (~1 MB) — 360×160×4 ≈ 230 KB is a safe budget.
const int kWidgetBgBakeWidth = 360;
const int kWidgetBgBakeHeight = 160;

/// Utility for copying and resizing images for widget designs.
///
/// Source images are resized to fit within [maxSourceDimension] while
/// maintaining aspect ratio. Baked bitmaps are sized to the actual
/// widget instance dimensions, capped at [maxBakedDimension].
class ImageUtils {
  /// Resize an image file to fit within [maxDimension] on the longest side.
  /// Returns the resized image as PNG bytes.
  ///
  /// This is used for storing the "source" image that can later be
  /// re-cropped/resized for specific widget instances.
  static Future<Uint8List> resizeSource(Uint8List imageBytes) async {
    return _resizeToFit(imageBytes, maxSourceDimension);
  }

  /// Resize an image file to exact pixel dimensions for a widget instance.
  /// The output is capped at [maxBakedDimension] on each side.
  ///
  /// [targetWidth]/[targetHeight] are the actual pixel dimensions of the
  /// widget instance (from AppWidgetManager.getAppWidgetOptions).
  static Future<Uint8List> resizeForWidget(
    Uint8List imageBytes, {
    required int targetWidth,
    required int targetHeight,
  }) async {
    // Cap at maxBakedDimension
    final cappedWidth = min(targetWidth, maxBakedDimension);
    final cappedHeight = min(targetHeight, maxBakedDimension);
    return _resizeToExact(imageBytes, cappedWidth, cappedHeight);
  }

  /// Decode image bytes and return dimensions.
  static Future<Size> decodeDimensions(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    image.dispose();
    return size;
  }

  /// Internal: resize to fit within maxDimension, maintaining aspect ratio.
  static Future<Uint8List> _resizeToFit(
    Uint8List bytes,
    int maxDimension,
  ) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final width = image.width;
    final height = image.height;

    // Calculate target dimensions
    int targetWidth = width;
    int targetHeight = height;

    if (width > maxDimension || height > maxDimension) {
      final scale = maxDimension / max(width, height);
      targetWidth = (width * scale).round();
      targetHeight = (height * scale).round();
    }

    final result = await _renderImage(image, targetWidth, targetHeight);
    image.dispose();
    return result;
  }

  /// Internal: resize to exact dimensions.
  static Future<Uint8List> _resizeToExact(
    Uint8List bytes,
    int targetWidth,
    int targetHeight,
  ) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final result = await _renderImage(image, targetWidth, targetHeight);
    image.dispose();
    return result;
  }

  /// Render a ui.Image to PNG bytes at the specified dimensions.
  static Future<Uint8List> _renderImage(
    ui.Image source,
    int width,
    int height,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      source,
      Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final result = await picture.toImage(width, height);
    final byteData = await result.toByteData(format: ui.ImageByteFormat.png);

    picture.dispose();
    result.dispose();

    return byteData!.buffer.asUint8List();
  }

  /// Copy image bytes to a file path, resizing to fit within maxDimension.
  /// Returns the path to the saved file.
  static Future<String> copyAndResizeSource({
    required Uint8List imageBytes,
    required String destinationPath,
  }) async {
    final resized = await resizeSource(imageBytes);
    final file = File(destinationPath);
    await file.writeAsBytes(resized);
    return destinationPath;
  }

  /// Save baked bitmap bytes to a file.
  static Future<String> saveBakedBitmap({
    required Uint8List bitmapBytes,
    required String destinationPath,
  }) async {
    final file = File(destinationPath);
    await file.writeAsBytes(bitmapBytes);
    return destinationPath;
  }

  /// Parse a hex color string like "#FF0000" or "FF0000".
  /// Returns [fallback] if parsing fails.
  static Color _parseHexColor(String? hex, Color fallback) {
    if (hex == null) return fallback;
    try {
      final clean = hex.replaceFirst('#', '');
      if (clean.length != 6 && clean.length != 8) return fallback;
      return Color(int.parse('FF$clean', radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  /// Bake a [BackgroundConfig] into a PNG bitmap at widget size.
  ///
  /// For [BackgroundType.none], returns `null` (no bitmap needed).
  /// For [BackgroundType.solid] / [BackgroundType.gradient], renders a
  /// color/gradient rectangle. For [BackgroundType.image], loads,
  /// crops, and overlays the source image.
  static Future<Uint8List?> bakeBackgroundBitmap({
    required BackgroundConfig background,
    required int width,
    required int height,
  }) async {
    if (background.type == BackgroundType.none) return null;

    final cappedW = min(width, maxBakedDimension);
    final cappedH = min(height, maxBakedDimension);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(cappedW.toDouble(), cappedH.toDouble());

    try {
      switch (background.type) {
        case BackgroundType.solid:
          final color = _parseHexColor(
            background.solidColor,
            const Color(0xFF1A1A2E),
          );
          canvas.drawRect(
            Rect.fromLTWH(0, 0, size.width, size.height),
            Paint()..color = color,
          );

        case BackgroundType.gradient:
          final rawColors = background.gradientColors
                  ?.map((h) => _parseHexColor(h, const Color(0xFF1A1A2E)))
                  .toList() ??
              [];
          // LinearGradient requires ≥ 2 colors
          final colors = rawColors.length >= 2
              ? rawColors
              : [
                  const Color(0xFF1A1A2E),
                  const Color(0xFF16213E),
                ];
          final rect =
              Rect.fromLTWH(0, 0, size.width, size.height);
          final gradient = LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );
          canvas.drawRect(
            rect,
            Paint()..shader = gradient.createShader(rect),
          );

        case BackgroundType.image:
          final path = background.imagePath;
          if (path == null) return null;
          final file = File(path);
          if (!await file.exists()) return null;

          ui.Image? src;
          try {
            final bytes = Uint8List.fromList(await file.readAsBytes());
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            src = frame.image;

            // Crop region calculation with safety clamps
            final srcW = src.width.toDouble();
            final srcH = src.height.toDouble();
            final scale =
                background.cropScale.clamp(0.01, 10.0); // prevent div-by-zero
            var cropW = srcW / scale;
            var cropH = srcH / scale;
            cropW = cropW.clamp(1.0, srcW); // at least 1px, at most full
            cropH = cropH.clamp(1.0, srcH);

            final offsetX =
                background.cropOffsetX.clamp(0.0, 1.0);
            final offsetY =
                background.cropOffsetY.clamp(0.0, 1.0);
            var cropX = srcW * offsetX - cropW / 2;
            var cropY = srcH * offsetY - cropH / 2;
            cropX = cropX.clamp(0.0, max(0.0, srcW - cropW));
            cropY = cropY.clamp(0.0, max(0.0, srcH - cropH));

            canvas.drawImageRect(
              src,
              Rect.fromLTWH(cropX, cropY, cropW, cropH),
              Rect.fromLTWH(0, 0, size.width, size.height),
              Paint()..filterQuality = FilterQuality.high,
            );

            // Overlay
            if (background.overlayMode != OverlayMode.none &&
                background.overlayOpacity > 0) {
              final overlayColor =
                  background.overlayMode == OverlayMode.dark
                      ? const Color(0xFF000000)
                      : const Color(0xFFFFFFFF);
              canvas.drawRect(
                Rect.fromLTWH(0, 0, size.width, size.height),
                Paint()
                  ..color = overlayColor
                      .withValues(alpha: background.overlayOpacity),
              );
            }
          } finally {
            src?.dispose(); // always release native image memory
          }

        case BackgroundType.none:
        // Already handled above, but exhaustive switch needs it.
        return null;
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(cappedW, cappedH);
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      image.dispose();

      return byteData?.buffer.asUint8List();
    } catch (_) {
      // Any render error → return null, caller falls back to no background
      return null;
    }
  }
}
