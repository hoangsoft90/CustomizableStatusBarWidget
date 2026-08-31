# Design Storage Service

## Purpose

CRUD service for `WidgetDesign` persistence. Stores designs list in SharedPreferences as JSON. Manages source images and baked bitmaps in app documents directory. Enforces free tier quota of 3 designs.

## Requirements

### R1: loadAll — read all designs

`loadAll()` returns a list of all saved `WidgetDesign` objects from SharedPreferences key `"widget_designs"`.

**Scenario: No designs saved**
- Given SharedPreferences has no `"widget_designs"` key
- When `loadAll()` is called
- Then the result is an empty list
- Reference: `lib/services/design_storage_service.dart:55-64`

**Scenario: Designs exist**
- Given SharedPreferences has 2 designs saved as JSON
- When `loadAll()` is called
- Then the result is a list of 2 `WidgetDesign` objects
- Reference: `lib/services/design_storage_service.dart:55-64`

### R2: save — create or update

`save(design)` adds a new design or replaces an existing one with the same `id`.

**Scenario: Create new design**
- Given `loadAll()` returns `[]`
- When `save(design)` is called with `id: 'abc'`
- Then `loadAll()` returns `[design]`
- Reference: `lib/services/design_storage_service.dart:75-82`

**Scenario: Update existing design**
- Given `loadAll()` returns `[design with id: 'abc']`
- When `save(updatedDesign)` is called with `id: 'abc'`
- Then `loadAll()` returns `[updatedDesign]` (replaced, not duplicated)
- Reference: `lib/services/design_storage_service.dart:75-82`

### R3: delete — remove design and files

`delete(id)` removes the design from the list AND deletes associated files (source image `{id}.jpg` + all baked bitmaps `{id}_{widgetId}.png`).

**Scenario: Delete with files**
- Given design with `id: 'abc'` exists
- And files `designs/abc.jpg` and `designs/abc_42.png` exist
- When `delete('abc')` is called
- Then the design is removed from the list
- And `designs/abc.jpg` is deleted
- And `designs/abc_42.png` is deleted
- Reference: `lib/services/design_storage_service.dart:84-108`

### R4: rename — update name and timestamp

`rename(id, newName)` updates the design's name and `updatedAt` timestamp.

**Scenario: Rename**
- Given design with `id: 'abc'`, `name: 'Home'`
- When `rename('abc', 'Night')` is called
- Then the design has `name: 'Night'` and updated `updatedAt`
- Reference: `lib/services/design_storage_service.dart:111-115`

### R5: loadById — single design lookup

`loadById(id)` returns the design with matching ID, or `null` if not found.

**Scenario: Found**
- Given designs `[{id: 'abc'}, {id: 'def'}]`
- When `loadById('abc')` is called
- Then the result is the design with `id: 'abc'`
- Reference: `lib/services/design_storage_service.dart:67-72`

**Scenario: Not found**
- When `loadById('xyz')` is called
- Then the result is `null`
- Reference: `lib/services/design_storage_service.dart:67-72`

### R6: isQuotaFull — free tier check

`isQuotaFull()` returns `true` when design count >= 3 (for non-premium users). Always returns `false` for premium users.

**Scenario: Quota full**
- Given 3 designs saved and `isPremium: false`
- When `isQuotaFull(isPremium: false)` is called
- Then the result is `true`
- Reference: `lib/services/design_storage_service.dart:121-125`

**Scenario: Premium bypass**
- Given 3 designs saved and `isPremium: true`
- When `isQuotaFull(isPremium: true)` is called
- Then the result is `false`
- Reference: `lib/services/design_storage_service.dart:121-125`

### R7: remainingSlots — available design count

`remainingSlots()` returns the number of designs that can still be created.

**Scenario: 1 of 3 used**
- Given 1 design saved and `isPremium: false`
- When `remainingSlots()` is called
- Then the result is `2`
- Reference: `lib/services/design_storage_service.dart:128-132`

### R8: File path helpers

`sourceImagePath(designId)` returns path for source image (`{designId}.jpg`).
`bakedBitmapPath(designId, widgetId)` returns path for baked bitmap (`{designId}_{widgetId}.png`).

**Scenario: Source path**
- Given `designId: 'abc'`
- When `sourceImagePath('abc')` is called
- Then the result ends with `/designs/abc.jpg`
- Reference: `lib/services/design_storage_service.dart:44-48`

**Scenario: Baked bitmap path**
- Given `designId: 'abc'`, `widgetId: 42`
- When `bakedBitmapPath('abc', 42)` is called
- Then the result ends with `/designs/abc_42.png`
- Reference: `lib/services/design_storage_service.dart:51-54`

### R9: clearBakedBitmaps — remove all baked files for a design

`clearBakedBitmaps(designId)` deletes all files matching `{designId}_*` in the designs directory.

**Scenario: Clear baked bitmaps**
- Given files `designs/abc_5.png`, `designs/abc_12.png` exist
- When `clearBakedBitmaps('abc')` is called
- Then both files are deleted
- Reference: `lib/services/design_storage_service.dart:148-160`

### R10: getDesignsDirectoryPath — for native access

`getDesignsDirectoryPath()` returns the absolute path to the designs directory.

**Scenario: Get path**
- When `getDesignsDirectoryPath()` is called
- Then the result is a valid directory path ending with `/designs`
- Reference: `lib/services/design_storage_service.dart:163-166`
