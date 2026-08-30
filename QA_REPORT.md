# QA Report — Date & Time Widget (Prompts 1–7)

> **Phương pháp:** Static code review toàn diện. Không có thiết bị Android trong môi trường này,
> nên KHÔNG có screenshot thật. Mọi findings bên dưới là từ review code — cần verify trên máy thật.

---

## A. FINDINGS từ Code Review (ưu tiên theo severity)

### 🔴 CRITICAL — Phải fix trước khi release

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| C1 | **FloatingBarService không tự cập nhật khi config thay đổi từ Editor** | `home_screen.dart` | Editor save → `WidgetBridge.updateWidgets()` + `_notifService.update()` nhưng **KHÔNG gọi `FloatingBarBridge.update()`**. User đổi format/font/color trong Editor → floating bar giữ nguyên format cũ cho đến khi reboot. |
| C2 | **EditorScreen vẫn hiển thị banner placeholder** | `editor_screen.dart` dòng ~310 | Editor có `Container(height: 60)` với text "AdMob Banner" ở cuối Column. Theo plan §3, Editor **KHÔNG được có banner**. Placeholder này gây nhầm lẫn và khi Prompt 6 thêm `AdBanner` widget thật, nó sẽ hiển thị sai vị trí. |
| C3 | **NotificationIconService không tự cập nhật theo thời gian** | `NotificationIconService.kt` | Service chỉ gọi `nm.notify()` khi `start()` hoặc `update()` được gọi. **Không có timer** — notification hiển thị "08:35" lúc 8:35 nhưng đến 9:00 vẫn hiện "08:35" cho đến khi user mở app và save config. Widget và floating bar có timer 60s, notification thì KHÔNG. |

### 🟡 HIGH — Có thể gây crash hoặc sai dữ liệu trên một số máy

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| H1 | **Notification icon bitmap có thể bị Samsung/Missing clip** | `NotificationIconService.kt` | `createDayBitmap()` tạo 64×64px. Samsung thường crop icon tròn → số "30" có thể bị cắt 1-2px ở cạnh. Xiaomi có thể mask thành hình khác. **Cần test thực tế và điều chỉnh padding nếu cần.** |
| H2 | **AlarmManager có thể bị Android 12+ hạn chế** | `DateTimeWidgetProvider.kt` | `setExactAndAllowWhileIdle()` cần `SCHEDULE_EXACT_ALARM` permission trên Android 12+. Đã có permission trong manifest, nhưng một số OEM (Xiaomi, Samsung) có thể tự ý tắt alarm để tiết kiệm pin. Widget sẽ hiển thị sai giờ nếu alarm bị kill. |
| H3 | **FloatingBarService từ BOOT_COMPLETED trên Android 15** | `BootReceiver.kt` | `startForegroundService()` từ BroadcastReceiver trên Android 15 có thể bị hạn chế nếu app chưa có foreground activity. BOOT_COMPLETED là trusted context nhưng một số OEM restrict hơn stock Android. |
| H4 | **IAP stream listener leak** | `main.dart` | `IapService` có `_subscription` listener nhưng không gọi `dispose()` trong `main()` hoặc app lifecycle. Nếu app bị kill đột ngột, stream có thể bị leak. |
| H5 | **FloatingBarService duplicate formatting logic** | `FloatingBarService.kt` | Viết lại toàn bộ logic format date/time/day riêng (không dùng chung với Flutter). Nếu logic Flutter thay đổi (thêm format mới) nhưng native không cập nhật → hiển thị khác nhau giữa app và floating bar. |

