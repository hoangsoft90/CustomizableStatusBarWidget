# My Designs Screen

## Purpose

Screen showing user-created designs in a grid. Supports create, rename, delete, apply, and share operations. Enforces free tier quota of 3 designs. Returns a `WidgetDesign` to the caller when user applies a design.

## Requirements

### R1: Design grid display

Designs are shown in a 2-column grid with mini `ClockPreview` (including background) and design name.

**Scenario: Show designs**
- Given 2 saved designs
- When MyDesignsScreen renders
- Then a 2-column grid shows 2 `_DesignCard` widgets
- Reference: `lib/screens/my_designs_screen.dart:227-243`

### R2: Empty state

When no designs exist, an empty state is shown with an icon, text, and "Create Design" button.

**Scenario: No designs**
- Given 0 saved designs
- When MyDesignsScreen renders
- Then "No designs yet" text and a "Create Design" button are visible
- Reference: `lib/screens/my_designs_screen.dart:192-220`

### R3: Create design flow

Tapping FAB "+" opens EditorScreen with `storage: null` (create mode). After save, a name dialog appears. Design is saved to DesignStorageService.

**Scenario: Create new design**
- Given quota is not full
- When user taps FAB "+"
- Then EditorScreen opens with empty config
- When user saves
- Then a name dialog appears
- When user enters "My Design" and confirms
- Then design is saved to DesignStorageService
- And grid updates to show the new design
- Reference: `lib/screens/my_designs_screen.dart:80-108`

### R4: Quota enforcement — 3 free designs

FAB is disabled when quota is full (3 designs for free users). Tapping shows "Design limit reached" dialog.

**Scenario: Quota full**
- Given 3 designs saved and `isPremium: false`
- When MyDesignsScreen renders
- Then FAB shows `Icons.folder_off` and `_canCreate` is `false`
- When user taps FAB
- Then "Design limit reached" dialog appears
- Reference: `lib/screens/my_designs_screen.dart:73-74`, `140-158`

**Scenario: Premium bypass**
- Given 3 designs saved and `isPremium: true`
- When `isQuotaFull(isPremium: true)` is called
- Then result is `false` (can create more)
- Reference: `lib/services/design_storage_service.dart:121-125`

### R5: Quota indicator in AppBar

AppBar shows quota as a badge: "2/3" (free) or "∞" (premium).

**Scenario: Free user**
- Given 2 designs saved and `isPremium: false`
- When AppBar renders
- Then badge shows "2/3" with green color
- Reference: `lib/screens/my_designs_screen.dart:169-187`

### R6: Apply design — return to caller

Tapping a design card calls `_applyDesign(design)` which pops the screen with the `WidgetDesign`.

**Scenario: Apply design**
- Given a design in the grid
- When user taps the design card
- Then `Navigator.pop(design)` returns the WidgetDesign
- Reference: `lib/screens/my_designs_screen.dart:76-78`

### R7: Long-press options menu

Long-pressing a design card shows a bottom sheet with 4 options: Apply, Share, Rename, Delete.

**Scenario: Long-press menu**
- Given a design in the grid
- When user long-presses the card
- Then a bottom sheet appears with Apply, Share, Rename, Delete options
- Reference: `lib/screens/my_designs_screen.dart:162-190`

### R8: Rename design

"Rename" option shows a dialog with the current name. Saving updates the name via `DesignStorageService.rename()`.

**Scenario: Rename**
- Given design named "Home"
- When user taps "Rename" and enters "Night"
- Then `designStorage.rename(id, 'Night')` is called
- And grid updates to show "Night"
- Reference: `lib/screens/my_designs_screen.dart:110-117`

### R9: Delete design with confirmation

"Delete" option shows a confirmation dialog. Confirming deletes via `DesignStorageService.delete()` which also removes associated files.

**Scenario: Delete**
- Given design named "Home"
- When user taps "Delete" and confirms
- Then `designStorage.delete(id)` is called
- And SnackBar "Design \"Home\" deleted" is shown
- Reference: `lib/screens/my_designs_screen.dart:119-138`

### R10: Share design

"Share" option calls `ShareService.shareDesign(context, design)` which renders the design as a PNG and opens the system share sheet.

**Scenario: Share**
- Given a design in the grid
- When user taps "Share"
- Then `ShareService.shareDesign(context, design)` is called
- Reference: `lib/screens/my_designs_screen.dart:173-177`
