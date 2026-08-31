# plan4_final.md — Correction Prompt cho AI Coding Agent (P0 trước release V1)

Tổng hợp từ `plan4.md` + `plan4_review1..4.md` + `features.md`/`features1.md`, đã **verify trực tiếp với source code thực tế** tại:
`/Users/hoang/htdocs_apps/CustomizableStatusBarWidget/source/date_time_widget/`

**Toàn bộ 4 bản review đều đúng ở phần root-cause đã chỉ ra.** Khi đọc source, tôi phát hiện thêm **1 bug mới (Bug C)** mà không bản review nào nhắc tới — nằm ngay cạnh Bug B, cùng gốc "quên gọi `storage.saveConfig()`" nhưng ảnh hưởng rộng hơn cả preset free lẫn locked. Đã gộp vào Task 2 dưới đây.

STOP FEATURE DEVELOPMENT. Không thêm tính năng mới. Không đổi product positioning. Làm tuần tự Task 1 → 2 → 3 → 4 → 5, pass acceptance criteria từng task trước khi sang task kế.

---

## TASK 1 — FIX `canUsePreset()` (Critical – Bypass Ad)

**File:** `lib/services/reward_service.dart`

Code hiện tại (đã đọc trực tiếp, đúng 100% như 4 review mô tả):
```dart
bool canUsePreset(String presetId,
    {required bool isPremium, required bool isFreePreset}) {
  if (isFreePreset) return true;
  if (isPremium) return true;

  final state = _loadState();
  if (state.unlockedToday.contains(presetId)) return true;
  return state.unlockCount < maxDailyUnlocks;   // ← BUG
}
```

**Nơi bug này gây hậu quả thật (điểm bổ sung — chưa review nào chỉ rõ dòng cụ thể):** Bug không chỉ ảnh hưởng UI hiển thị lock/unlock ở `presets_screen.dart`, mà còn khiến **`ads_service.dart` bỏ qua toàn bộ ad flow**. Trong `AdsService.unlockPreset()`:
```dart
if (_reward.canUsePreset(presetId,
    isPremium: currentConfig.isPremium, isFreePreset: isFreePreset)) {
  // Already unlocked today
  return true;   // ← với bug hiện tại, dòng này trả true kể cả preset CHƯA unlock, miễn còn lượt
}
```
→ Do `canUsePreset()` sai, dòng `return true;` này chạy sớm, **dialog "Watch a short ad..." không bao giờ hiện ra** với preset chưa unlock miễn còn lượt trong ngày → đúng là hiện tượng "xem/không xem gì cũng dùng được" mà bạn báo cáo.

**Fix:**
```dart
bool canUsePreset(String presetId,
    {required bool isPremium, required bool isFreePreset}) {
  if (isFreePreset) return true;
  if (isPremium) return true;

  final state = _loadState();
  return state.unlockedToday.contains(presetId);   // CHỈ điều này
}
```
Giữ nguyên `remainingUnlocksToday()`, `unlockToday()`, `resetIfNewDay()`, `maxDailyUnlocks = 2` — các phần này đã đúng, không cần sửa.

### ⚠️ Test hiện tại đang assert ĐÚNG theo hành vi lỗi — bắt buộc phải sửa cùng lúc

Đã đọc trực tiếp `test/reward_service_test.dart` và xác nhận các dòng sau đang **encode chính hành vi bug**, sẽ FAIL sau khi fix (đây là điều đúng, không phải agent làm sai):