### 🟡 MEDIUM — UX hoặc edge case

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| M1 | **Widget không responsive với font scale system** | `widget_*.xml` | Font size hardcode trong XML (22sp, 30sp, 38sp). Nếu user设置 hệ thống font lớn (accessibility), widget text có thể bị tràn layout. |
| M2 | **Floating bar background hardcode `0xCC000000`** | `FloatingBarService.kt` | Nền luôn đen semi-transparent, không tuân thủ `ClockConfig.color`. User chọn nền trắng hoặc màu sáng → floating bar vẫn nền đen. |
| M3 | **Rewarded ad network error không có retry** | `ads_service.dart` | Nếu `onAdFailedToLoad` → `_rewardedAd = null` và không retry. User tap "Watch" khi ad fail → dialog "Watch" hiện nhưng `showRewardedAd()` return `false` → preset không unlock và không có feedback. |
| M4 | **EditorScreen không lưu khi back nhanh** | `editor_screen.dart` | User chỉnh config trong Editor rồi bấm back (không bấm Save) → thay đổi bị mất. UX rõ ràng nhưng có thể gây confusion. |
| M5 | **`permission_handler` có thể không cần thiết** | `notification_service.dart` | Chỉ dùng `Permission.notification.request()`. Có thể dùng native `ActivityCompat.requestPermission()` thay vì thêm dependency. Tuy nhiên không phải bug. |

### 🟢 LOW — Enhancement hoặc cosmetic

| # | Vấn đề | File | Chi tiết |
|---|--------|------|----------|
| L1 | **ClockPreview `withValues(alpha:)` deprecated** | `clock_preview.dart` | Dùng `withValues(alpha: 0.85)` — có thể deprecated trong Flutter version tương lai. Nên dùng `withOpacity(0.85)`. |
| L2 | **No deep link từ widget tap** | `DateTimeWidgetProvider.kt` | Tap widget mở app nhưng không navigate đến screen cụ thể. Không phải bug nhưng có thể improve UX. |
| L3 | **BootReceiver không kiểm tra SDK version** | `BootReceiver.kt` | `FloatingBarService.start()` gọi `startForegroundService()` — nếu boot trên Android < O, sẽ crash (nhưng practically không ai dùng Android < 8 anymore). |

---

## B. ACCEPTANCE CRITERIA CHECK (mục 8 plan1_final.md)

| Criteria | Code Status | Ghi chú |
|----------|-------------|---------|
| Widget hiển thị đúng time/date/day, tự cập nhật, sống sót qua reboot | ✅ Code OK | AlarmManager 60s + BootReceiver restart. **Cần test thực tế.** |
| Notification icon hiển thị và cập nhật đúng | ⚠️ **Có bug C3** | Không tự cập nhật theo thời gian — cần fix timer. |
| Config thay đổi trong Editor phản ánh ngay trong Preview, Widget, Notification | ⚠️ **Thiếu floating bar** (C1) | Preview ✅, Widget ✅, Notification ✅, **Floating bar ❌** |
| Rewarded Video unlock đúng preset, lưu bền vững qua restart | ✅ Code OK | `unlockedPresets` persist via SharedPreferences JSON roundtrip. |
| IAP Remove Ads tắt toàn bộ banner/rewarded prompt vĩnh viễn | ✅ Code OK | `isPremium` persist, `showBanners` check, `unlockPreset` skip when premium. |
| Không có ads trên Widget/Notification/Floating Bar | ✅ Code OK | Không có code ads nào trong các file native services. |
| Floating Bar không chồng lên status bar thật | ✅ Code OK | `y = statusBarHeight` trong `createLayoutParams()`. |
| Onboarding giải thích đúng bản chất kỹ thuật | ✅ Code OK | Dialog nói rõ "does NOT modify your phone's status bar". |
| App hoạt động offline (trừ ads) | ✅ Code OK | Storage local, config đọc từ SharedPreferences. |
| Test trên Android 12–16, 3 dòng máy | ⚠️ **Chưa test** | Cần chạy trên máy thật. |

---

## C. TEST CASES CHECK (mục 9 plan1_final.md)

### Test Case 1: Đổi format ngày → widget cập nhật trong < 5s

**Cách test:**
1. Mở app → Editor → đổi format từ "EEE dd MMM" sang "dd/MM/yyyy" → Save
2. Quay về home screen → kiểm tra widget
3. Đợi tối đa 5 giây

