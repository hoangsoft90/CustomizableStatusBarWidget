import 'clock_config.dart';

/// Background type for a widget design.
enum BackgroundType { none, solid, gradient, image }

/// Overlay mode applied on top of background image.
enum OverlayMode { none, dark, light }

/// Configuration for the background layer of a [WidgetDesign].
///
/// Supports solid color, gradient, or image background with optional
/// blur, overlay, and auto text contrast.
class BackgroundConfig {
  /// The type of background.
  final BackgroundType type;

  /// Solid color hex string, e.g. "#1A1A2E". Used when [type] is [BackgroundType.solid].
  final String? solidColor;

  /// Gradient colors hex strings. Used when [type] is [BackgroundType.gradient].
  /// Minimum 2 colors.
  final List<String>? gradientColors;

  /// Local file path to the source image (already copied into app documents).
  /// Used when [type] is [BackgroundType.image].
  final String? imagePath;

  /// Scale factor for crop region (0.0–1.0). Default 1.0 = full image.
  final double cropScale;

  /// Offset of crop region center as fraction of image size (0.0–1.0).
  /// (0.5, 0.5) = center of image.
  final double cropOffsetX;
  final double cropOffsetY;

  /// Gaussian blur sigma. 0 = off. Suggested 6–8 when enabled.
  final double blurSigma;

  /// Overlay opacity (0.0–0.7). 0 = no overlay.
  final double overlayOpacity;

  /// Overlay mode: dark, light, or none.
  final OverlayMode overlayMode;

  /// Automatically adjust text color for contrast against background.
  final bool autoTextContrast;

  /// Add shadow behind text for readability.
  final bool textShadow;

  const BackgroundConfig({
    this.type = BackgroundType.none,
    this.solidColor,
    this.gradientColors,
    this.imagePath,
    this.cropScale = 1.0,
    this.cropOffsetX = 0.5,
    this.cropOffsetY = 0.5,
    this.blurSigma = 0.0,
    this.overlayOpacity = 0.0,
    this.overlayMode = OverlayMode.none,
    this.autoTextContrast = true,
    this.textShadow = true,
  });

  /// Default no-background config.
  factory BackgroundConfig.none() => const BackgroundConfig();

  /// Create from JSON.
  factory BackgroundConfig.fromJson(Map<String, dynamic> json) {
    return BackgroundConfig(
      type: BackgroundType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BackgroundType.none,
      ),
      solidColor: json['solidColor'] as String?,
      gradientColors: (json['gradientColors'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imagePath: json['imagePath'] as String?,
      cropScale: (json['cropScale'] as num?)?.toDouble() ?? 1.0,
      cropOffsetX: (json['cropOffsetX'] as num?)?.toDouble() ?? 0.5,
      cropOffsetY: (json['cropOffsetY'] as num?)?.toDouble() ?? 0.5,
      blurSigma: (json['blurSigma'] as num?)?.toDouble() ?? 0.0,
      overlayOpacity: (json['overlayOpacity'] as num?)?.toDouble() ?? 0.0,
      overlayMode: OverlayMode.values.firstWhere(
        (m) => m.name == json['overlayMode'],
        orElse: () => OverlayMode.none,
      ),
      autoTextContrast: json['autoTextContrast'] as bool? ?? true,
      textShadow: json['textShadow'] as bool? ?? true,
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'solidColor': solidColor,
      'gradientColors': gradientColors,
      'imagePath': imagePath,
      'cropScale': cropScale,
      'cropOffsetX': cropOffsetX,
      'cropOffsetY': cropOffsetY,
      'blurSigma': blurSigma,
      'overlayOpacity': overlayOpacity,
      'overlayMode': overlayMode.name,
      'autoTextContrast': autoTextContrast,
      'textShadow': textShadow,
    };
  }

  /// Create a copy with selective overrides.
  BackgroundConfig copyWith({
    BackgroundType? type,
    String? solidColor,
    List<String>? gradientColors,
    String? imagePath,
    double? cropScale,
    double? cropOffsetX,
    double? cropOffsetY,
    double? blurSigma,
    double? overlayOpacity,
    OverlayMode? overlayMode,
    bool? autoTextContrast,
    bool? textShadow,
  }) {
    return BackgroundConfig(
      type: type ?? this.type,
      solidColor: solidColor ?? this.solidColor,
      gradientColors: gradientColors ?? this.gradientColors,
      imagePath: imagePath ?? this.imagePath,
      cropScale: cropScale ?? this.cropScale,
      cropOffsetX: cropOffsetX ?? this.cropOffsetX,
      cropOffsetY: cropOffsetY ?? this.cropOffsetY,
      blurSigma: blurSigma ?? this.blurSigma,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      overlayMode: overlayMode ?? this.overlayMode,
      autoTextContrast: autoTextContrast ?? this.autoTextContrast,
      textShadow: textShadow ?? this.textShadow,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackgroundConfig &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          solidColor == other.solidColor &&
          _listEquals(gradientColors, other.gradientColors) &&
          imagePath == other.imagePath &&
          cropScale == other.cropScale &&
          cropOffsetX == other.cropOffsetX &&
          cropOffsetY == other.cropOffsetY &&
          blurSigma == other.blurSigma &&
          overlayOpacity == other.overlayOpacity &&
          overlayMode == other.overlayMode &&
          autoTextContrast == other.autoTextContrast &&
          textShadow == other.textShadow;

  @override
  int get hashCode => Object.hash(
        type,
        solidColor,
        Object.hashAll(gradientColors ?? []),
        imagePath,
        cropScale,
        cropOffsetX,
        cropOffsetY,
        blurSigma,
        overlayOpacity,
        overlayMode,
        autoTextContrast,
        textShadow,
      );

  static bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'BackgroundConfig(${toJson()})';
}

/// A user-created or cloned design that bundles a [ClockConfig] with
/// a [BackgroundConfig] for personalization.
///
/// Designs are persisted as a JSON list in SharedPreferences under
/// key "widget_designs". Source images are stored in app documents.
class WidgetDesign {
  /// Unique identifier (UUID v4).
  final String id;

  /// User-editable display name, e.g. "Home", "Night", "Travel".
  final String name;

  /// The clock configuration for this design.
  final ClockConfig clock;

  /// Background configuration for this design.
  final BackgroundConfig background;

  /// When this design was last modified.
  final DateTime updatedAt;

  const WidgetDesign({
    required this.id,
    required this.name,
    required this.clock,
    this.background = const BackgroundConfig(),
    required this.updatedAt,
  });

  /// Create from JSON.
  factory WidgetDesign.fromJson(Map<String, dynamic> json) {
    return WidgetDesign(
      id: json['id'] as String,
      name: json['name'] as String,
      clock: ClockConfig.fromJson(json['clock'] as Map<String, dynamic>),
      background: json['background'] != null
          ? BackgroundConfig.fromJson(json['background'] as Map<String, dynamic>)
          : const BackgroundConfig(),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'clock': clock.toJson(),
      'background': background.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with selective overrides.
  WidgetDesign copyWith({
    String? id,
    String? name,
    ClockConfig? clock,
    BackgroundConfig? background,
    DateTime? updatedAt,
  }) {
    return WidgetDesign(
      id: id ?? this.id,
      name: name ?? this.name,
      clock: clock ?? this.clock,
      background: background ?? this.background,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WidgetDesign &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          clock == other.clock &&
          background == other.background;

  @override
  int get hashCode => Object.hash(id, name, clock, background);

  @override
  String toString() => 'WidgetDesign(${toJson()})';
}
