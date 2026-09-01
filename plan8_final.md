# Plan8 Final — Background P0 Fix (Verified, Self-Audited)

> Nguồn: `plan8.md` + `plan8_review1-5.md` + `checklist.md` + forensic đọc trực tiếp
> source thật tại `/Users/hoang/htdocs_apps/CustomizableStatusBarWidget/source/date_time_widget/`
> (ngày hiện tại). **Xác nhận: cả 5 vấn đề P0 mà review1-5 đã chỉ ra VẪN CÒN NGUYÊN
> trong code, agent chưa áp dụng bất kỳ thay đổi nào** — code hiện tại khớp
> từng dòng, từng comment với những gì review4 đã trích dẫn.

---

## 0. Vì sao vòng này khác các vòng trước

Ở `plan1→plan5`, mỗi vòng Correction Prompt đều dẫn tới tiến bộ thật (verify được bằng code). Ở vòng `plan8` này, agent **báo là đã code xong nhưng thực tế không có thay đổi nào** so với round trước — 5 review độc lập (review1-5) đều đọc cùng 1 bộ lỗi y hệt nhau, và bản forensic hiện tại xác nhận code vẫn giữ nguyên các đoạn bug đã bị review4 trích dẫn từng dòng.

**Do đó, khác với các bản Correction Prompt trước, prompt này bắt buộc agent phải tự trích dẫn lại đúng đoạn code sau khi sửa (self-verification) trước khi báo "done"** — không chấp nhận báo cáo bằng lời mà không kèm bằng chứng dòng code.

---

## 1. Xác nhận 5 vấn đề P0 (đã verify lại bằng forensic đọc source, ngày hiện tại)

| # | Vấn đề | File | Bằng chứng verify lại |
| --- | --- | --- | --- |
| 1 | URI chỉ grant cho `com.android.systemui`, không phải launcher thật | `DateTimeWidgetProvider.kt` → `applyWidgetBackground()` | `context.grantUriPermission("com.android.systemui", uri, ...)` + `views.setImageViewUri(...)` — còn nguyên |
| 2 | Resize 1 widget xóa background của TOÀN BỘ widget (path global) | `DateTimeWidgetProvider.kt` → `onAppWidgetOptionsChanged()` | `prefs.edit().remove(BG_PATH_KEY).apply()` — còn nguyên, kèm nguyên comment "clear cached bitmap so Flutter can re-bake" |
| 3 | Overlay `#59000000` hard-code, phủ lên MỌI loại background (kể cả Solid trắng) | `widget_2x1/3x1/4x1/4x2.xml` | Đã đọc lại `widget_4x2.xml` — `android:background="#59000000"` còn nguyên trên `LinearLayout` |
| 4 | Bake ảnh cố định 480×480, không theo kích thước widget thực tế | `editor_screen.dart`, `home_screen.dart` | `width: 480, height: 480` còn nguyên ở cả 2 nơi gọi `ImageUtils.bakeBackgroundBitmap` |
| 5 | Save không có loading; lỗi bake/bridge bị nuốt im lặng | `editor_screen.dart` → `_save()`, `_bakeAndSetWidgetBackground()` | Không có `_isSaving` hay bất kỳ loading state nào cho `_save()`; `catch (_) { // Best-effort — don't crash the save flow }` còn nguyên |

**Không cần phân tích lại root cause** — 5 review trước đã đúng và đồng thuận. Vấn đề duy nhất của vòng này là **thực thi**, không phải **thiết kế giải pháp**.

---

## 2. Correction Prompt — 5 Task atomic, kèm self-verification bắt buộc

> Đưa từng Task một, KHÔNG gộp. Sau mỗi Task, agent phải dán lại đúng đoạn code đã sửa (không phải mô tả bằng lời) trước khi được coi là hoàn thành Task đó.

### TASK 1 — Native: vẽ background bằng Bitmap, bỏ URI/systemui

```
Sửa file:
android/app/src/main/kotlin/com/example/date_time_widget/DateTimeWidgetProvider.kt
Hàm: applyWidgetBackground(...)

XÓA hoàn toàn:
- FileProvider.getUriForFile(...)
- context.grantUriPermission("com.android.systemui", ...)
- views.setImageViewUri(...)

THAY BẰNG:
1. Đọc path từ SharedPreferences (BG_PATH_KEY) như hiện tại.
2. Nếu path null hoặc File(path).exists() == false → 
   views.setViewVisibility(R.id.widget_background, View.GONE), return.
3. Nếu file tồn tại:
   - BitmapFactory.decodeFile(path) với inSampleSize hợp lý (tránh OOM
     nếu file gốc lớn hơn dự kiến)
   - Nếu bitmap decode được có cạnh lớn hơn 800px, scale xuống còn tối đa
     800px cạnh dài, giữ tỉ lệ, dùng Bitmap.createScaledBitmap
   - views.setImageViewBitmap(R.id.widget_background, bitmap)
   - views.setViewVisibility(R.id.widget_background, View.VISIBLE)
4. Bọc toàn bộ bước 3 trong try/catch: fail → GONE ImageView + Log.e,
   không throw ra ngoài renderWidget().

SAU KHI SỬA: dán lại toàn bộ hàm applyWidgetBackground() mới (không tóm
tắt, dán nguyên hàm) để tôi xác nhận không còn "com.android.systemui"
hay "setImageViewUri" ở đâu trong file này.
```