**Dự kiến:** Widget cập nhật (MethodChannel `updateWidgets()` triggered ngay sau save)
**Code status:** ✅ Logic đúng — `WidgetBridge.updateWidgets()` called in `EditorScreen._save()`
**Rủi ro:** Widget layout XML dùng `SimpleDateFormat` với pattern — cần confirm pattern match

### Test Case 2: Reboot → widget + notification tự khởi động lại

**Cách test:**
1. Bật notification + thêm widget
2. Reboot emulator/device
3. Sau khi boot xong → kiểm tra widget hiển thị giờ mới
4. Kiểm tra notification icon xuất hiện

**Dự kiến:** BootReceiver → restart notification + updateAllWidgets + scheduleAlarm
**Code status:** ✅ Logic đúng — BootReceiver xử lý cả 3 services
**Rủi ro:** AlarmManager có thể bị delay 1-2 phút sau boot do Doze mode

### Test Case 3: Tắt màn hình 10 phút → mở lại → thời gian đúng

**Cách test:**
1. Ghi lại thời gian hiện tại
2. Tắt màn hình 10 phút
3. Mở lại → kiểm tra widget hiển thị giờ mới (không phải giờ cũ)

**Dự kiến:** Widget cập nhật khi `onUpdate()` được gọi (AlarmManager trigger)
**Code status:** ⚠️ `setExactAndAllowWhileIdle()`应该 bypass Doze, nhưng một số OEM có thể delay
**Rủi ro:** Samsung/Mi implementations có thể kill alarm

### Test Case 4: Đổi timezone → app cập nhật

**Cách test:**
1. Mở app → thấy giờ hiện tại
2. Vào Settings → đổi timezone
3. Quay về app → giờ phải cập nhật

**Dự kiến:** `Calendar.getInstance()` dùng system timezone → tự cập nhật
**Code status:** ✅ `DateTime.now()` và `Calendar.getInstance()` reflect system timezone realtime
**Rủi ro:** Widget chỉ cập nhật mỗi 60s → có thể delay 0-60s

### Test Case 5: Mất mạng giữa lúc xem ad → không unlock giả

**Cách test:**
1. Bật airplane mode
2. Tap preset locked → dialog "Watch" hiện
3. Tap "Watch"
4. Ad fail to load → preset KHÔNG được unlock

**Dự kiến:** `onAdFailedToShowFullScreenContent` → `completer.complete(false)` → unlockLogic không chạy
**Code status:** ✅ `_showAndEarn()` only unlock when `earned == true`
**Edge case:** Nếu ad load thành công nhưng mất mạng giữa lúc xem → `onAdDismissedFullScreenContent` → `rewardEarned = false` → không unlock ✓

### Test Case 6: Mua IAP → restart app → vẫn premium

**Cách test:**
1. Settings → Buy Premium → complete purchase
2. Kill app
3. Mở lại → Settings hiện "Premium Active", không có banner

**Dự kiến:** `isPremium = true` saved in SharedPreferences → persist qua restart
**Code status:** ✅ `_markPremium()` → `_storage.saveConfig()` → SharedPreferences persists
**Rủi ro:** Nếu `_handlePurchase` bị interrupt trước khi `_markPremium()` → purchase lost. Cần `restorePurchases()` on next init.

### Test Case 7: Từ chối quyền notification → widget vẫn dùng được

**Cách test:**
1. Mở app → tap "Enable Notification"
2. Dialog hiện → tap "Enable"
3. System permission dialog → tap "Don't allow"
4. Widget vẫn hoạt động bình thường

**Dự kiến:** Notification denied → chỉ notification không hoạt động, widget独立
**Code status:** ✅ Widget (`DateTimeWidgetProvider`) không phụ thuộc notification service

### Test Case 8: Bật Floating Bar trên Android 15 → không crash

**Cách test:**
1. Trên device Android 15+
2. Tap "Enable Floating Bar" → grant permission
3. Floating bar xuất hiện ngay dưới status bar
4. Không có crash