```dart
// dòng 39 — trong test 'resets state when date changes'
// After reset, premium1 is NOT pre-unlocked — but unlocks are available
expect(service.canUsePreset('premium1', isPremium: false, isFreePreset: false), true);
// PHẢI sửa thành false — comment đã tự thừa nhận preset chưa unlock

// dòng 51 — trong test 'does NOT reset when same day'
// state có unlockedToday chứa 'premium1' → giữ true là ĐÚNG, không đổi

// dòng 69-70 — test 'locked preset returns true when unlocks remaining'
expect(service.canUsePreset('premium1', isPremium: false, isFreePreset: false), true);
// Tên test + assertion đều mô tả đúng bug. Phải đổi thành:
//   rename test → 'locked preset returns false when not yet unlocked, even with unlocks remaining'
//   expect(...) → false

// dòng 76 — trong test 'locked preset returns false when no unlocks remaining'
expect(service.canUsePreset('premium1', ...), true); // already unlocked — GIỮ NGUYÊN, đúng
expect(service.canUsePreset('premium3', ...), false); // limit reached — GIỮ NGUYÊN, đúng
```

**Yêu cầu:** Task 1 CHƯA xong nếu chỉ sửa `reward_service.dart` mà không cập nhật `test/reward_service_test.dart` theo đúng bảng trên. Không được xóa test để né fail — phải sửa expectation cho khớp behavior đúng, kèm sửa lại tên test nếu tên đang mô tả sai (như dòng 69).

### Acceptance Criteria — Task 1
- [ ] Locked preset chưa unlock hôm nay → `canUsePreset = false` dù còn lượt.
- [ ] Locked preset đã unlock hôm nay → `canUsePreset = true`.
- [ ] Free preset → luôn `true`.
- [ ] `isPremium = true` → luôn `true`.
- [ ] `AdsService.unlockPreset()` với preset chưa unlock, còn lượt → **phải hiện dialog xem ad**, không return `true` sớm.
- [ ] `remainingUnlocksToday()` vẫn hoạt động đúng (0–2), không bị đổi hành vi.
- [ ] `test/reward_service_test.dart` đã cập nhật đúng theo bảng trên, `flutter test test/reward_service_test.dart` pass 100%.

---

## TASK 2 — FIX Apply Preset sau Rewarded Ad + Fix việc chưa persist config khi chọn Preset (bao gồm cả Bug B lẫn Bug C mới)

**File chính:** `lib/screens/presets_screen.dart`, `lib/screens/home_screen.dart`

### Bug B (đã xác nhận, đúng như 4 review mô tả)

`_onLockedTap()` hiện tại:
```dart
final unlocked = await ads.unlockPreset(context, presetId, widget.currentConfig, isFreePreset: false);
if (unlocked && mounted) {
  final updatedConfig = storage.loadConfig();   // ← config CŨ, không phải preset.config
  setState(() => _selectedId = presetId);
  ...
  WidgetBridge.updateWidgets();                 // ← gọi không kèm configJson → native tự đọc SharedPreferences riêng của nó, KHÔNG liên quan gì tới config Flutter vừa "muốn" áp dụng
  Navigator.of(context).pop(updatedConfig);
}
```
`RewardState` đã ghi nhận unlock, nhưng `ClockConfig` (Flutter side) chưa từng được set thành `preset.config` ở đâu cả trong hàm này → pop về config cũ.

### Bug C — MỚI, chưa review nào phát hiện (đã trace toàn bộ chuỗi gọi để xác nhận)

Đây là bug **rộng hơn Bug B**, và ảnh hưởng **cả preset FREE lẫn LOCKED**, không chỉ riêng flow reward ads.

Trace chuỗi thực tế:

1. `_onSelect()` (chọn preset FREE) trong `presets_screen.dart`:
   ```dart
   void _onSelect(String presetId, ClockConfig config) {
     setState(() => _selectedId = presetId);
     WidgetBridge.updateWidgets();     // không configJson
     Navigator.of(context).pop(config);
   }
   ```
   Không hề gọi `storage.saveConfig(config)` ở đâu trong toàn bộ file `presets_screen.dart`.