**Acceptance Task 1 (agent tự check trước khi báo xong):**
- [ ] Grep `grep -n "systemui\|setImageViewUri" DateTimeWidgetProvider.kt` trả về KHÔNG có kết quả nào
- [ ] Grep `grep -n "setImageViewBitmap" DateTimeWidgetProvider.kt` trả về ít nhất 1 kết quả
- [ ] Đã dán nguyên hàm `applyWidgetBackground()` mới trong câu trả lời

---

### TASK 2 — Resize KHÔNG xóa background global

```
Sửa file: DateTimeWidgetProvider.kt
Hàm: onAppWidgetOptionsChanged(...)

XÓA dòng:
prefs.edit().remove(BG_PATH_KEY).apply()

Giữ lại CHỈ:
renderWidget(context, appWidgetManager, widgetId)

Không thêm logic per-widgetId storage trong task này — MVP giữ
background GLOBAL (mọi widget cùng 1 file path), chỉ sửa để KHÔNG xóa
path khi resize.

SAU KHI SỬA: dán lại toàn bộ hàm onAppWidgetOptionsChanged() mới.
```

**Acceptance Task 2:**
- [ ] Grep `grep -n "remove(BG_PATH_KEY)" DateTimeWidgetProvider.kt` — dòng này CHỈ còn xuất hiện trong `saveWidgetBackground()` (khi Flutter chủ động set null để xóa), KHÔNG còn trong `onAppWidgetOptionsChanged()`
- [ ] Đã dán nguyên hàm `onAppWidgetOptionsChanged()` mới trong câu trả lời

---

### TASK 3 — Bỏ overlay cứng trên XML

```
Sửa 4 file:
android/app/src/main/res/layout/widget_2x1.xml
android/app/src/main/res/layout/widget_3x1.xml
android/app/src/main/res/layout/widget_4x1.xml
android/app/src/main/res/layout/widget_4x2.xml

Trong mỗi file, XÓA thuộc tính:
android:background="#59000000"
trên LinearLayout chứa 3 TextView (widget_day/date/time).

Thêm text shadow cho dễ đọc trên mọi nền, ví dụ trên mỗi TextView:
android:shadowColor="#80000000"
android:shadowDx="0"
android:shadowDy="1"
android:shadowRadius="3"

Không thêm overlay màu nền mới nào khác thay thế — overlay (nếu user
chọn Dark/Light trong Editor) đã được bake sẵn vào chính file PNG từ
Flutter, không cần overlay riêng ở XML nữa.

SAU KHI SỬA: dán lại nguyên nội dung widget_4x2.xml (đại diện, vì cả 4
file sửa giống nhau).
```

**Acceptance Task 3:**
- [ ] Grep `grep -rn "#59000000" android/app/src/main/res/layout/` trả về KHÔNG có kết quả nào
- [ ] Grep `grep -n "shadowColor" android/app/src/main/res/layout/widget_4x2.xml` trả về ít nhất 1 kết quả
- [ ] Đã dán nguyên `widget_4x2.xml` mới trong câu trả lời

---

### TASK 4 — Save: loading + lỗi phải báo user

```
Sửa file: lib/screens/editor_screen.dart

A) Thêm loading cho toàn bộ _save():
   - Thêm field: bool _isSaving = false;
   - Trong _save(): setState(() => _isSaving = true) ngay đầu hàm,
     setState(() => _isSaving = false) trong finally.
   - Disable nút "Save" trong AppBar khi _isSaving == true (onPressed:
     _isSaving ? null : _save).
   - Hiện CircularProgressIndicator nhỏ thay chữ "Save" khi đang chạy,
     hoặc overlay toàn màn hình như đã làm cho _isProcessingImage —
     chọn 1 trong 2, nhất quán với UX đã có ở _pickImage().

B) Sửa _bakeAndSetWidgetBackground(): 
   XÓA:
   } catch (_) {
     // Best-effort — don't crash the save flow
   }
   
   THAY BẰNG:
   } catch (e, st) {
     debugPrint('bakeAndSetWidgetBackground failed: $e\n$st');
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Could not update widget background')),
       );
     }
   }

Không được để _save() throw ra ngoài hay crash — chỉ cần user THẤY
được lỗi qua SnackBar, config chính (không phải background) vẫn lưu
được bình thường.

SAU KHI SỬA: dán lại nguyên hàm _save() và _bakeAndSetWidgetBackground() mới.
```