**Dự kiến:** `startForeground()` called before `addOverlay()` → satisfies Android 15 requirement
**Code status:** ⚠️ Cần verify `FOREGROUND_SERVICE_SPECIAL_USE` accepted by Play Store
**Rủi ro:** Google có thể reject app với `specialUse` type nếu không giải thích rõ trong store listing

### Test Case 9: Widget resize (2x1 → 4x2) → nội dung co giãn

**Cách test:**
1. Thêm widget 4x1
2. Long-press widget → resize thành 4x2
3. Nội dung phải tự co giãn, không vỡ layout

**Dự kiến:** `chooseLayout()` detects size change → switch layout XML
**Code status:** ✅ `AppWidgetManager.getAppWidgetOptions()` → `OPTION_APPWIDGET_MIN_WIDTH` → choose layout
**Rủi ro:** Resize có thể không trigger `onUpdate()` ngay → cần chờ 60s hoặc tap widget

### Test Case 10: Uninstall → reinstall → không còn dữ liệu cũ

**Cách test:**
1. Cài app, config một số settings
2. Gỡ cài đặt
3. Cài lại

**Dự kiến:** SharedPreferences bị xóa khi uninstall
**Code status:** ✅ Android xóa app data khi uninstall
**Rủi ro:** Không có — Android guarantee

---

## D. DEVICE-SPECIFIC CONCERNS

### Pixel (target user chính)

| Vấn đề | Risk | Ghi chú |
|--------|------|---------|
| Notification icon crop | Trung bình | Pixel stock Android render monochrome icon chuẩn nhất. Bitmap 64×64应该 work well. |
| AlarmManager | Thấp | Stock Android không restrict alarm quá mức. |
| Foreground service | Thấp | Pixel chạy Android gốc, ít restrict hơn OEM. |
| Battery optimization | Trung bình | Pixel có aggressive Doze. `setExactAndAllowWhileIdle` should bypass. |

### Samsung

| Vấn đề | Risk | Ghi chú |
|--------|------|---------|
| Notification icon | **Cao** | Samsung One UI có thể crop icon thành hình tròn. Số "30" có thể bị cắt. **Cần test và possibly tăng padding trong bitmap.** |
| Battery optimization | **Cao** | Samsung "Device Care" tự kill background services. Widget có thể bị delay. **Cần hướng dẫn user tắt "Put app to sleep".** |
| AlarmManager | Trung bình | Samsung có thể delay alarms trong "Deep sleeping apps". |
| Overlay permission | Thấp | Samsung hỗ trợ SYSTEM_ALERT_WINDOW tốt. |

### Xiaomi (MIUI/HyperOS)

| Vấn đề | Risk | Ghi chú |
|--------|------|---------|
| Autostart permission | **Cao** | MIUI yêu cầu "Autostart" permission riêng. Nếu không grant → BootReceiver có thể không chạy. **Cần onboarding giải thích.** |
| Battery optimization | **Cao** | MIUI "Battery saver" kill apps mạnh nhất. Widget và floating bar có thể bị kill. |
| Notification icon | Trung bình | MIUI render icon khác stock Android. |
| Overlay | Trung bình | MIUI có thể có additional "Display pop-up window" permission. |

---

## E. MANUAL TEST CHECKLIST (chạy trên máy thật)

### Pre-test setup
```
□ Chuẩn bị 3 devices:
  - Pixel (Android 14 hoặc 15) — ưu tiên cao nhất
  - Samsung (Android 13 hoặc 14)
  - Xiaomi (Android 12 hoặc 13)
□ Mỗi device: cài app, tạo shortcut adb logcat
□ Disable battery optimization cho app trên mỗi device
```

### F0. Installation & First Launch
```
□ App cài thành công trên cả 3 devices
□ Onboarding screen hiển thị đúng (nếu có)
□ Home screen hiện ra với ClockPreview live
□ Banner ad hiển thị ở bottom (test ID)
□ Không có crash khi mở lần đầu
```