2. `HomeScreen._openPresets()` trong `home_screen.dart` nhận `updated` config đã pop về:
   ```dart
   if (updated != null && mounted) {
     setState(() => _config = updated);
     final configJson = updated.toJsonString();
     WidgetBridge.updateWidgets(configJson: configJson);   // fresh — OK
     _notifService.update();                                // ← xem bug bên dưới
     FloatingBarBridge.update(configJson: configJson);       // fresh — OK
   }
   ```
   **`HomeScreen._openPresets()` cũng không gọi `widget.storage.saveConfig(updated)`.** So sánh với `_openEditor()` — cũng thiếu tương tự, nhưng ở đó không sao vì `EditorScreen` tự gọi `widget.storage.saveConfig(_config)` (dòng 112 trong `editor_screen.dart`) **trước khi** pop. `PresetsScreen` không có bước tương đương này ở bất kỳ nhánh nào (`_onSelect` lẫn `_onLockedTap`).

3. `NotificationService.update()` trong `notification_service.dart`:
   ```dart
   Future<void> update() async {
     if (!_loadEnabled()) return;
     final configJson = _storage.loadConfig().toJsonString();  // ← đọc lại từ SharedPreferences, KHÔNG dùng config vừa chọn
     await _updateNative(configJson: configJson);
   }
   ```
   Vì bước 1+2 chưa từng `saveConfig()`, `_storage.loadConfig()` ở đây trả về **config cũ trước khi chọn preset**.

**Hậu quả cụ thể (đã verify từng bước, không phải suy đoán):**
- Chọn **bất kỳ preset nào (kể cả preset FREE, không liên quan gì tới ads)** → Home Widget và Floating Bar cập nhật đúng ngay lập tức (vì `WidgetBridge`/`FloatingBarBridge` nhận `configJson` trực tiếp từ biến `updated` trong bộ nhớ).
- Nhưng **Notification Icon/Status Bar sẽ KHÔNG đổi theo preset mới** — nó gọi lại `_notifService.update()` nhưng hàm này đọc storage cũ, nên vẫn hiển thị config trước đó. Đây là **status bar icon** — chính là USP số 1 của app theo `features.md` mục 1 — nên bug này khá nghiêm trọng về UX.
- Nếu user thoát app rồi mở lại: `HomeScreen.initState()` chạy `_config = widget.storage.loadConfig()` → **quay lại đúng config cũ**, preset vừa chọn (kể cả preset free) coi như "biến mất" khỏi in-app preview và mọi lần cập nhật tiếp theo, cho tới khi user vào lại Editor và bấm Save (lúc đó Editor mới ghi `saveConfig` thật sự).

### Fix hoàn chỉnh cho Task 2 (gộp cả Bug B và Bug C)

**Nguyên tắc kiến trúc:** `PresetsScreen` chỉ có nhiệm vụ trả về đúng `ClockConfig` cần áp dụng (`preset.config`) qua `Navigator.pop`. **`HomeScreen` là single owner** chịu trách nhiệm: (a) `storage.saveConfig()`, (b) đẩy xuống cả 3 native surface (Widget/Notification/FloatingBar). `PresetsScreen` **không tự gọi `WidgetBridge.updateWidgets()`** nữa (bỏ 2 chỗ gọi thừa/sai trong `_onSelect` và `_onLockedTap`) để tránh 2 nơi cùng chịu trách nhiệm apply config.

**1. `lib/screens/presets_screen.dart`**

```dart
void _onSelect(String presetId, ClockConfig config) {
  setState(() => _selectedId = presetId);
  Navigator.of(context).pop(config);   // bỏ WidgetBridge.updateWidgets() thừa ở đây
}

Future<void> _onLockedTap(String presetId, String name) async {
  final ads = widget.adsService;
  final storage = widget.storage;
  final reward = widget.rewardService;
  if (ads == null || storage == null || reward == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$name" is locked — watch an ad to unlock.')),
    );
    return;
  }

  final preset = builtInPresets.firstWhere((p) => p.id == presetId);

  final unlocked = await ads.unlockPreset(
    context, presetId, widget.currentConfig, isFreePreset: false,
  );
  if (unlocked && mounted) {
    setState(() => _selectedId = presetId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"$name" unlocked for today!')),
    );
    Navigator.of(context).pop(preset.config);   // trả preset.config, KHÔNG phải storage.loadConfig()
  }
}
```

