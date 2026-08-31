# Crop Screen

## Purpose

Full-screen crop UI that lets the user zoom and pan an image to select a crop region. Returns a `CropResult` with scale and offset values for the background image pipeline.

## Requirements

### R1: Display image with zoom + pan

The screen shows the selected image centered in a black background. User can pinch to zoom (1x–5x) and drag to pan.

**Scenario: Initial state**
- Given user opened crop screen with an image
- When the screen renders
- Then the image is displayed centered with `scale = 1.0` and `offset = (0, 0)`
- Reference: `lib/screens/crop_screen.dart:47-48`

**Scenario: Pinch to zoom**
- Given `scale = 1.0`
- When user pinch-zooms outward
- Then `_scale` increases (clamped to 5.0)
- Reference: `lib/screens/crop_screen.dart:96-106`

### R2: Offset clamping

Pan offset is clamped based on zoom scale so user cannot pan beyond image edges.

**Scenario: Clamp at max zoom**
- Given `scale = 3.0` and `canvasSize = Size(400, 800)`
- When user pans
- Then offset is clamped to `±(3.0 - 1) * 400 / 2 = ±400`
- Reference: `lib/screens/crop_screen.dart:108-115`

### R3: Zoom indicator

Current zoom percentage is displayed in the bottom bar.

**Scenario: Show zoom**
- Given `scale = 2.5`
- When the bottom bar renders
- Then text shows "250%"
- Reference: `lib/screens/crop_screen.dart:72-77`

### R4: Reset button

"Reset" button in bottom bar resets scale to 1.0 and offset to (0, 0).

**Scenario: Reset crop**
- Given `scale = 3.0`, `offset = (100, 50)`
- When user taps "Reset"
- Then `scale = 1.0` and `offset = Offset.zero`
- Reference: `lib/screens/crop_screen.dart:117-122`

### R5: Confirm — return CropResult

"Done" button calculates normalized offset (0.0–1.0) and pops with `CropResult(scale, offsetX, offsetY)`.

**Scenario: Confirm crop**
- Given `scale = 2.0` with some offset
- When user taps "Done"
- Then `Navigator.pop(CropResult(...))` is called
- And `offsetX` and `offsetY` are in range 0.0–1.0
- Reference: `lib/screens/crop_screen.dart:125-136`

### R6: Cancel — return null

Back button or "Cancel" text button pops with `null`.

**Scenario: Cancel crop**
- When user taps "Cancel" or back button
- Then `Navigator.pop()` is called with no result
- Reference: `lib/screens/crop_screen.dart:64-67`

### R7: CropResult data class

`CropResult` has 3 fields: `scale` (double), `offsetX` (double 0–1), `offsetY` (double 0–1).

**Scenario: Create result**
- Given `CropResult(scale: 2.0, offsetX: 0.6, offsetY: 0.4)`
- Then all fields are accessible
- Reference: `lib/screens/crop_screen.dart:9-20`