### F1. Live Clock (P0)
```
□ ClockPreview hiển thị đúng giờ, ngày, thứ
□ Tự cập nhật mỗi giây (đồng hồ chạy)
□ Hiển thị đúng format mặc định: "EEE dd MMM" + "HH:mm"
□ Đổi timezone system → clock cập nhật trong < 60s
```

### F2. Editor (P0)
```
□ Mở Editor từ Home → tap "Customize"
□ Đổi date format → preview cập nhật ngay
□ Đổi 12h/24h → preview cập nhật ngay
□ Toggle showSeconds → preview cập nhật ngay
□ Toggle showDay/showDate → preview cập nhật ngay
□ Drag font size slider → preview thay đổi mượt
□ Tap color swatch → preview đổi màu ngay
□ Tap alignment buttons → preview đổi vị trí ngay
□ Bấm Save → quay về Home, config mới được lưu
□ Bấm Back (không Save) → config cũ vẫn giữ
□ Preview KHÔNG bị banner che (editor không có banner)
```

### F3. Presets (P0)
```
□ Mở Presets từ Home → grid 8 preset hiển thị
□ Free presets: tap → preview áp dụng →返回 Home với config mới
□ Locked presets: tap → dialog "Watch a short ad"
□ Tap "Watch" → test ad hiện → xem xong → preset unlock
□ Tap "Cancel" → không unlock
□ Preset đã unlock vẫn unlock sau restart app
```

### F4. Home Screen Widget (P0)
```
□ Long-press home → Widgets → tìm "Date & Time Widget"
□ Thêm widget 4x1 → hiển thị đúng time/date/day
□ Resize widget → layout tự thay đổi
□ Đổi config trong app → save → widget cập nhật trong < 5s
□ Tap widget → mở app
□ Reboot → widget tự restore
□ Widget hiển thị đúng giờ sau reboot (không lệch)
```

### F5. Notification Icon (P0)
```
□ Tap "Enable Notification" → dialog giải thích
□ Tap "Enable" → permission dialog (Android 13+)
□ Grant → notification icon xuất hiện trong status bar
□ Icon hiển thị số ngày (vd "30")
□ Pull down notification → thấy "Sunday, 30 August 2026" + "08:35"
□ Đổi config trong Editor → save → notification cập nhật nội dung
□ Deny permission → widget vẫn hoạt động
□ Disable notification → icon biến mất
□ Reboot → notification tự restore (nếu đã enable)
```

### F5b. Notification Icon — OEM-Specific
```
□ [Samsung] Kiểm tra icon có bị crop thành hình tròn không
□ [Samsung] Kiểm tra số có bị cắt 1-2px ở cạnh không
□ [Xiaomi] Kiểm tra icon có hiển thị đúng không
□ [Pixel] Kiểm tra icon hiển thị rõ ràng
□ [Tất cả] So sánh hình dạng icon giữa 3 máy — chụp ảnh
```

### F6. AdMob (P0)
```
□ Banner hiển thị ở bottom Home screen
□ Banner hiển thị ở bottom Settings screen
□ Banner KHÔNG hiển thị trong Editor screen
□ Rewarded ad hiện khi tap preset locked
□ Rewarded ad xem xong → preset unlock
□ Mua "Remove Ads" → tất cả banner biến mất
□ Mua "Remove Ads" → preset locked →直接 unlock (không ad dialog)
□ Restart app sau khi mua → vẫn premium, không có banner
□ Restore Purchase hoạt động
```

### F7. Floating Bar (P1)
```
□ Tap "Enable Floating Bar" → dialog giải thích KHÔNG phải sửa status bar
□ Tap "Continue" → system settings "Display over other apps"
□ Grant permission → quay về app → tap "Enable" again
□ Floating bar xuất hiện NGAY DƯỚI status bar
□ Bar hiển thị đúng day, date, time
□ Bar cập nhật mỗi phút
□ Swipe-down notification shade vẫn hoạt động (bar không chặn)
□ Tap floating bar → không có response (FLAG_NOT_FOCUSABLE)
□ Disable từ app → bar biến mất
□ Config thay đổi trong Editor → floating bar cập nhật
□ Reboot → floating bar tự restore
```

