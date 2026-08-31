# Widget Design Model

## Purpose

Defines the data models for user-created designs that bundle a `ClockConfig` with a `BackgroundConfig`. Used by My Designs feature (plan5 §5) and background image pipeline (plan5 §4).

## Requirements

### R1: BackgroundConfig — 12-field immutable model

`BackgroundConfig` stores all background-related settings: type, solidColor, gradientColors, imagePath, cropScale, cropOffsetX/Y, blurSigma, overlayOpacity, overlayMode, autoTextContrast, textShadow.

**Scenario: Default config**
- Given `const BackgroundConfig()`
- Then `type == BackgroundType.none`
- And `autoTextContrast == true`
- And `textShadow == true`
- And `blurSigma == 0.0`
- Reference: `lib/models/widget_design.dart:38-51`

**Scenario: Image background config**
- Given `BackgroundConfig(type: BackgroundType.image, imagePath: '/data/.../abc.jpg', overlayOpacity: 0.35, overlayMode: OverlayMode.dark)`
- Then all fields match the provided values
- Reference: `lib/models/widget_design.dart:38-51`

### R2: BackgroundConfig — JSON roundtrip

`fromJson` and `toJson` correctly serialize/deserialize all 12 fields including enum values as strings.

**Scenario: Serialize and deserialize**
- Given `BackgroundConfig(type: BackgroundType.gradient, gradientColors: ['#FF0000', '#0000FF'], overlayOpacity: 0.5)`
- When `toJson()` then `fromJson()` is called
- Then the result equals the original
- Reference: `lib/models/widget_design.dart:57-75`, `78-93`

### R3: BackgroundConfig — copyWith

`copyWith` creates a new instance with selective overrides while preserving other fields.

**Scenario: Copy with overlay change**
- Given `BackgroundConfig(type: BackgroundType.image, overlayOpacity: 0.35)`
- When `copyWith(overlayOpacity: 0.5)` is called
- Then result has `overlayOpacity: 0.5` and all other fields unchanged
- Reference: `lib/models/widget_design.dart:96-115`

### R4: BackgroundConfig — equality

Two `BackgroundConfig` instances with identical fields are equal. List fields (gradientColors) are compared element-wise.

**Scenario: Equal configs**
- Given `a = BackgroundConfig(solidColor: '#FF0000')` and `b = BackgroundConfig(solidColor: '#FF0000')`
- Then `a == b` is `true`
- Reference: `lib/models/widget_design.dart:118-133`

### R5: WidgetDesign — 5-field immutable model

`WidgetDesign` bundles `id`, `name`, `clock` (ClockConfig), `background` (BackgroundConfig), `updatedAt`.

**Scenario: Create design**
- Given `WidgetDesign(id: '1', name: 'Home', clock: ClockConfig(), background: BackgroundConfig(type: image), updatedAt: DateTime.now())`
- Then all fields are accessible
- Reference: `lib/models/widget_design.dart:168-180`

### R6: WidgetDesign — JSON roundtrip

`fromJson` and `toJson` correctly serialize/deserialize including nested `ClockConfig` and `BackgroundConfig`.

**Scenario: Serialize and deserialize**
- Given a `WidgetDesign` with image background and custom clock config
- When `toJson()` then `fromJson()` is called
- Then the result equals the original
- Reference: `lib/models/widget_design.dart:182-196`

### R7: WidgetDesign — copyWith

`copyWith` creates a new instance with selective overrides.

**Scenario: Rename design**
- Given `design` with `name: 'Home'`
- When `design.copyWith(name: 'Night')` is called
- Then result has `name: 'Night'` and all other fields unchanged
- Reference: `lib/models/widget_design.dart:206-220`

### R8: Enum values

`BackgroundType` has 4 values: `none`, `solid`, `gradient`, `image`.
`OverlayMode` has 3 values: `none`, `dark`, `light`.

**Scenario: All enum values**
- Then `BackgroundType.values.length == 4`
- And `OverlayMode.values.length == 3`
- Reference: `lib/models/widget_design.dart:4-5`
