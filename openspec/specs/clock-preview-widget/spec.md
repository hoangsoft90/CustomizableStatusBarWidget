# ClockPreview Widget

## Purpose

StatefulWidget that renders a live clock display, updating every second via a Timer. Reads format from ClockConfig and uses DateFormatter to produce display strings.

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

### R4: Dark background container

The preview renders inside a `Container` with `Colors.black87` background and `borderRadius: 16`.

**Scenario: Container styling**
- When ClockPreview builds
- Then the outer Container has `color: Colors.black87` and `borderRadius: BorderRadius.circular(16)`
- Reference: `lib/widgets/clock_preview.dart:50-54`

### R5: Re-renders on config change

When the parent passes a new ClockConfig (via `didUpdateWidget` or rebuild), the preview immediately uses the new config on the next timer tick (or immediately if already ticking).

**Scenario: Config change mid-display**
- Given preview shows `fontSize: 32`
- When parent rebuilds with `config: newConfig(fontSize: 48)`
- Then on next timer tick, the time renders at `fontSize: 48`
- Reference: `lib/widgets/clock_preview.dart:60` (uses `widget.config` directly in build)
