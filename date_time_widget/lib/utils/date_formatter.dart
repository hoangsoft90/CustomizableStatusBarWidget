import '../models/clock_config.dart';

/// Formats date, time, and day-of-week strings based on [ClockConfig].
///
/// Uses Dart's built-in `DateTime` formatting — no external date library.
class DateFormatter {
  /// Format the time portion (e.g. "08:35", "8:35 PM").
  static String formatTime(DateTime now, ClockConfig config) {
    String result = config.timeFormat;
    final h24 = now.hour;
    final h12 = h24 == 0 ? 12 : (h24 > 12 ? h24 - 12 : h24);
    final mm = _pad(now.minute);
    final period = h24 >= 12 ? 'PM' : 'AM';

    result = result.replaceAll('HH', _pad(h24));
    result = result.replaceAll('hh', _pad(h12));
    result = result.replaceAll('mm', mm);

    result = result.replaceAll('a', period);

    return result;
  }

  /// Format the date portion using the pattern in [ClockConfig.format].
  static String formatDate(DateTime now, ClockConfig config) {
    // If format contains only time tokens, no date to show
    final dateTokens = [
      'yyyy', 'yy', 'MMMM', 'MMM', 'MM', 'dd', 'd',
      'EEEE', 'EEE', 'EE', 'E',
    ];
    final hasDateToken = dateTokens.any((t) => config.format.contains(t));
    if (!hasDateToken) return '';

    return _formatPattern(now, config.format);
  }

  /// Format the day of week (e.g. "Sunday", "Sun", "SUN").
  static String formatDay(DateTime now, ClockConfig config) {
    final names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final shortNames = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];

    final dayIndex = now.weekday - 1; // 0 = Monday

    // Determine if day is part of the format string or should be separate
    final format = config.format;
    final hasDayInFormat = format.contains('EEEE') ||
        format.contains('EEE') ||
        format.contains('EE') ||
        format.contains('E');

    if (!config.showDay) return '';
    if (hasDayInFormat) return ''; // Day is already in formatDate output

    // Use uppercase style matching the mockup ("SUN")
    if (format.toUpperCase().contains('EEE') ||
        format.toUpperCase().contains('EE')) {
      return shortNames[dayIndex].toUpperCase();
    }

    return names[dayIndex];
  }

  /// Check if the format string contains day-of-week tokens.
  static bool _hasDayTokens(String format) {
    return format.contains('EEEE') ||
        format.contains('EEE') ||
        format.contains('EE') ||
        format.contains('E');
  }

  /// Check if the format string contains date tokens (not day-only).
  static bool _hasDateTokens(String format) {
    final dateTokens = ['yyyy', 'yy', 'MMMM', 'MMM', 'MM', 'dd', 'd'];
    return dateTokens.any((t) => format.contains(t));
  }

  /// Build a display model from config — returns lines to show.
  static ClockDisplay buildDisplay(DateTime now, ClockConfig config) {
    final time = formatTime(now, config);

    // Check if the format mixes date + day tokens
    final format = config.format;
    final dayOnly = _hasDayTokens(format) && !_hasDateTokens(format);
    final dateOnly = _hasDateTokens(format) && !_hasDayTokens(format);
    final mixed = _hasDayTokens(format) && _hasDateTokens(format);

    String dayLine = '';
    String dateLine = '';

    if (mixed) {
      // "EEEE, dd MMM" → single line with both day and date
      dateLine = _formatPattern(now, format);
    } else if (dayOnly) {
      dayLine = formatDate(now, config); // uses format pattern
      if (!config.showDay) dayLine = '';
    } else if (dateOnly) {
      dateLine = formatDate(now, config);
    } else {
      // Fallback: show day + date separately
      if (config.showDay) dayLine = formatDay(now, config);
      if (config.showDate) dateLine = formatDate(now, config);
    }

    // If dayLine is empty and we have day-of-week info, try formatDay
    if (dayLine.isEmpty && config.showDay && !_hasDayTokens(format)) {
      dayLine = formatDay(now, config);
    }

    return ClockDisplay(
      time: time,
      day: dayLine,
      date: dateLine,
    );
  }

  // ── Internal helpers ─────────────────────────────────────

  static String _formatPattern(DateTime now, String pattern) {
    var result = pattern;

    // Year
    result = result.replaceAll('yyyy', '${now.year}');
    result = result.replaceAll('yy', '${now.year % 100}');

    // Month
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthShort = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    result = result.replaceAll('MMMM', monthNames[now.month - 1]);
    result = result.replaceAll('MMM', monthShort[now.month - 1]);
    result = result.replaceAll('MM', _pad(now.month));

    // Day
    result = result.replaceAll('dd', _pad(now.day));
    // 'd' without 'dd' — only if not preceded by 'd'
    result = result.replaceAll(RegExp(r'(?<!d)d(?!d)'), '${now.day}');

    // Day of week
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    final dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    result = result.replaceAll('EEEE', dayNames[now.weekday - 1]);
    result = result.replaceAll('EEE', dayShort[now.weekday - 1]);
    result = result.replaceAll(RegExp(r'(?<!E)E(?!E)'), '${now.weekday}');

    return result;
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}

/// Data class for the clock display lines.
class ClockDisplay {
  final String time;
  final String day;
  final String date;

  const ClockDisplay({
    required this.time,
    this.day = '',
    this.date = '',
  });
}
