# Floating Bar Service (Native Android)

## Purpose

ForegroundService using `TYPE_APPLICATION_OVERLAY` to draw a transparent floating bar immediately below the real status bar. Shows day, date, and time. Updates in-place (no stop/start cycle) on config change or time tick.

## Requirements

### R1: Overlay positioning

The overlay bar is placed at `y = statusBarHeight` (read from system resources), directly below the status bar. Height is 32dp.

**Scenario: Position calculation**
- Given status bar height is 24px
- When overlay layout params are created
- Then `y = 24` and `height = 32dp`
- And `gravity = Gravity.TOP or Gravity.START`
- Reference: `FloatingBarService.kt:162-178`

### R2: TYPE_APPLICATION_OVERLAY

Uses `WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY` (API 26+). Does NOT draw on top of System UI — sits below the status bar.

**Scenario: Window type**
- When `createLayoutParams` runs
- Then `type = TYPE_APPLICATION_OVERLAY`
- And flags include `FLAG_NOT_FOCUSABLE | FLAG_NOT_TOUCH_MODAL | FLAG_LAYOUT_IN_SCREEN`
- Reference: `FloatingBarService.kt:170-176`

### R3: Transparent background with luminance-based tint

Background color is determined by text color luminance: dark bg for light text, lighter bg for dark text. Alpha is `0xCC` (80%).

**Scenario: Light text on dark bg**
- Given `config.color = '#FFFFFF'` (white text)
- When `createBarView` runs
- Then `bgColor = Color.argb(0xCC, 0, 0, 0)` (dark background)
- Reference: `FloatingBarService.kt:187-194`

**Scenario: Dark text on light bg**
- Given `config.color = '#000000'` (black text)
- When `createBarView` runs
- Then `bgColor = Color.argb(0xCC, 20, 20, 20)` (slightly lighter dark)
- Reference: `FloatingBarService.kt:192-194`

### R4: Layout structure

`LinearLayout` (horizontal) with: `dayText` → `dateText` → `spacer` (weight=1) → `timeText`. Alignment from config applied via `layout.gravity`.

**Scenario: Center alignment**
- Given `config.alignment = 'center'`
- When bar view is created
- Then `layout.gravity = Gravity.CENTER or Gravity.CENTER_VERTICAL`
- Reference: `FloatingBarService.kt:197-222`

### R5: updateOverlay in-place

`updateOverlay()` reads the existing `overlayView` (cast to LinearLayout), calls `updateBarContent()` which updates text and alignment without recreating the view.

**Scenario: Update text without recreate**
- Given overlay is already showing
- When `updateOverlay()` is called
- Then `updateBarContent(layout)` updates TextViews and gravity directly
- Reference: `FloatingBarService.kt:148-155`, `230-290`

### R6: UPDATE_OVERLAY intent action

`onStartCommand` handles `UPDATE_OVERLAY` action separately from the initial start — updates in-place, does not recreate overlay.

**Scenario: Update intent received**
- Given service is already running
- When `onStartCommand` receives intent with `action == "UPDATE_OVERLAY"`
- Then `updateOverlay()` is called and `START_STICKY` is returned
- Reference: `FloatingBarService.kt:137-141`

### R7: Foreground notification

Service shows a low-priority ongoing notification "Date & Time Floating Bar — Active".

**Scenario: Foreground notification**
- When service starts
- Then `startForeground(NOTIFICATION_ID, notification)` is called
- Reference: `FloatingBarService.kt:133-134`

### R8: Locale-aware formatting

Day names and month names use `Calendar.getDisplayName()` with `Locale.getDefault()`.

**Scenario: Locale-aware month**
- Given device locale is Japanese
- When `updateBarContent` formats the date
- Then month name is in Japanese
- Reference: `FloatingBarService.kt:256-284`

### R9: Alignment applied in bar

Config alignment maps to Android Gravity constants: left→START, right→END, center→CENTER.

**Scenario: Right alignment**
- Given `config.alignment = 'right'`
- When `updateBarContent` runs
- Then `layout.gravity = Gravity.END or Gravity.CENTER_VERTICAL`
- Reference: `FloatingBarService.kt:287-291`

### R10: Config from SharedPreferences

Reads from `"status_bar_config"` SharedPreferences, same as other native services.

**Scenario: Config read**
- When `readConfig()` is called
- Then it reads `SharedPreferences("status_bar_config").getString("clock_config")`
- Reference: `FloatingBarService.kt:301-307`