**Acceptance Task 4:**
- [ ] Grep `grep -n "_isSaving" lib/screens/editor_screen.dart` trả về ít nhất 3 kết quả (khai báo + set true + set false)
- [ ] Grep `grep -n "catch (_) {}" lib/screens/editor_screen.dart` hoặc `catch (_) {$` không còn khớp với block trong `_bakeAndSetWidgetBackground()`
- [ ] Đã dán nguyên 2 hàm mới trong câu trả lời

---

### TASK 5 — Smoke test bắt buộc, báo PASS/FAIL từng dòng

```
Sau khi hoàn thành Task 1-4, chạy build thật (không chỉ đọc code) và
test các kịch bản sau trên device/emulator, báo PASS/FAIL từng dòng —
KHÔNG được báo "hoàn thành" nếu chưa thực sự chạy build và test:

1. [ ] Solid màu đỏ → Preview đỏ → Save → Widget hiện đỏ (không xám/đen)
2. [ ] Gradient → Widget có gradient giống preview
3. [ ] Image → Widget có ảnh giống preview (không bị phủ đen 35%)
4. [ ] Resize 1 widget (kéo giãn) → nền của widget đó VÀ các widget
       khác đang có trên màn hình đều KHÔNG mất
5. [ ] Kill app hoàn toàn rồi mở lại → widget vẫn giữ nền
6. [ ] Reboot máy (hoặc emulator) → widget vẫn giữ nền sau khi máy khởi
       động lại
7. [ ] Status bar notification vẫn hoạt động bình thường (không bị ảnh
       hưởng bởi thay đổi ở Task 1-4)
8. [ ] Floating Bar vẫn bật/tắt/update bình thường
9. [ ] Presets / Rewarded ad flow không crash sau khi áp dụng background
10. [ ] Bấm Save với ảnh nặng (>5MB) → thấy loading, không bị đứng UI,
        không crash

Nếu bất kỳ dòng nào FAIL, dừng lại, KHÔNG báo "done", báo rõ dòng nào
fail và tại sao.
```

---

## 3. Checklist đối chiếu cuối cùng (chỉ coi PASS khi có bằng chứng dòng code + test thật)

| Checklist.md | Điều kiện PASS |
| --- | --- |
| Mọi process ngầm có loading | Task 4A xong + test #10 PASS |
| Chọn background image có loading | Đã PASS từ vòng trước, không đổi |
| Pro qua ads, chỉ dùng trong ngày | Không đụng tới trong vòng này — nếu nghi ngờ bị ảnh hưởng, audit riêng bằng `reward_service_test.dart` |
| App không giật, process nặng → background | Cần thêm `compute()` cho `ImageUtils.bakeBackgroundBitmap` nếu ảnh lớn gây jank ở test #10 — đánh giá sau khi có kết quả test thật, chưa bắt buộc trong 5 Task này nếu test #10 PASS |
| Lỗi → toast | Task 4B xong |
| Widget = preview | Task 1 + 2 + 3 xong + test #1-3 PASS |
| Flutter ↔ native hoàn thiện | Tất cả Task 1-5 xong + toàn bộ test Task 5 PASS |

---

## 4. Quy tắc bắt buộc cho vòng này (khác các vòng trước)

1. **Không nhận báo cáo "đã sửa xong" nếu không kèm code đã dán** — mỗi Task yêu cầu agent dán nguyên hàm/file đã sửa, không tóm tắt bằng lời.
2. **Không nhận Task 5 "PASS" nếu không có bằng chứng đã thực sự build và chạy** — không phải suy luận từ đọc code.
3. Làm đúng thứ tự Task 1 → 2 → 3 → 4 → 5, dừng lại sau mỗi Task để review trước khi sang Task tiếp theo.
4. Không thêm feature mới (Auto Day/Night, Share, My Designs mở rộng...) trong vòng sửa lỗi này.
5. Nếu ở bất kỳ Task nào agent báo "không tìm thấy đoạn code cần sửa" hoặc "đã thử nhưng không chắc đã áp dụng" — dừng lại ngay, báo rõ, không tự chuyển sang Task tiếp theo.

---

## 5. Việc cần làm sau khi cả 5 Task PASS thật

- Test bổ sung trên 2 launcher khác nhau (ví dụ Pixel Launcher + Nova Launcher hoặc Samsung One UI Home) để xác nhận Task 1 (Bitmap) hoạt động độc lập với launcher, không còn phụ thuộc grant permission như cách cũ.
- Nếu test #10 (ảnh nặng) cho thấy UI giật, quay lại làm P1 đã nêu ở review1-5: chuyển `bakeBackgroundBitmap` sang chạy qua `compute()`.
- Sau khi Definition of Done đạt (mục 3 toàn bộ PASS), mới quay lại roadmap Personalization V1.1 (Auto Day/Night, Quick Actions) theo `plan5_final.md`.