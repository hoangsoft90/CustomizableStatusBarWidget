# plan3_final.md — Correction Plan cho AI Coding Agent

Tổng hợp từ `plan3.md` + `plan3_review1.md` → `plan3_review4.md`, đã **verify trực tiếp với source code thực tế** tại:
`/Users/hoang/htdocs_apps/CustomizableStatusBarWidget/source/date_time_widget/`

Thông tin xác nhận trước khi làm:
- `pubspec.yaml` → `version: 1.0.0+1` — app **chưa release**, không có git repo. → **Không cần migration/grandfather cho legacy "unlock forever"**, xóa thẳng semantics cũ.
- Sync kiến trúc là **một chiều Flutter → Native qua MethodChannel** (`widget_bridge.dart`, `floating_bar_bridge.dart`, `notification_service.dart`). Native không có cơ chế tự chọn preset. → **Flutter là gatekeeper duy nhất**, Native không cần biết `RewardState`.

STOP FEATURE DEVELOPMENT. Không thêm tính năng mới ngoài 2 task dưới đây. Không đổi product positioning. Làm tuần tự: hoàn thành + pass acceptance criteria Task A rồi mới sang Task B. Task C chạy sau cùng.

---

## TASK A — REMOVE "SHOW SECONDS" (ưu tiên cao, đang có bug hiển thị)

### Root cause (đã xác nhận trong code)

1. **Android không thể tick theo giây ổn định**: widget chỉ nhận `ACTION_TIME_TICK` (mỗi phút). Cố ép chạy mỗi giây bằng `Handler`/`AlarmManager` sẽ gây hao pin, bị OEM (Samsung/Xiaomi...) kill process.
2. **Bug double seconds** xác nhận đúng ở **cả 3 file native**:
   - `DateTimeWidgetProvider.kt` dòng 171
   - `NotificationIconService.kt` dòng 103
   - `FloatingBarService.kt` dòng 335, 349, 352 (nối thủ công `":$mm:${pad(cal.get(Calendar.SECOND))}"`, phức tạp hơn 2 file kia — dễ bị bỏ sót)

   Logic sai:
   ```kotlin
   val timePattern = if (config.showSeconds) {
       config.timeFormat.replace("mm", "mm:ss")
   } else {
       config.timeFormat
   }
   ```
   Với preset có `timeFormat = "HH:mm:ss"` + `showSeconds = true` → `replace("mm","mm:ss")` biến thành `HH:mm:ss:ss` → hiển thị `08:35:42:42`.

3. Flutter Editor (`editor_screen.dart` dòng 198-200) vẫn có toggle "Show seconds"; Flutter formatter (`date_formatter.dart` dòng 20) xử lý khác quy tắc so với Native → hai bên không đồng bộ logic.

4. **2 preset built-in đang chứa bug thật** (`lib/models/presets.dart`):
   - `basic3` (dòng ~35-40): `timeFormat: 'HH:mm:ss'`, `showSeconds: true`
   - `premium2` (dòng ~100-106): `timeFormat: 'HH:mm:ss'`, `showSeconds: true`

### Yêu cầu cụ thể

**1. `lib/models/clock_config.dart`**
- Xóa field `showSeconds` khỏi: class field (dòng 12), constructor (dòng 44), `fromJson` (dòng 64), `toJson` (dòng 90), `copyWith` (dòng 110, 124), `==` (dòng 144), `hashCode` (dòng 159).
- Trong `fromJson`: JSON cũ có thể còn `"showSeconds"` hoặc `timeFormat` chứa `ss`. Bỏ qua field `showSeconds` (không đọc, không lưu), và **normalize timeFormat**:
  ```dart
  String normalizeTimeFormat(String format) {
    return format
        .replaceAll(RegExp(r':?ss'), '')   // HH:mm:ss → HH:mm ; hh:mm:ss a → hh:mm a
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
  ```
  Áp dụng: `timeFormat: normalizeTimeFormat(json['timeFormat'] as String? ?? 'HH:mm')`

