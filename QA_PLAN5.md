# QA Report — V1.0 Personalization (Plan5)

> Date: 2026-08-31
> Verified by: Static code review + dart analyze + flutter test
> Device testing: Required on real devices (Pixel, Samsung, Xiaomi)

---

## 1. Acceptance Criteria Verification

### Background Image

| # | Criterion | Status | Verification Method |
|---|-----------|--------|---------------------|
| 1 | Chọn ảnh gallery → crop → preview chữ luôn đọc được trên cả ảnh sáng và tối | ⚠️ Manual | Code review: overlay dark 35% + text shadow + autoTextContrast defaults ON. Need device test to confirm readability. |
| 2 | Apply → Home Widget hiện đúng ảnh + chữ, không méo/stretch | ⚠️ Manual | Code review: `applyWidgetBackground()` reads baked bitmap per widgetId, `centerCrop` scaleType. Need device test. |
| 3 | Đặt cùng 1 design lên 2 widget instance size khác nhau → cả 2 đều hiển thị đúng tỉ lệ | ⚠️ Manual | Code review: `chooseLayout()` reads per-widget options, `applyWidgetBackground()` reads per-widgetId bitmap. Need device test with 2x1 + 4x2 simultaneously. |
| 4 | Kéo giãn (resize) 1 widget instance → ảnh bake lại đúng size mới | ⚠️ Manual | Code review: `onAppWidgetOptionsChanged()` clears bitmap cache, Flutter re-bakes on next update. Need device test. |
| 5 | Không crash hay bị OS từ chối update với ảnh input 12MP+ | ⚠️ Manual | Code review: `ImageUtils.resizeSource()` caps at 1600px, `resizeForWidget()` caps at 480x480. Need device test with 12MP photo. |
| 6 | Xóa design → toàn bộ file ảnh liên quan bị xóa | ✅ Static | `DesignStorageService.delete()` deletes source `.jpg` + all `_{widgetId}.png` via directory listing. |

### My Designs

| # | Criterion | Status | Verification Method |
|---|-----------|--------|---------------------|
| 7 | Lưu tối đa 3 design (free); design thứ 4 → thông báo giới hạn | ✅ Static | `isQuotaFull()` returns true at count >= 3. `_showQuotaFullDialog()` shown. FAB disabled. |
| 8 | Apply 1 tap cập nhật preview + widget + notification + floating bar | ✅ Static | `_openMyDesigns()` calls: `saveConfig()` → `WidgetBridge.updateWidgets()` → `_notifService.update()` → `FloatingBarBridge.update()`. Same chain as Editor/Presets. |
| 9 | Rename/Delete hoạt động đúng | ✅ Static | `rename()` updates name + updatedAt. `delete()` removes from list + cleans files. |

### Share

| # | Criterion | Status | Verification Method |
|---|-----------|--------|---------------------|
| 10 | Tạo ảnh preview đúng design, mở được system share sheet | ⚠️ Manual | Code review: `ShareService.shareDesign()` renders at 1080x540, saves PNG, calls `Share.shareXFiles()`. Need device test. |
| 11 | Có branding nhỏ ở bản free | ✅ Static | Watermark "Photo Clock Widget" at bottom-right, opacity 40%. |

### Regression — Không được phá vỡ

| # | Criterion | Status | Verification Method |
|---|-----------|--------|---------------------|
| 12 | Status bar notification vẫn hoạt động | ✅ Static | `NotificationService` untouched. `_notifService.update()` still called in all apply flows. |
| 13 | Reward daily preset flow vẫn hoạt động | ✅ Test | 91/91 tests pass including `reward_service_test.dart` (16 tests). |
| 14 | Không có ads trên widget/floating bar/notification | ✅ Static | No ad code in `DateTimeWidgetProvider.kt`, `NotificationIconService.kt`, `FloatingBarService.kt`. |
| 15 | Không xuất hiện lại `showSeconds` | ✅ Static | `grep -rn "showSeconds" lib/` returns 0 results. |
| 16 | Offline-first — không phát sinh network call mới | ✅ Static | All new services (`DesignStorageService`, `ShareService`, `ImageUtils`) use local file system only. `share_plus` opens system share sheet (no network). |

---

## 2. Files Changed (Plan5)

