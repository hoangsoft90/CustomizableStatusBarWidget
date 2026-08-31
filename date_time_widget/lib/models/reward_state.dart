import 'dart:convert';

/// Tracks daily reward entitlement: how many ads the user has watched
/// today and which presets they've unlocked for today's use.
///
/// Persisted separately from ClockConfig in SharedPreferences
/// under key "reward_state".
class RewardState {
  /// Local date string (yyyy-MM-dd) when this state was last reset.
  final String date;

  /// Number of rewarded ads watched today (max 2).
  final int unlockCount;

  /// Preset IDs unlocked for today's use.
  final List<String> unlockedToday;

  const RewardState({
    required this.date,
    this.unlockCount = 0,
    this.unlockedToday = const [],
  });

  /// Create empty state for a given date.
  factory RewardState.empty(String date) => RewardState(date: date);

  /// Create from a JSON map.
  factory RewardState.fromJson(Map<String, dynamic> json) {
    return RewardState(
      date: json['date'] as String? ?? '',
      unlockCount: json['unlockCount'] as int? ?? 0,
      unlockedToday: (json['unlockedToday'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }

  /// Create from a JSON string.
  factory RewardState.fromJsonString(String jsonString) {
    return RewardState.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>);
  }

  /// Convert to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'unlockCount': unlockCount,
      'unlockedToday': List<String>.from(unlockedToday),
    };
  }

  /// Convert to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Create a copy with selective overrides.
  RewardState copyWith({
    String? date,
    int? unlockCount,
    List<String>? unlockedToday,
  }) {
    return RewardState(
      date: date ?? this.date,
      unlockCount: unlockCount ?? this.unlockCount,
      unlockedToday: unlockedToday ?? this.unlockedToday,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RewardState &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          unlockCount == other.unlockCount &&
          _listEquals(unlockedToday, other.unlockedToday);

  @override
  int get hashCode => Object.hash(
        date,
        unlockCount,
        Object.hashAll(unlockedToday),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'RewardState(${toJson()})';
}