**2. `lib/screens/editor_screen.dart`**
- Xóa toàn bộ `_ToggleRow` "Show seconds" (khoảng dòng 195-201).

**3. `lib/utils/date_formatter.dart`**
- Xóa logic `if (config.showSeconds) { result = result.replaceAll('ss', ss); }` (dòng ~20).
- Chỉ hỗ trợ 2 format chuẩn: `HH:mm` (24h) và `hh:mm a` (12h).

**4. `lib/models/presets.dart`**
- `basic3`: đổi `timeFormat: 'HH:mm:ss'` → `'HH:mm'`, xóa field `showSeconds: true`.
- `premium2`: tương tự, đổi `timeFormat: 'HH:mm:ss'` → `'HH:mm'`, xóa `showSeconds: true`.

**5. Native Android — sửa cả 3 file, không được bỏ sót file nào:**

- `android/.../DateTimeWidgetProvider.kt`
- `android/.../NotificationIconService.kt`
- `android/.../FloatingBarService.kt`

Với mỗi file:
- Xóa field `showSeconds: Boolean` khỏi data class `ClockData`.
- Xóa dòng parse `showSeconds = extract("showSeconds") == "true"`.
- Xóa toàn bộ khối `if (config.showSeconds) { ... } else { ... }` liên quan format giây.
- Dùng thẳng `SimpleDateFormat(config.timeFormat, Locale.getDefault())`.
- **Chú ý riêng cho `FloatingBarService.kt`**: có 2 nhánh nối chuỗi thủ công ở dòng 349 và 352, không chỉ 1 khối `if/else` như 2 file kia, phải xóa cả 2 nhánh và dùng logic format thống nhất.

**6. Tests — viết lại theo behavior mới, không chỉ sửa cho pass:**
- `test/date_formatter_test.dart`, `test/editor_config_test.dart`, `test/storage_service_test.dart`, `test/plan2_fixes_test.dart` — xóa mọi expectation liên quan `showSeconds`.
- **Thêm test migration mới** cho JSON legacy có `showSeconds: true` + `timeFormat: "HH:mm:ss"` / `"hh:mm:ss a"` → normalize đúng, không crash.

### Acceptance Criteria — Task A

- [ ] Không còn field `showSeconds` ở bất kỳ đâu trong Flutter và Native (cả 3 file `.kt`).
- [ ] Editor không còn toggle "Show seconds".
- [ ] Không còn preset nào chứa `ss` trong `timeFormat`.
- [ ] Widget / FloatingBar / Notification chỉ hiển thị `HH:mm` hoặc `hh:mm a`.
- [ ] Không còn hiện tượng double seconds (`08:35:42:42`).
- [ ] Legacy JSON vẫn load được, không crash, `timeFormat` được normalize.
- [ ] Tất cả unit test liên quan pass.

---

## TASK B — DAILY REWARD ENTITLEMENT

### Hiện trạng (đã xác nhận trong code)

- `lib/services/ads_service.dart` (`unlockPreset()`): dialog *"Watch a short ad to unlock this preset forever?"* → sau khi xem ad → append `presetId` vào `ClockConfig.unlockedPresets` → lưu vĩnh viễn.
- `lib/screens/presets_screen.dart` dòng 90: check trực tiếp `currentConfig.unlockedPresets.contains(preset.id)`.
- `lib/services/iap_service.dart` dòng 110: khi mua Premium set `unlockedPresets: allPresetIds` — dùng chung field với Rewarded, cần tách rõ.

Vấn đề: xem 1 ad → unlock vĩnh viễn → gần như zero recurring revenue.

### Yêu cầu cụ thể

**1. Tạo `lib/models/reward_state.dart`** — `date` (yyyy-MM-dd), `unlockCount`, `unlockedToday: List<String>`. Persist SharedPreferences key riêng (`"reward_state"`), không gộp vào `clock_config`.

