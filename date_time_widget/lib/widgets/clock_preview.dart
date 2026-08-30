import 'dart:async';

import 'package:flutter/material.dart';

import '../models/clock_config.dart';
import '../utils/date_formatter.dart';

/// Live clock preview that updates every second.
///
/// Reads format from [ClockConfig] and renders the time, date, and day
/// of week using [DateFormatter].
class ClockPreview extends StatefulWidget {
  final ClockConfig config;

  const ClockPreview({super.key, required this.config});

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

  @override
  Widget build(BuildContext context) {
    final display = DateFormatter.buildDisplay(_now, widget.config);
    final fontSize = widget.config.fontSize;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Day of week (e.g. "Sunday")
          if (display.day.isNotEmpty)
            Text(
              display.day,
              textAlign: _alignment,
              style: TextStyle(
                fontSize: fontSize * 0.55,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),

          // Date (e.g. "30 August 2026")
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
                ),
              ),
            ),

          // Time (e.g. "08:35")
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
