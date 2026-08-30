import 'clock_config.dart';

/// Supported home-screen widget sizes.
///
/// Each size maps to an `AppWidgetProviderInfo` `minWidth`/`minHeight`
/// cell count in the Android widget system.
enum WidgetSize {
  /// 2×1 cells
  twoByOne(2, 1),

  /// 3×1 cells
  threeByOne(3, 1),

  /// 4×1 cells
  fourByOne(4, 1),

  /// 4×2 cells
  fourByTwo(4, 2);

  final int columns;
  final int rows;

  const WidgetSize(this.columns, this.rows);

  /// Android cell width: each cell ≈ 70dp
  int get minWidthDp => columns * 70;

  /// Android cell height: each cell ≈ 70dp
  int get minHeightDp => rows * 70;

  /// Label for the widget picker, e.g. "4×2"
  String get label => '$columns×$rows';
}

/// Configuration data sent from Flutter to the native Android
/// [AppWidgetProvider] via MethodChannel.
class WidgetConfig {
  /// The clock configuration to render in the widget.
  final ClockConfig clockConfig;

  /// The size of the widget.
  final WidgetSize size;

  const WidgetConfig({
    required this.clockConfig,
    this.size = WidgetSize.fourByOne,
  });

  /// Convert to a map suitable for MethodChannel arguments.
  Map<String, dynamic> toMap() {
    return {
      ...clockConfig.toJson(),
      'widgetSize': size.name,
      'columns': size.columns,
      'rows': size.rows,
    };
  }

  factory WidgetConfig.fromMap(Map<String, dynamic> map) {
    final sizeStr = map['widgetSize'] as String?;
    final size = WidgetSize.values.firstWhere(
      (s) => s.name == sizeStr,
      orElse: () => WidgetSize.fourByOne,
    );
    return WidgetConfig(
      clockConfig: ClockConfig.fromJson(map),
      size: size,
    );
  }
}