**2. Tạo `lib/services/reward_service.dart`** với methods:
```dart
Future<void> resetIfNewDay();
bool canUsePreset(String presetId, {required bool isPremium, required bool isFreePreset});
int remainingUnlocksToday();
Future<bool> unlockToday(String presetId);
```
Business rule ưu tiên: free preset → true; premium → true; đã unlock hôm nay → true; còn lượt (`unlockCount < 2`) → cho xem ad; hết lượt → false.

**Quan trọng:** `unlockToday()` phải đọc `RewardState` mới nhất trực tiếp từ storage tại thời điểm gọi, không dùng snapshot cũ truyền từ UI (tránh stale write, giống pattern `_isPremium` hiện tại luôn đọc trực tiếp từ storage).

**3. Sửa `ads_service.dart`**: xóa logic append `unlockedPresets`; `unlockPreset()` gọi `RewardService.unlockToday()` sau khi ad earned; dialog đổi thành *"Watch a short ad to use this preset today?"* + hiển thị số lượt còn lại.
**Bổ sung:** khi hết lượt, dừng `preloadRewarded()` luôn, không chỉ chặn UI.

**4. Sửa `presets_screen.dart`**: thay check `unlockedPresets.contains()` bằng `rewardService.canUsePreset()`. Phân biệt rõ UI: Free / Locked-còn lượt / Locked-hết lượt / Premium.

**5. `clock_config.dart`**: xóa field `unlockedPresets` hoàn toàn; `fromJson` ignore field này nếu gặp JSON cũ.

**6. `iap_service.dart`**: xóa `unlockedPresets: allPresetIds` khi set Premium — chỉ cần `isPremium = true`.

**7. Migration**: app chưa release (version 1.0.0+1, không có git) → không cần grandfather, xóa thẳng semantics cũ.

**8. Native**: không cần thay đổi — Flutter là gatekeeper duy nhất qua MethodChannel một chiều.

### Task C — Viết lại test

`test/iap_premium_test.dart` (5 test case dòng 25-70) test đúng semantics "unlock forever" → viết lại hoàn toàn thành test cho `RewardService` (reset qua ngày, tăng count, giới hạn 2/ngày enforce ở service, premium override, free preset luôn true, không stale write). Cập nhật `storage_service_test.dart`, `editor_config_test.dart`, `plan2_fixes_test.dart` để bỏ mọi reference `unlockedPresets`.

### Acceptance Criteria — Task B

- [ ] Không còn field `unlockedPresets` trong `ClockConfig`.
- [ ] `RewardState` lưu riêng, có `date` + `unlockCount` + `unlockedToday`.
- [ ] Passive reset khi mở app / PresetsScreen nếu khác ngày.
- [ ] Free preset luôn dùng được; Premium override toàn bộ.
- [ ] Xem ad → unlock chỉ trong ngày hôm đó (local calendar).
- [ ] Tối đa 2 unlock/ngày, enforce ở service; hết lượt dừng preload ad.
- [ ] Dialog wording "today", không còn "forever".
- [ ] Qua ngày mới → reset count + clear unlockedToday.
- [ ] Tất cả test liên quan viết lại và pass.

---

## QUY TẮC CHUNG CHO AGENT

- Không thêm feature mới ngoài Task A + B (+ C là dọn test).
- Không đổi product name / Store positioning.
- Không đặt quảng cáo lên Notification / Widget / Floating Bar.
- Làm Task A trước, pass hết acceptance criteria rồi mới sang Task B.
- Sau khi hoàn thành, chạy lại `flutter test` toàn bộ và báo cáo kết quả đầy đủ.
- Nếu phát hiện conflict không có trong plan này, ưu tiên giải pháp đơn giản, ổn định, ít phá kiến trúc, và báo lại trước khi tự ý mở rộng phạm vi.