| File | Lines | Description |
|------|-------|-------------|
| `lib/models/widget_design.dart` | 230 | `BackgroundConfig` + `WidgetDesign` models with JSON roundtrip |
| `lib/services/design_storage_service.dart` | 160 | CRUD + quota 3 + file management |
| `lib/utils/image_utils.dart` | 110 | Image resize (source 1600px, widget 480px) |
| `lib/screens/editor_screen.dart` | 580 | Background section (None/Solid/Gradient/Image) + crop flow |
| `lib/screens/crop_screen.dart` | 140 | Pinch-to-zoom + pan crop UI |
| `lib/screens/my_designs_screen.dart` | 310 | Design list + create/rename/delete/apply/share |
| `lib/screens/home_screen.dart` | 270 | My Designs button + design apply flow |
| `lib/main.dart` | 85 | Init `DesignStorageService` |
| `lib/widgets/clock_preview.dart` | 200 | Background rendering (solid/gradient/image+overlay) |
| `lib/services/widget_bridge.dart` | 70 | `setWidgetBackground()` + `getActiveWidgetIds()` |
| `lib/services/share_service.dart` | 200 | Render design to PNG + share |
| `android/.../widget_2x1.xml` | 28 | FrameLayout + ImageView background layer |
| `android/.../widget_3x1.xml` | 28 | Same |
| `android/.../widget_4x1.xml` | 42 | Same |
| `android/.../widget_4x2.xml` | 32 | Same |
| `android/.../DateTimeWidgetProvider.kt` | 180 | `applyWidgetBackground()` + `onAppWidgetOptionsChanged()` |
| `android/.../MainActivity.kt` | 100 | Handle `setWidgetBackground` + `getActiveWidgetIds` |
| `pubspec.yaml` | 35 | Added `path_provider`, `uuid`, `image_picker`, `share_plus` |

**Total: ~2,790 lines added/modified**

---

## 3. Test Results

```
91 passed, 0 failed ✅
```

### Test files

| File | Tests |
|------|-------|
| `plan2_fixes_test.dart` | 36 |
| `storage_service_test.dart` | 5 |
| `editor_config_test.dart` | 6 |
| `date_formatter_test.dart` | 14 |
| `floating_bar_config_test.dart` | 5 |
| `notification_config_test.dart` | 12 |
| `iap_premium_test.dart` | 8 |
| `reward_service_test.dart` | 16 |
| `widget_test.dart` | 1 |

---

## 4. Manual Test Checklist (Device Required)

### High Priority (P0)

- [ ] **B1**: Pick 12MP photo from gallery → crop → preview shows text readable on both light/dark areas
- [ ] **B2**: Apply design with image background → home widget shows correct image (not stretched)
- [ ] **B3**: Place same design on 2x1 and 4x2 widgets simultaneously → both display correctly
- [ ] **B4**: Resize widget by dragging → bitmap re-bakes for new size, no stretch
- [ ] **B5**: Create 3 designs (free) → 4th attempt shows "limit reached" dialog
- [ ] **B6**: Apply design → notification + widget + floating bar all update
- [ ] **B7**: Delete design → verify files removed from app storage

### Medium Priority (P1)

- [ ] **B8**: Share design → system share sheet opens with PNG preview
- [ ] **B9**: Rename design → name updates in grid
- [ ] **B10**: Long-press design → bottom sheet shows Apply/Share/Rename/Delete
- [ ] **B11**: Solid color background → apply → widget shows correct color
- [ ] **B12**: Gradient background → apply → widget shows gradient

### Regression (P0)

- [ ] **R1**: Notification icon still works after plan5 changes
- [ ] **R2**: Preset apply flow (reward → unlock → apply) still works
- [ ] **R3**: No ads appear on widget/notification/floating bar
- [ ] **R4**: No `showSeconds` anywhere in UI
- [ ] **R5**: App works offline (no new network calls)

### Device Matrix

| Device | Android Version | Priority |
|--------|----------------|----------|
| Pixel 7/8 | Android 14/15 | High |
| Samsung Galaxy S23 | Android 14 | High |
| Xiaomi 13 | Android 14 | Medium |

---

## 5. Known Limitations (V1.0)

1. **Blur not implemented in native widget** — `blurSigma` is stored in `BackgroundConfig` but the native `applyWidgetBackground()` only sets the bitmap directly. Blur is applied in Flutter preview only. Plan5 §4 says blur is optional and defaults to off.

2. **Auto text contrast not implemented** — `autoTextContrast` flag is stored but not actively computed. Text color is user-configured. Plan5 §4 says this is a "smart default" suggestion.

3. **Background not persisted in SharedPreferences** — `BackgroundConfig` is stored in `WidgetDesign` list (via `DesignStorageService`), not in the global `ClockConfig`. When user applies a design, the background is set in `HomeScreen._background` state but not persisted to SharedPreferences. This means background is lost on app restart unless the user re-applies the design.

4. **Share watermark always visible** — Plan5 §7 says watermark can be removed for Premium "sau này". V1.0 always shows watermark.

---

## 6. Recommendations

1. **Persist BackgroundConfig** — Consider saving the active design's background path to SharedPreferences so it survives app restart. Currently only ClockConfig is persisted.

2. **Native blur** — If blur is important for widget appearance, consider applying it during bitmap baking (in Flutter before sending to native) rather than in native code.

3. **Widget background re-bake trigger** — The `onAppWidgetOptionsChanged` clears the bitmap cache, but Flutter needs to be running to re-bake. If the app is killed and user resizes widget, the background will be lost until next app launch. Consider baking bitmaps for all active widget instances when the app comes to foreground.
