# Share Service

## Purpose

Renders a `WidgetDesign` as a PNG image (1080×540, 2:1 ratio) and shares it via the system share sheet. Includes background, text, and watermark.

## Requirements

### R1: Render design to PNG

`shareDesign()` renders the design off-screen using `RepaintBoundary` + `toImage()`, capturing a 1080×540 PNG.

**Scenario: Render capture**
- Given a design with image background and custom clock config
- When `ShareService.shareDesign(context, design)` is called
- Then a `_SharePreviewWidget` is inserted off-screen at `(-2000, -2000)`
- And after 100ms delay, `RepaintBoundary.toImage(pixelRatio: 1.0)` captures the widget
- And the result is a 1080×540 PNG image
- Reference: `lib/services/share_service.dart:24-60`

### R2: Preview widget renders full design

`_SharePreviewWidget` renders the design with background (solid/gradient/image + overlay), time/date/day text with correct colors and fonts, and text shadows if enabled.

**Scenario: Image background with overlay**
- Given design with `type: image`, `overlayMode: dark`, `overlayOpacity: 0.35`
- When `_SharePreviewWidget` renders
- Then `Image.file` shows the background image
- And a dark overlay with 35% opacity covers the image
- And text is rendered on top with shadows
- Reference: `lib/services/share_service.dart:130-210`

**Scenario: Solid color background**
- Given design with `type: solid`, `solidColor: '#1A1A2E'`
- When `_SharePreviewWidget` renders
- Then `Container` has `color: Color(0xFF1A1A2E)`
- Reference: `lib/services/share_service.dart:146-149`

### R3: Watermark on free version

A "Photo Clock Widget" watermark is rendered at bottom-right with 40% opacity.

**Scenario: Watermark visible**
- When `_SharePreviewWidget` renders
- Then "Photo Clock Widget" text is at `Positioned(bottom: 16, right: 16)`
- And opacity is 40%
- Reference: `lib/services/share_service.dart:199-209`

### R4: Save to temp file and share

Captured PNG is saved to temporary directory, then shared via `Share.shareXFiles()`.

**Scenario: Share flow**
- Given a captured 1080×540 PNG
- When sharing
- Then file is saved to `{tempDir}/design_share.png`
- And `Share.shareXFiles([XFile(path, mimeType: 'image/png')])` is called
- And subject is "My clock design — {design.name}"
- Reference: `lib/services/share_service.dart:54-66`

### R5: Error handling — silent failure

If any step fails (capture, save, share), the method catches the exception and returns silently without crashing.

**Scenario: Capture fails**
- Given `boundary` is null (widget not rendered)
- When `shareDesign()` is called
- Then the overlay entry is removed and the method returns
- Reference: `lib/services/share_service.dart:38-40`

### R6: Cleanup — remove overlay entry

After capture, the overlay entry is always removed, even if capture fails.

**Scenario: Cleanup**
- Given an overlay entry was inserted
- When capture completes (success or failure)
- Then `entry.remove()` is called
- Reference: `lib/services/share_service.dart:40`
