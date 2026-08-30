import 'clock_config.dart';

/// A visual preset that bundles a name, description, and a [ClockConfig].
///
/// Presets are identified by a unique [id]. Some presets are locked and
/// require a rewarded ad watch or premium purchase to unlock.
class Preset {
  /// Unique identifier, e.g. "basic1", "sunset_orange"
  final String id;

  /// Display name shown in the UI.
  final String name;

  /// Short description of the preset style.
  final String description;

  /// The clock configuration for this preset.
  final ClockConfig config;

  /// Whether this preset requires unlocking (rewarded ad or premium).
  final bool isLocked;

  const Preset({
    required this.id,
    required this.name,
    required this.description,
    required this.config,
    this.isLocked = false,
  });

  /// Factory for creating a preset from JSON.
  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      config: ClockConfig.fromJson(json['config'] as Map<String, dynamic>),
      isLocked: json['isLocked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'config': config.toJson(),
      'isLocked': isLocked,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Preset &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          config == other.config;

  @override
  int get hashCode => Object.hash(id, name, config);
}
