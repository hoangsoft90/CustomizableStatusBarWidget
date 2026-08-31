import 'dart:io';

import 'package:flutter/material.dart';

/// Result from the crop screen — crop region as fractions of image size.
class CropResult {
  /// Scale factor (1.0 = no zoom, >1 = zoomed in).
  final double scale;

  /// Offset of crop center as fraction of image size (0.0–1.0).
  /// (0.5, 0.5) = center of image.
  final double offsetX;
  final double offsetY;

  const CropResult({
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });
}

/// Full-screen crop screen with zoom + pan.
///
/// User can pinch to zoom and drag to pan. The crop region is the
/// visible area of the image at the current zoom/pan state.
///
/// Returns a [CropResult] on confirmation, or null on cancel.
class CropScreen extends StatefulWidget {
  final File imageFile;

  const CropScreen({super.key, required this.imageFile});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  double _scale = 1.0;
  double _previousScale = 1.0;
  Offset _offset = Offset.zero;
  Offset _previousOffset = Offset.zero;
  Offset _focalPoint = Offset.zero;

  // Track canvas dimensions for offset clamping
  Size _canvasSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Crop Image'),
        actions: [
          TextButton(
            onPressed: _onConfirm,
            child: const Text(
              'Done',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
            return GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: _onScaleUpdate,
              child: Image.file(
                widget.imageFile,
                fit: BoxFit.contain,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (frame != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _measureImage();
                    });
                  }
                  return child;
                },
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            // Zoom indicator
            Text(
              '${(_scale * 100).round()}%',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            TextButton(
              onPressed: _resetCrop,
              child: const Text('Reset', style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
      ),
    );
  }

  void _measureImage() {
    // We'll use the rendered image size for offset bounds
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      _canvasSize = renderBox.size;
    }
  }

  void _onScaleStart(ScaleStartDetails details) {
    _previousScale = _scale;
    _previousOffset = _offset;
    _focalPoint = details.focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Apply scale
      _scale = (_previousScale * details.scale).clamp(1.0, 5.0);

      // Apply pan
      final dx = details.focalPoint.dx - _focalPoint.dx;
      final dy = details.focalPoint.dy - _focalPoint.dy;
      _offset = Offset(
        _previousOffset.dx + dx,
        _previousOffset.dy + dy,
      );

      // Clamp offset based on scale
      _clampOffset();
    });
  }

  void _clampOffset() {
    if (_canvasSize == Size.zero) return;
    final maxOffset = (_scale - 1) * _canvasSize.shortestSide / 2;
    _offset = Offset(
      _offset.dx.clamp(-maxOffset, maxOffset),
      _offset.dy.clamp(-maxOffset, maxOffset),
    );
  }

  void _resetCrop() {
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  void _onConfirm() {
    // Convert canvas offset to image-fraction offset
    // offset ranges from -maxOffset to +maxOffset
    // We normalize to 0.0–1.0 where 0.5 is center
    final maxOffset = (_scale - 1) * _canvasSize.shortestSide / 2;
    final offsetX = maxOffset > 0
        ? 0.5 + (_offset.dx / (2 * maxOffset)) * 0.5
        : 0.5;
    final offsetY = maxOffset > 0
        ? 0.5 + (_offset.dy / (2 * maxOffset)) * 0.5
        : 0.5;

    Navigator.of(context).pop(CropResult(
      scale: _scale,
      offsetX: offsetX.clamp(0.0, 1.0),
      offsetY: offsetY.clamp(0.0, 1.0),
    ));
  }
}