**2. `lib/screens/home_screen.dart`** — thêm bước `saveConfig` còn thiếu trong CẢ HAI hàm mở sub-screen trả về config (áp dụng luôn cho `_openEditor()` để nhất quán về sau, dù hiện tại `_openEditor()` không lỗi vì Editor tự save):

```dart
Future<void> _openEditor() async {
  final updated = await Navigator.of(context).push<ClockConfig>(
    MaterialPageRoute(builder: (_) => EditorScreen(config: _config, storage: widget.storage)),
  );
  if (updated != null && mounted) {
    await widget.storage.saveConfig(updated);   // idempotent — Editor đã save, nhưng an toàn khi gọi lại
    setState(() => _config = updated);
    final configJson = updated.toJsonString();
    WidgetBridge.updateWidgets(configJson: configJson);
    _notifService.update();
    FloatingBarBridge.update(configJson: configJson);
  }
}

Future<void> _openPresets() async {
  final updated = await Navigator.of(context).push<ClockConfig>(
    MaterialPageRoute(
      builder: (_) => PresetsScreen(
        currentConfig: _config,
        adsService: widget.adsService,
        storage: widget.storage,
        rewardService: widget.rewardService,
      ),
    ),
  );
  if (updated != null && mounted) {
    await widget.storage.saveConfig(updated);   // ← BƯỚC CÒN THIẾU — bắt buộc, fix cả Bug B lẫn Bug C
    setState(() => _config = updated);
    final configJson = updated.toJsonString();
    WidgetBridge.updateWidgets(configJson: configJson);
    _notifService.update();
    FloatingBarBridge.update(configJson: configJson);
  }
}
```

**Lưu ý thứ tự:** `saveConfig()` phải chạy **trước** `_notifService.update()`, vì `NotificationService.update()` đọc lại từ `storage.loadConfig()` — nếu gọi sai thứ tự, Notification vẫn sẽ stale.

### Acceptance Criteria — Task 2
- [ ] Xem ad thành công → clock đổi sang đúng preset vừa unlock, áp dụng ngay trên **cả 3 surface: Widget, Notification, Floating Bar** (không chỉ Widget/FloatingBar như trước khi fix).
- [ ] Chọn **preset FREE** → Notification Icon cũng đổi ngay lập tức (trước khi fix, đây là nơi bug C xảy ra âm thầm nhất vì không ai để ý free preset cũng bị ảnh hưởng).
- [ ] Thoát app rồi mở lại → preset vừa chọn (free hoặc đã unlock hôm nay) vẫn là config hiện tại, không revert về config cũ.
- [ ] Cùng preset lần 2 trong ngày → apply ngay, không trừ thêm lượt, không hiện ad.
- [ ] Hết 2 lượt → không cho xem ad, hiện "No unlocks left today. Come back tomorrow."
- [ ] Dismiss ad / ad fail → không unlock, không đổi config, cả 3 surface giữ nguyên như trước khi tap.
- [ ] `PresetsScreen` không còn gọi trực tiếp `WidgetBridge.updateWidgets()` ở bất kỳ đâu — chỉ `HomeScreen` gọi.

---

## TASK 3 — XÓA SẠCH `showSeconds` Ở NATIVE (P0 Technical Debt)

Đã grep xác nhận **13 dòng match** còn tồn tại, đúng như review3 liệt kê:

```
FloatingBarService.kt:335   val timePattern = if (config.showSeconds) {
FloatingBarService.kt:349   if (config.showSeconds) "${pad(h12)}:$mm:${pad(cal.get(Calendar.SECOND))} $period"
FloatingBarService.kt:352   if (config.showSeconds) "${pad(h24)}:$mm:${pad(cal.get(Calendar.SECOND))}"
FloatingBarService.kt:399   showSeconds = extract("showSeconds") == "true",
FloatingBarService.kt:462   val showSeconds: Boolean = false,
NotificationIconService.kt:103  val timePattern = if (config.showSeconds) {
NotificationIconService.kt:220  showSeconds = extract("showSeconds") == "true",
NotificationIconService.kt:255  val showSeconds: Boolean = false,
DateTimeWidgetProvider.kt:145   showSeconds = extract("showSeconds") == "true",
DateTimeWidgetProvider.kt:171   val timePattern = if (config.showSeconds) {
DateTimeWidgetProvider.kt:234   val showSeconds: Boolean = false,
```

**Yêu cầu cho MỖI trong 3 file (`DateTimeWidgetProvider.kt`, `NotificationIconService.kt`, `FloatingBarService.kt`):**
- Xóa field `val showSeconds: Boolean = false` khỏi data class `ClockData`.
- Xóa dòng `showSeconds = extract("showSeconds") == "true",` khi parse.
- Xóa toàn bộ khối `if (config.showSeconds) {...} else {...}` — dùng thẳng `SimpleDateFormat(config.timeFormat, Locale.getDefault())`.
- **`FloatingBarService.kt` cần chú ý riêng:** có 2 nhánh nối chuỗi thủ công ở dòng 349 và 352 (khác cấu trúc if/else đơn giản như 2 file kia), phải xóa cả 2 nhánh true và chỉ giữ nhánh false, dùng logic format thống nhất.

### Acceptance Criteria — Task 3
- [ ] `grep -r showSeconds android/` → 0 kết quả.
- [ ] Widget / Floating Bar / Notification không bao giờ hiện giây.
- [ ] Không còn double seconds (`08:35:42:42`).
- [ ] Config `timeFormat = "HH:mm"` hoặc `"hh:mm a"` hiển thị đúng trên cả 3 surface.

---

## TASK 4 — TẠM ẨN IAP UI (Remove Ads & Unlock All)

**File:** `lib/screens/settings_screen.dart` — đã xác nhận UI vẫn hiển thị đầy đủ (title `'Remove Ads & Unlock All'`, nút mua, `'Restore Purchase'`).

**Yêu cầu:**
```dart
static const bool kShowPremiumUi = false;
```
Bọc toàn bộ Premium Card (bao gồm cả nút "Restore Purchase") bằng `if (kShowPremiumUi) ...`.

Giữ nguyên `IapService`, `buy()`, `restore()`, `isPremium` trong source — không xóa code.

**Bổ sung phòng ngừa (không phải bug đang có, nhưng nên làm khi đang test AdMob):** `IapService.isPremium` hiện đọc trực tiếp `_storage.loadConfig().isPremium` — mặc định `false` theo `ClockConfig.defaults()`, không có nguy cơ hiện tại. Tuy nhiên trong giai đoạn test AdMob/test Play Billing, nếu vô tình trigger `_markPremium()` (qua sandbox purchase/restore test), user sẽ được set `isPremium = true` vĩnh viễn trong SharedPreferences local dù UI đã ẩn. Khuyến nghị: thêm 1 dòng log rõ ràng trong `_markPremium()` để dễ phát hiện nếu việc này xảy ra ngoài ý muốn trong lúc QA.

### Acceptance Criteria — Task 4
- [ ] Settings không còn thấy "Remove Ads & Unlock All" / nút Buy / Restore Purchase.
- [ ] Vẫn còn About + version + Banner (khi không premium).
- [ ] `IapService` vẫn compile, sẵn sàng bật lại bằng cách đổi `kShowPremiumUi = true`.
- [ ] Flow Rewarded Ads + Daily Limit hoạt động bình thường với user free.

---

