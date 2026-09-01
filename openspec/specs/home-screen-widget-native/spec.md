# Home Screen Widget (Native Android)

## Purpose

`DateTimeWidgetProvider` extends `AppWidgetProvider` to render day/date/time on the home screen. Supports 4 widget sizes (2×1, 3×1, 4×1, 4×2) with separate layout XML files. Config is read from "status_bar_config" SharedPreferences. Supports optional background image baked per widget instance.

## Requirements

### R1: 4 widget sizes with layout selection

Layout is chosen based on the widget's `minWidth`/`minHeight` from AppWidgetManager options:

| minWidth | Layout | Size |
|----------|--------|------|
| ≥ 300 and ≥ 170 | `widget_4x2.xml` | 4×2 |
| ≥ 300 | `widget_4x1.xml` | 4×1 |
| ≥ 240 | `widget_3x1.xml` | 3×1 |
| < 240 | `widget_2x1.xml` | 2×1 |

**Scenario: 4×2 widget**
- Given a widget with minWidth=320, minHeight=180
- When `chooseLayout` runs
- Then `R.layout.widget_4x2` is selected
- Reference: `DateTimeWidgetProvider.kt:112-117`

**Scenario: 2×1 widget**
- Given a widget with minWidth=150, minHeight=80
- When `chooseLayout` runs
- Then `R.layout.widget_2x1` is selected
- Reference: `DateTimeWidgetProvider.kt:112-117`

### R2: Config from SharedPreferences

Reads from `"status_bar_config"` SharedPreferences, key `"clock_config"`. Falls back to default ClockData on parse error.

**Scenario: Config present**
- Given SharedPreferences has valid JSON config
- When `readConfig` is called
- Then ClockData fields match the saved config
- Reference: `DateTimeWidgetProvider.kt:122-129`

**Scenario: No config — defaults**
- Given SharedPreferences has no config
- When `readConfig` is called
- Then ClockData defaults are used (format: 'EEE dd MMM', fontSize: 32.0, etc.)
- Reference: `DateTimeWidgetProvider.kt:126`

### R3: Rendering — day, date, time

`renderWidget` sets text on `widget_day`, `widget_date`, `widget_time` TextViews. Applies user color and proportional font sizes.

**Scenario: Full render**
- Given config with `color: '#FF5722'`, `fontSize: 34`
- When `renderWidget` runs
- Then `widget_time` text size is 34sp
- And `widget_day` text size is 34 × 0.45 = 15.3sp
- And `widget_date` text size is 34 × 0.4 = 13.6sp
- And all text colors are #FF5722
- Reference: `DateTimeWidgetProvider.kt:80-95`

### R4: Tap opens app with editor deep link

Tapping any text in the widget launches the app with `open_editor=true` extra, which triggers the Editor screen.

**Scenario: Widget tap**
- Given a widget instance
- When user taps `widget_day`, `widget_date`, or `widget_time`
- Then a PendingIntent fires with `open_editor=true`
- Reference: `DateTimeWidgetProvider.kt:97-107`

### R5: updateAllWidgets — static method

`updateAllWidgets(context)` iterates all widget IDs and calls `renderWidget` for each. Called by TimeTickService, BootReceiver, and MainActivity.

**Scenario: Force update all**
- When `DateTimeWidgetProvider.updateAllWidgets(context)` is called
- Then every active widget instance is re-rendered
- Reference: `DateTimeWidgetProvider.kt:28-34`

### R6: onTick — coordinated update

`onTick(context)` updates widgets AND triggers NotificationIconService.update() AND FloatingBarService.updateOverlay() in one call.

**Scenario: Time tick**
- When `DateTimeWidgetProvider.onTick(context)` is called
- Then `updateAllWidgets` runs
- And `NotificationIconService.update(context)` runs
- And `FloatingBarService.updateOverlay(context)` runs
- Reference: `DateTimeWidgetProvider.kt:36-40`

### R7: saveConfig — Flutter config sync

`saveConfig(context, json)` writes config to SharedPreferences, then triggers updateAllWidgets + notification + floating bar.

**Scenario: Config received from Flutter**
- Given a JSON string from Flutter MethodChannel
- When `saveConfig(context, json)` is called
- Then the JSON is saved to `"status_bar_config"` SharedPreferences
- And all three services are updated
- Reference: `DateTimeWidgetProvider.kt:43-49`

### R8: Locale-aware day names

Day names use `SimpleDateFormat` with `Locale.getDefault()` or `Calendar.getDisplayName()`.

**Scenario: Locale-aware**
- Given device locale is French
- When `formatDisplay` renders day names
- Then day names are in French
- Reference: `DateTimeWidgetProvider.kt:148-155`

### R9: Sunday crash guard

Day-of-week index is guarded: `if (dayIdx < 0) 6 else dayIdx` to handle Sunday (Calendar.SUNDAY=1, Calendar.MONDAY=2, so 1-2=-1).

**Scenario: Sunday**
- Given `Calendar.DAY_OF_WEEK == Calendar.SUNDAY`
- When `dayIdx = dayOfWeek - Calendar.MONDAY` (=-1)
- Then `dayIdxSafe = 6` (Sunday index in the names array)
- Reference: `DateTimeWidgetProvider.kt:143-144`

