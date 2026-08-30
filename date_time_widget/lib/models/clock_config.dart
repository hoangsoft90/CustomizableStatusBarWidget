import 'dart:convert';

/// Clock configuration model matching the JSON schema in plan1_final.md §5.
class ClockConfig {
  /// Date format string, e.g. "EEE dd MMM", "DD/MM/YYYY"
  final String format;

  /// Time format, e.g. "HH:mm" (24h) or "hh:mm a" (12h)
  final String timeFormat;

  /// Whether to show seconds in the clock
  final bool showSeconds;

  /// Whether to show the date
  final bool showDate;

  /// Whether to show the day of week
  final bool showDay;

  /// Font size for the clock display
  final double fontSize;

  /// Text color as hex string, e.g. "#FFFFFF"
  final String color;

  /// Text alignment: "left", "center", or "right"
  final String alignment;

  /// Whether notification icon is enabled
  final bool notificationEnabled;

  /// Whether floating bar is enabled (P1)
  final bool floatingBarEnabled;

  /// List of unlocked preset IDs
  final List<String> unlockedPresets;

  /// Whether the user has purchased the premium IAP
  final bool isPremium;

  const ClockConfig({
    this.format = 'EEE dd MMM',
    this.timeFormat = 'HH:mm',
    this.showSeconds = false,
    this.showDate = true,
    this.showDay = true,
    this.fontSize = 32,
    this.color = '#FFFFFF',
    this.alignment = 'center',
    this.notificationEnabled = false,
    this.floatingBarEnabled = false,
    this.unlockedPresets = const ['basic1', 'basic2'],
    this.isPremium = false,
  });

  /// Default config used on first launch.
  factory ClockConfig.defaults() => const ClockConfig();

  /// Create from a JSON map.
  factory ClockConfig.fromJson(Map<String, dynamic> json) {
    return ClockConfig(
      format: json['format'] as String? ?? 'EEE dd MMM',
      timeFormat: json['timeFormat'] as String? ?? 'HH:mm',
      showSeconds: json['showSeconds'] as bool? ?? false,
      showDate: json['showDate'] as bool? ?? true,
      showDay: json['showDay'] as bool? ?? true,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 32,
      color: json['color'] as String? ?? '#FFFFFF',
      alignment: json['alignment'] as String? ?? 'center',
      notificationEnabled: json['notificationEnabled'] as bool? ?? false,
      floatingBarEnabled: json['floatingBarEnabled'] as bool? ?? false,
      unlockedPresets: (json['unlockedPresets'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['basic1', 'basic2'],
      isPremium: json['isPremium'] as bool? ?? false,
    );
  }

  /// Create from a JSON string.
  factory ClockConfig.fromJsonString(String jsonString) {
    return ClockConfig.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Convert to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'format': format,
      'timeFormat': timeFormat,
      'showSeconds': showSeconds,
      'showDate': showDate,
      'showDay': showDay,
      'fontSize': fontSize,
      'color': color,
      'alignment': alignment,
      'notificationEnabled': notificationEnabled,
      'floatingBarEnabled': floatingBarEnabled,
      'unlockedPresets': List<String>.from(unlockedPresets),
      'isPremium': isPremium,
    };
  }

  /// Convert to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Create a copy with selective overrides.
  ClockConfig copyWith({
    String? format,
    String? timeFormat,
    bool? showSeconds,
    bool? showDate,
    bool? showDay,
    double? fontSize,
    String? color,
    String? alignment,
    bool? notificationEnabled,
    bool? floatingBarEnabled,
    List<String>? unlockedPresets,
    bool? isPremium,
  }) {
    return ClockConfig(
      format: format ?? this.format,
      timeFormat: timeFormat ?? this.timeFormat,
      showSeconds: showSeconds ?? this.showSeconds,
      showDate: showDate ?? this.showDate,
      showDay: showDay ?? this.showDay,
      fontSize: fontSize ?? this.fontSize,
      color: color ?? this.color,
      alignment: alignment ?? this.alignment,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      floatingBarEnabled: floatingBarEnabled ?? this.floatingBarEnabled,
      unlockedPresets: unlockedPresets ?? this.unlockedPresets,
      isPremium: isPremium ?? this.isPremium,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClockConfig &&
          runtimeType == other.runtimeType &&
          format == other.format &&
          timeFormat == other.timeFormat &&
          showSeconds == other.showSeconds &&
          showDate == other.showDate &&
          showDay == other.showDay &&
          fontSize == other.fontSize &&
          color == other.color &&
          alignment == other.alignment &&
          notificationEnabled == other.notificationEnabled &&
          floatingBarEnabled == other.floatingBarEnabled &&
          _listEquals(unlockedPresets, other.unlockedPresets) &&
          isPremium == other.isPremium;

  @override
  int get hashCode => Object.hash(
        format,
        timeFormat,
        showSeconds,
        showDate,
        showDay,
        fontSize,
        color,
        alignment,
        notificationEnabled,
        floatingBarEnabled,
        Object.hashAll(unlockedPresets),
        isPremium,
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'ClockConfig(${toJson()})';
}
