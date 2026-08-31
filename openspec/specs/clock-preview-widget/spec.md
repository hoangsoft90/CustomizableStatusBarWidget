# ClockPreview Widget

## Purpose

StatefulWidget that renders a live clock display, updating every second via a Timer. Reads format from ClockConfig and uses DateFormatter to produce display strings. Supports optional BackgroundConfig for rendering backgrounds (solid, gradient, image with overlay).

## Requirements

### R1: Timer-based update

A `Timer.periodic(Duration(seconds: 1))` updates `_now` and triggers `setState` every second.

**Scenario: Initial render**
- Given ClockPreview is created with a ClockConfig
- When `initState` runs
- Then `_now = DateTime.now()` and a 1-second timer starts
- Reference: `lib/widgets/clock_preview.dart:18-23`

**Scenario: Timer cancelled on dispose**
- Given ClockPreview is in the widget tree
- When it is removed (dispose)
- Then `_timer.cancel()` is called
- Reference: `lib/widgets/clock_preview.dart:26-29`

### R2: Three display lines

Renders up to 3 lines: day (if non-empty), date (if non-empty), time (always).

**Scenario: All three lines**
- Given config with `showDay: true`, `showDate: true`, `format: 'EEEE, dd MMM'`
- When build is called
- Then day line, date line, and time line are all visible
- Reference: `lib/widgets/clock_preview.dart:56-86`

**Scenario: Time only**
- Given config with `showDay: false`, `showDate: false`
- When build is called
- Then only the time line is rendered
- Reference: `lib/widgets/clock_preview.dart:67-86`

### R3: Styling from config

- Day: `fontSize * 0.55`, weight `w500`
- Date: `fontSize * 0.6`, weight `w400`, alpha `0.85`
- Time: `fontSize`, weight `w700`, letterSpacing `1.2`
- Color parsed from config hex string
- Alignment from config alignment field

**Scenario: Color parsing**
- Given `config.color = '#FF5722'`
- When `_textColor` is computed
- Then the result is `Color(0xFFFF5722)`
- Reference: `lib/widgets/clock_preview.dart:32-37`

**Scenario: Alignment mapping**
- Given `config.alignment = 'left'`
- When `_alignment` is computed
- Then result is `TextAlign.left`
- Reference: `lib/widgets/clock_preview.dart:39-46`

### R4: Background rendering (plan5 §4)

ClockPreview now accepts an optional `background` parameter (`BackgroundConfig`). The background is rendered behind the text content based on its type.

**Scenario: No background (default)**
- Given `background: BackgroundConfig()` (type: none)
- When ClockPreview renders
- Then the outer Container has `color: Colors.black87` (unchanged from before)
- Reference: `lib/widgets/clock_preview.dart:50-54`

**Scenario: Solid color background**
- Given `background: BackgroundConfig(type: solid, solidColor: '#1A1A2E')`
- When ClockPreview renders
- Then `_backgroundDecoration()` returns `BoxDecoration(color: Color(0xFF1A1A2E))`
- Reference: `lib/widgets/clock_preview.dart:68-75`

**Scenario: Gradient background**
- Given `background: BackgroundConfig(type: gradient, gradientColors: ['#FF0000', '#0000FF'])`
- When ClockPreview renders
- Then `_backgroundDecoration()` returns `BoxDecoration(gradient: LinearGradient(...))`
- Reference: `lib/widgets/clock_preview.dart:77-87`

**Scenario: Image background with overlay**
- Given `background: BackgroundConfig(type: image, imagePath: '/data/.../abc.jpg', overlayOpacity: 0.35, overlayMode: dark)`
- When ClockPreview renders
- Then `Image.file` shows the background image via `_buildBackgroundImage()`
- And a dark overlay covers the image via `_buildOverlay()`
- And text content is rendered in a Stack on top
- Reference: `lib/widgets/clock_preview.dart:89-93`, `152-170`

### R5: Text shadow for readability

When `background.textShadow` is true, text gets a `Shadow(color: Colors.black54, blurRadius: 8)` for readability over images.

**Scenario: Shadow enabled**
- Given `background.textShadow: true`
- When text renders
- Then `shadows: [Shadow(color: Colors.black54, blurRadius: 8, offset: Offset(1, 1))]`
- Reference: `lib/widgets/clock_preview.dart:120-130`

**Scenario: Shadow disabled**
- Given `background.textShadow: false`
- When text renders
- Then `shadows: null`
- Reference: `lib/widgets/clock_preview.dart:120-130`

### R6: Image background uses Stack layout

When background type is `image`, the widget uses a `ClipRRect > Stack` layout: image layer → overlay layer → text content (with padding).

**Scenario: Stack layers**
- Given background type is `image`
- When ClockPreview renders
- Then the widget tree is `Container > ClipRRect > Stack > [Positioned.fill(Image), Positioned.fill(Overlay), Padding(text)]`
- Reference: `lib/widgets/clock_preview.dart:152-170`

### R7: Re-renders on config change

When the parent passes a new ClockConfig (via `didUpdateWidget` or rebuild), the preview immediately uses the new config on the next timer tick (or immediately if already ticking).

**Scenario: Config change mid-display**
- Given preview shows `fontSize: 32`
- When parent rebuilds with `config: newConfig(fontSize: 48)`
- Then on next timer tick, the time renders at `fontSize: 48`
- Reference: `lib/widgets/clock_preview.dart:60` (uses `widget.config` directly in build)

### R8: Re-renders on background change

When the parent passes a new BackgroundConfig, the preview immediately uses it on the next build.

**Scenario: Background change**
- Given preview with `background: BackgroundConfig(type: none)`
- When parent rebuilds with `background: BackgroundConfig(type: solid, solidColor: '#FF0000')`
- Then the container background changes to red
- Reference: `lib/widgets/clock_preview.dart:147` (uses `widget.background` directly in build)