### R10: Layout XML — FrameLayout + ImageView background (plan5 §2.1)

All 4 layout XML files use `FrameLayout` as root, with `ImageView#widget_background` as the bottom layer and `LinearLayout` (containing TextViews) on top.

**Scenario: ImageView in layout**
- Given any widget layout file
- When the widget renders
- Then `widget_background` ImageView exists with `scaleType="centerCrop"` and `visibility="gone"`
- Reference: `widget_2x1.xml`, `widget_3x1.xml`, `widget_4x1.xml`, `widget_4x2.xml`

### R11: applyWidgetBackground — read baked bitmap (plan5 §2.2, plan8 §1)

`applyWidgetBackground()` reads the bitmap path from SharedPreferences namespace `widget_background` (key `bg_bitmap_path`), decodes the bitmap with `inSampleSize` downscaling, caps at 800px max side, and sets it on the ImageView via `setImageViewBitmap`.

**Scenario: Bitmap exists**
- Given SharedPreferences has `bg_bitmap_path` pointing to a valid PNG
- When `applyWidgetBackground(context, views, widgetId)` runs
- Then `BitmapFactory.decodeFile()` loads the bitmap with `inSampleSize` for large images
- And if `maxSide > 800`, the bitmap is scaled down to 800px max via `Bitmap.createScaledBitmap()`
- And `views.setImageViewBitmap(R.id.widget_background, finalBitmap)` sets it
- And `views.setViewVisibility(R.id.widget_background, VISIBLE)` makes it visible
- Reference: `DateTimeWidgetProvider.kt:195-241`

**Scenario: No bitmap — fallback**
- Given SharedPreferences has no `bg_bitmap_path` or file doesn't exist
- When `applyWidgetBackground(context, views, widgetId)` runs
- Then `views.setViewVisibility(R.id.widget_background, GONE)` hides ImageView
- And widget displays text on default dark background
- Reference: `DateTimeWidgetProvider.kt:200-204`

**Scenario: Decode error — fallback**
- Given `bg_bitmap_path` points to a corrupted file
- When `BitmapFactory.decodeFile()` returns null
- Then `Log.e()` is called and ImageView stays GONE
- Reference: `DateTimeWidgetProvider.kt:237`

### R11b: calculateInSampleSize — memory optimization

`calculateInSampleSize(options, reqWidth, reqHeight)` computes the optimal `inSampleSize` power-of-2 value for downsampling large bitmaps to avoid OOM.

**Scenario: Large image downsampled**
- Given a 3000×2000 source image
- When decoded with `reqWidth=800, reqHeight=800`
- Then `inSampleSize` is 4 (renders at 750×500)
- Reference: `DateTimeWidgetProvider.kt:243-253`

### R12: saveWidgetBackground — static method (plan5 §3)

`saveWidgetBackground(context, widgetId, bitmapPath)` saves the bitmap path to SharedPreferences and triggers re-render of that specific widget.

**Scenario: Save background path**
- Given `widgetId = 42`, `bitmapPath = "/data/.../abc_42.png"`
- When `saveWidgetBackground(context, 42, "/data/.../abc_42.png")` is called
- Then SharedPreferences stores `"widget_bg_42" → bitmapPath`
- And `renderWidget(context, mgr, 42)` is called
- Reference: `DateTimeWidgetProvider.kt:51-60`

**Scenario: Clear background**
- Given `widgetId = 42` has a bitmap path
- When `saveWidgetBackground(context, 42, null)` is called
- Then key `"widget_bg_42"` is removed from SharedPreferences
- And widget re-renders with default background
- Reference: `DateTimeWidgetProvider.kt:51-60`

### R13: onAppWidgetOptionsChanged — resize preserves background (plan8 §2)

When user resizes a widget, `onAppWidgetOptionsChanged()` re-renders the widget WITHOUT clearing the cached bitmap path. The existing bitmap is reused at the new size. Flutter will re-bake on the next save/apply cycle.

**Scenario: Widget resized — background preserved**
- Given widget instance 42 has cached bitmap in SharedPreferences
- When user drags to resize widget
- Then `onAppWidgetOptionsChanged()` calls `renderWidget()` only
- And the bitmap path is NOT removed from SharedPreferences
- And the existing bitmap continues to display at the new size
- Reference: `DateTimeWidgetProvider.kt:130-140`

### R14: Text shadow on all TextViews (plan8 §3)

All TextViews (`widget_day`, `widget_date`, `widget_time`) in all 4 layout XML files have `shadowColor="#AA000000"` and `shadowDx=0` `shadowDy=1` for text readability over any background.

**Scenario: Text shadow applied**
- Given any widget layout XML
- When the widget renders
- Then all 3 TextViews have shadow attributes
- And no hardcoded color overlay (no `#59000000` or `#CC000000`) exists on the LinearLayout
- Reference: `widget_2x1.xml`, `widget_3x1.xml`, `widget_4x1.xml`, `widget_4x2.xml`