## TASK 5 — `.draft/features.md` làm baseline cho AI nghiên cứu retention

`features1.md` (bản bạn đính kèm, do 1 AI review tổng hợp lại) là **bản đầy đủ và chính xác nhất hiện có** — nên dùng bản này (đổi tên thành `.draft/features.md` chính thức), không dùng bản gốc `features.md` (baseline thuần, thiếu phần Known Issues + Research Brief chi tiết).

**Bổ sung bắt buộc vào mục "4. Critical Known Issues" của `features1.md` trước khi giao cho AI nghiên cứu tiếp** — thêm Bug C vừa phát hiện, vì nó ảnh hưởng trực tiếp tới đúng thứ mà Research Brief đang nhắm tới (Interactive Utility Modules hiển thị trên Notification/Floating Bar sẽ kế thừa y hệt bug này nếu không fix gốc trước):

```markdown
3. **Notification Icon không cập nhật khi chọn Preset (Lỗi đồng bộ dữ liệu)**
   - **Vấn đề:** `PresetsScreen` không bao giờ gọi `storage.saveConfig()`.
     `HomeScreen._openPresets()` cũng thiếu bước này. Vì vậy
     `NotificationService.update()` (đọc lại `storage.loadConfig()`) luôn
     nhận config CŨ, dù Widget và Floating Bar đã nhận config mới đúng qua
     tham số configJson truyền trực tiếp. Bug này ảnh hưởng CẢ preset free
     lẫn preset đã unlock qua reward ad.
   - **Fix:** `HomeScreen._openPresets()` phải gọi
     `await widget.storage.saveConfig(updated)` NGAY TRƯỚC khi gọi
     `_notifService.update()`. Xem chi tiết Task 2 trong plan4_final.md.
```

Giữ nguyên toàn bộ phần "5. STRATEGIC RESEARCH BRIEF" trong `features1.md` — nội dung phản biện "nghịch lý widget hoàn hảo → user không mở app", định hướng Interactive Utility Modules (Pin/Network/RAM), Quick Actions, Auto-Theme, và ràng buộc kỹ thuật (không đặt ads lên Overlay/Widget, offline-first, không loop 1 giây) đều đã được 4 bản review đồng thuận và tôi xác nhận không có gì cần phản biện thêm — đây là brief đã đủ chín để giao cho AI khác nghiên cứu.

### Acceptance Criteria — Task 5
- [ ] `.draft/features.md` là bản `features1.md` đã cập nhật, có thêm mục Bug C ở phần Known Issues.
- [ ] Research Brief giữ nguyên định hướng Interactive Utility Modules, không bị pha loãng bởi chi tiết kỹ thuật P0.

---

## QUY TẮC CHUNG CHO AGENT

- Không thêm feature mới (không Module Pin, không Quick Actions, không theme mới…) trong 5 task này.
- Không đổi product name / Store positioning.
- Không đặt ads lên Notification / Widget / Floating Bar.
- Thứ tự bắt buộc: Task 1 → Task 2 → Task 3 → Task 4 → Task 5.
- Sau khi hoàn thành, chạy lại toàn bộ `flutter test` và báo cáo kết quả (bao nhiêu pass/fail, liệt kê file nào).
- Kiểm tra thủ công tối thiểu 4 case sau khi xong:
  1. Locked preset + còn 2 lượt → phải hiện ad, xem xong mới đổi clock trên cả 3 surface.
  2. Chọn preset FREE → Notification đổi ngay, không cần thoát/mở lại app.
  3. Cùng preset lần 2 trong ngày → apply ngay, không hiện ad.
  4. Native (Widget/FloatingBar/Notification) không còn hiện giây ở bất kỳ đâu.
- Nếu phát hiện conflict không có trong plan này, ưu tiên giải pháp đơn giản, ổn định, ít phá kiến trúc, và báo lại trước khi tự ý mở rộng phạm vi.
