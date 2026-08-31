import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Maximum dimension (width or height) for source images stored in app documents.
/// Plan5 §3: "max cạnh 1600px".
const int maxSourceDimension = 1600;

/// Maximum dimension for baked widget bitmaps.
/// Plan5 §2.3: "trần tuyệt đối 480x480px cho size lớn nhất (4x2)".
const int maxBakedDimension = 480;

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
}