### F7b. Floating Bar — Android 15+
```
□ [Android 15] Bật floating bar → không crash
□ [Android 15] Floating bar hoạt động bình thường
□ [Android 15] Floating bar survive screen off/on
```

### F8. Boot Recovery (P0)
```
□ Bật notification + floating bar + thêm widget
□ Reboot device
□ Sau boot: widget hiển thị giờ mới
□ Sau boot: notification icon xuất hiện
□ Sau boot: floating bar hoạt động
□ Không cần mở app để restore
```

### F9. Edge Cases
```
□ Tắt màn hình 10 phút → mở lại → giờ đúng (không lệch)
□ Đổi timezone → tất cả (preview, widget, notification, floating bar) cập nhật
□ Font scale system lớn → widget không vỡ layout
□ Dark mode → widget readability OK
□ Light mode → widget readability OK (widget nền đen semi-transparent)
□ App trong background 1 giờ → mở lại → giờ đúng
□ Battery: 1 giờ chạy nền → kiểm tra pin consumption
```

### F10. Policy Self-Check
```
□ KHÔNG có ads trên widget
□ KHÔNG có ads trên notification
□ KHÔNG có ads trên floating bar
□ Onboarding nói "does NOT modify status bar"
□ Store listing KHÔNG hứa "giống Samsung 100%"
□ Rewarded ad chỉ hiện khi user chủ động tap
□ IAP "Remove Ads" tắt tất cả ads
```

---

## F. FIXES ĐỀ XUẤT (không tự ý implement — chờ confirmation)

### Fix C1: FloatingBarBridge.update() missing in Editor/Presets save flow

```dart
// home_screen.dart — _openEditor()
if (updated != null && mounted) {
  setState(() => _config = updated);
  WidgetBridge.updateWidgets();
  _notifService.update();
  FloatingBarBridge.update();  // ← THÊM DÒNG NÀY
}
```

Tương tự trong `_openPresets()`.

### Fix C2: Editor banner placeholder

```dart
// editor_screen.dart — thay Container placeholder bằng SizedBox.shrink()
// hoặc xóa hoàn toàn phần banner placeholder
```

### Fix C3: NotificationIconService cần timer tự cập nhật

```kotlin
// NotificationIconService.kt — thêm Handler + Runnable
private val handler = Handler(Looper.getMainLooper())
private val updateRunnable = object : Runnable {
    override fun run() {
        update(context) // caller needs context
        handler.postDelayed(this, 60_000)
    }
}
```

Hoặc đơn giản hơn: dùng AlarmManager tương tự DateTimeWidgetProvider.

### Fix H3: BootReceiver floating bar — thêm try-catch

```kotlin
try {
  if (FloatingBarService.isEnabled(context)) {
    FloatingBarService.start(context)
  }
} catch (e: Exception) {
  // Log but don't crash boot receiver
}
```

### Fix L1: `withValues(alpha:)` → `withOpacity(alpha:)`

```dart
// clock_preview.dart
color: _textColor.withOpacity(0.85),
```

---

## G. BATTERY TEST PROTOCOL

```
Test battery impact sau 1 giờ chạy nền:

1. Screenshot battery level trước test
2. Bật: widget + notification icon + floating bar
3. Để app chạy nền 1 giờ (không mở app)
4. Screenshot battery level sau test
5. Tính delta

Dự kiến battery impact:
- Widget: AlarmManager 1 lần/phút → ~0.1%/giờ
- Notification: Cập nhật khi config thay đổi → ~0%/giờ
- Floating Bar: Handler 1 lần/phút → ~0.2%/giờ
- Tổng: < 0.5%/giờ (acceptable)

Nếu > 1%/giờ → cần optimize:
- Widget: tăng interval lên 5 phút
- Floating bar: tăng interval lên 2 phút
```

---

*Báo cáo này cần được verify bằng cách chạy test trên máy thật.*
*Không implement fix nào cho đến khi user confirm findings và approve scope.*
