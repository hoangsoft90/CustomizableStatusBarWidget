# plan7_final.md — Correction Prompt cho AI Coding Agent (Background Feature, vòng 2)

Tổng hợp từ `plan7.md` + `plan7_review1..4.md` + `checklist.md`, đã **verify trực tiếp với source code thực tế** tại:
`/Users/hoang/htdocs_apps/CustomizableStatusBarWidget/source/date_time_widget/`

## Xác nhận trạng thái thật (đọc trực tiếp source, không suy đoán)

**Tin tốt:** Từ vòng `plan6_final.md` trước, phần Bug A (preview trong app thiếu `background:` param) **đã được fix đúng** — verify tại `home_screen.dart:310`: `ClockPreview(config: _config, background: _background)`. Preview trong app (cả Editor lẫn Home) hiện đã hoạt động đúng, khớp với báo cáo của bạn.

**Tin xấu:** Phần Bug B (native widget hoàn toàn chưa nhận/render background) từ `plan6_final.md` **chưa được đụng vào một dòng nào**. Đã verify lại từng file:
- `MainActivity.kt` — `getActiveWidgetIds` và `setWidgetBackground` **vẫn không tồn tại** trong `WIDGET_CHANNEL` handler (chỉ có `updateWidgets`, `requestWidgetPick`).
- `DateTimeWidgetProvider.kt` — `renderWidget()` **vẫn** chỉ gọi `setTextViewText/setTextColor/setTextViewTextSize`, không có `setImageViewUri`/`setImageViewBitmap` nào. `data class ClockData` vẫn không có field background.
- Cả 4 file `widget_2x1/3x1/4x1/4x2.xml` **vẫn** `android:background="#CC000000"` hard-code, không có `ImageView`.

**→ `plan7.md` và cả 4 bản review đều đúng 100% với code hiện tại — không có gì cần phản biện về phần chẩn đoán.** Đây thực chất là **cùng một Bug B** từ `plan6_final.md`, chỉ là chưa ai làm. Bản plan này sẽ không lặp lại việc chẩn đoán, mà tập trung vào bản sửa cuối cùng, gộp thêm 2 phát hiện mới của tôi (xem mục "Bổ sung của tôi" ở Task 2 và Task 3).

STOP FEATURE DEVELOPMENT. Không thêm tính năng mới. Làm tuần tự Task 1 → 2 → 3, pass acceptance criteria từng phần rồi mới đối chiếu `checklist.md` ở cuối.

---

## TASK 1 — LOADING KHI CHỌN BACKGROUND IMAGE (Flutter, nhanh, làm trước)

### Xác nhận

`lib/screens/editor_screen.dart._pickImage()` (dòng ~247-290) **hoàn toàn không có state loading**:
```dart
Future<void> _pickImage() async {
  final picked = await _picker.pickImage(...);
  if (picked == null) return;

  final bytes = await File(picked.path).readAsBytes();   // ← có thể chậm với ảnh lớn, không loading
  ...
  await ImageUtils.copyAndResizeSource(imageBytes: bytes, destinationPath: sourcePath);
  ...
  final cropResult = await Navigator.of(context).push<CropResult>(...);
  ...
}
```

### Fix

**File:** `lib/screens/editor_screen.dart`

1. Thêm state:
```dart
bool _isProcessingImage = false;
```

2. Bọc toàn bộ phần xử lý (SAU khi user đã chọn ảnh từ gallery, KHÔNG bọc lúc mở gallery):
```dart
Future<void> _pickImage() async {
  final picked = await _picker.pickImage(
    source: ImageSource.gallery,
    maxWidth: 2400,
    maxHeight: 2400,
  );
  if (picked == null) return;

  setState(() => _isProcessingImage = true);
  try {
    final bytes = await File(picked.path).readAsBytes();

    final appDir = await getApplicationDocumentsDirectory();
    final designsDir = Directory('${appDir.path}/designs');
    if (!await designsDir.exists()) {
      await designsDir.create(recursive: true);
    }
    final designId = const Uuid().v4();
    final sourcePath = '${designsDir.path}/$designId.jpg';
    await ImageUtils.copyAndResizeSource(
      imageBytes: bytes,
      destinationPath: sourcePath,
    );

    if (!mounted) return;
    final cropResult = await Navigator.of(context).push<CropResult>(
      MaterialPageRoute(builder: (_) => CropScreen(imageFile: File(sourcePath))),
    );

    if (cropResult == null) return;

    setState(() {
      _background = BackgroundConfig(
        type: BackgroundType.image,
        imagePath: sourcePath,
        cropScale: cropResult.scale,
        cropOffsetX: cropResult.offsetX,
        cropOffsetY: cropResult.offsetY,
        blurSigma: 0.0,
        overlayOpacity: 0.35,
      );
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not process image. Please try another one.')),
      );
    }
  } finally {
    if (mounted) setState(() => _isProcessingImage = false);
  }
}
```

3. UI: hiện `CircularProgressIndicator` + text `"Preparing image…"` khi `_isProcessingImage == true` (overlay nhỏ trên vùng Background selector là đủ, không cần full-screen block). Disable nút "Image" trong lúc xử lý để tránh double-tap mở 2 lần Gallery/Crop.

4. **Rủi ro OOM (đồng thuận cả review1 lẫn review2):** `readAsBytes()` đọc ảnh 10-20MB vào RAM có thể khiến OS kill app. Khối `try/catch/finally` ở trên đã đảm bảo nếu crash do lỗi đọc file/OOM sẽ được bắt và tắt loading đúng cách thay vì treo vô hạn. Không bắt buộc phải đổi hẳn sang xử lý theo path/stream ở vòng này (đó là tối ưu P1, không phải root cause của vấn đề loading) — nhưng nếu agent có thời gian, ưu tiên dùng `ImageUtils` đọc trực tiếp từ `File` path thay vì load hết bytes vào bộ nhớ trước.

### Acceptance Criteria — Task 1
- [ ] Chọn ảnh lớn → thấy loading ngay, không có khoảng "im lặng" trước khi Crop hiện ra.
- [ ] Lỗi xử lý ảnh (file hỏng, hết bộ nhớ) → SnackBar báo lỗi, loading tắt, không crash.
- [ ] Bấm nút Image 1 lần không mở Crop 2 lần do double-tap.
- [ ] Loading chỉ bật SAU khi chọn ảnh xong (không bật lúc mở Gallery).

---

## TASK 2 — NATIVE METHODCHANNEL: `getActiveWidgetIds` + `setWidgetBackground`

**File:** `android/app/src/main/kotlin/com/example/date_time_widget/MainActivity.kt`

Thêm 2 case trong `WIDGET_CHANNEL` handler, trước dòng `else -> result.notImplemented()`:

```kotlin
"getActiveWidgetIds" -> {
    val mgr = AppWidgetManager.getInstance(this)
    val ids = mgr.getAppWidgetIds(ComponentName(this, DateTimeWidgetProvider::class.java))
    result.success(ids.toList())
}
"setWidgetBackground" -> {
    val bitmapPath = call.argument<String?>("bitmapPath")
    DateTimeWidgetProvider.setBackground(this, bitmapPath)
    result.success(true)
}
```

Cần thêm import `android.appwidget.AppWidgetManager` và `android.content.ComponentName` ở đầu file (chưa có sẵn trong `MainActivity.kt` hiện tại).

**Lưu ý MVP (khớp đúng thiết kế hiện tại của Flutter — 2 file `editor_screen.dart` và `home_screen.dart` đều đang push CÙNG 1 file bitmap cho MỌI widgetId):** dùng **1 path chung** lưu trong `SharedPreferences`, không cần map theo từng `widgetId` riêng. Vì vậy `setWidgetBackground` ở trên **không cần** tham số `widgetId` — dù Flutter vẫn gửi kèm `widgetId` trong payload (do vòng lặp `for (final widgetId in widgetIds)` ở Flutter), native chỉ cần lấy `bitmapPath` và ghi đè path chung, gọi update lại toàn bộ widget instance.

### Bổ sung của tôi #1 — KHÔNG CÓ trong plan7.md/4 review: `DateTimeWidgetProvider` cần thêm hàm `setBackground()` mới, đặt trong `companion object`

```kotlin
private const val BG_PREFS = "widget_background"
private const val BG_PATH_KEY = "bg_bitmap_path"

fun setBackground(context: Context, bitmapPath: String?) {
    context.getSharedPreferences(BG_PREFS, Context.MODE_PRIVATE)
        .edit().putString(BG_PATH_KEY, bitmapPath).apply()
    updateAllWidgets(context)
}

private fun readBackgroundPath(context: Context): String? {
    return context.getSharedPreferences(BG_PREFS, Context.MODE_PRIVATE)
        .getString(BG_PATH_KEY, null)
}
```

### Acceptance Criteria — Task 2
- [ ] `WidgetBridge.getActiveWidgetIds()` (Dart) trả về danh sách ID thật (không còn `[]` do `notImplemented`).
- [ ] `WidgetBridge.setWidgetBackground()` không còn ném `PlatformException`.
- [ ] Path được ghi vào `SharedPreferences` key `widget_background`.

---

## TASK 3 — RENDER BACKGROUND TRÊN WIDGET (Layout + Provider + FileProvider + Cache-busting)

### 3.1 Layout XML — cả 4 file: `widget_2x1.xml`, `widget_3x1.xml`, `widget_4x1.xml`, `widget_4x2.xml`

Đổi từ `LinearLayout` phẳng có `android:background="#CC000000"` sang `FrameLayout` bọc ngoài:

```xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ImageView
        android:id="@+id/widget_background"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="centerCrop"
        android:contentDescription="@null" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical"
        android:gravity="center"
        android:padding="6dp"
        android:background="#59000000">
        <!-- overlay tối nhẹ mặc định để chữ luôn đọc được, KHÔNG phải nền chính -->

        <!-- giữ nguyên các TextView id cũ: widget_day, widget_date, widget_time -->
    </LinearLayout>
</FrameLayout>
```

Giữ nguyên toàn bộ id các `TextView` hiện có để không phải sửa phần set text trong `renderWidget()`.

### 3.2 `DateTimeWidgetProvider.kt` — render trong `renderWidget()`, thêm sau phần set text/color/size:

```kotlin
val bgPath = readBackgroundPath(context)
if (bgPath != null && File(bgPath).exists()) {
    val uri = FileProvider.getUriForFile(
        context, "${context.packageName}.fileprovider", File(bgPath)
    )
    views.setImageViewUri(R.id.widget_background, uri)
    views.setViewVisibility(R.id.widget_background, android.view.View.VISIBLE)
} else {
    views.setViewVisibility(R.id.widget_background, android.view.View.GONE)
}
```

**Bắt buộc dùng `setImageViewUri`, KHÔNG dùng `setImageViewBitmap`** — đồng thuận cả review1/review2/review3: `RemoteViews` truyền qua Binder IPC giới hạn ~1MB tổng transaction; bitmap ARGB_8888 480×480 giải nén ra RAM đã chiếm ~921KB, cộng dồn cho 4 widget instance dễ vượt ngưỡng → `TransactionTooLargeException`. `setImageViewUri` để Launcher tự đọc file qua URI, không đóng gói bitmap vào Binder transaction.

Thêm import: `androidx.core.content.FileProvider`, `java.io.File`.

### 3.3 `AndroidManifest.xml` — khai báo FileProvider (hiện chưa có, đã verify)

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

### 3.4 `res/xml/file_paths.xml` — tạo mới

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <files-path name="widget_bg" path="widget_bg/" />
</paths>
```
Đường dẫn `files-path` phải khớp chính xác nơi Flutter đang ghi file thật: `${ApplicationDocumentsDirectory}/widget_bg/...` (xác nhận đúng path này ở cả `editor_screen.dart` và `home_screen.dart`).

### 3.5 Cache-Busting — đồng thuận cả 4 review, đây là điểm quan trọng hay bị quên

**Vấn đề:** Cả `editor_screen.dart` (dòng ~155 vùng `_bakeAndSetWidgetBackground`) và `home_screen.dart` (dòng ~155) đều đang ghi đè lên **cùng 1 tên file cố định**: `current_bg.png`. Khi user đổi ảnh nền, file bị overwrite nhưng URI truyền cho `AppWidgetManager`/Launcher **không đổi** → hệ thống có thể lấy ảnh từ cache thay vì đọc file mới, khiến ảnh không cập nhật dù đã "set" đúng.

**Fix (áp dụng ở CẢ HAI file, xem Bổ sung #2 bên dưới để biết vì sao bắt buộc sửa cả 2):**
```dart
final bgFile = File('${bgDir.path}/bg_${DateTime.now().millisecondsSinceEpoch}.png');
await bgFile.writeAsBytes(bitmapBytes);

// Cleanup file cũ (best-effort, không throw nếu lỗi)
try {
  final oldFiles = bgDir.listSync().whereType<File>()
      .where((f) => f.path.endsWith('.png') && f.path != bgFile.path);
  for (final f in oldFiles) { await f.delete(); }
} catch (_) {}
```

### Bổ sung của tôi #2 — KHÔNG CÓ trong plan7.md/4 review: bake logic bị lặp lại y hệt ở 2 file, phải sửa CẢ HAI, không chỉ 1

Đã verify: `_bakeAndSetWidgetBackground()` tồn tại **độc lập, gần như copy-paste giống hệt nhau** ở cả:
- `lib/screens/editor_screen.dart` (dòng ~168-215, dùng khi Save trong Editor chính)
- `lib/screens/home_screen.dart` (dòng ~126-165, dùng khi áp dụng 1 design từ "My Designs")

Cả 2 nơi đều dùng `width: 480, height: 480` và tên file `current_bg.png`. **Nếu agent chỉ sửa 1 trong 2 file (rất dễ xảy ra vì Task 3.5 chỉ nói "editor_screen.dart" theo thói quen), flow "My Designs" sẽ vẫn dính bug cache/kích thước cứng dù flow Editor chính đã hết bug.** Bắt buộc áp dụng cùng 1 fix (đổi tên file có timestamp + cleanup) ở **cả 2 nơi**. Khuyến nghị agent, nếu có thời gian, refactor 2 hàm này thành 1 hàm dùng chung trong `lib/utils/image_utils.dart` hoặc 1 service riêng để tránh việc sửa lệch nhau lần sau — nhưng đây là optional refactor, không bắt buộc để pass checklist.

### 3.6 Bake size — P1, không chặn release

Vẫn giữ `480×480` cho vòng này (đã verify: `scaleType="centerCrop"` ở layout mới sẽ tự crop theo tỷ lệ khung chứa, không bị stretch méo — chỉ mất một phần ảnh ở cạnh dài với các widget dẹt như 4x1). Bake theo kích thước động là tối ưu, xếp sau khi pipeline cơ bản đã chạy đúng.

### Acceptance Criteria — Task 3
- [ ] Solid color save → Home Widget đổi màu nền thật (không chỉ preview trong app).
- [ ] Gradient save → Home Widget hiện gradient.
- [ ] Image save (từ cả Editor lẫn "My Designs") → Home Widget hiện ảnh, không méo, chữ đọc được.
- [ ] Đổi ảnh 2 lần liên tiếp → widget hiện đúng ảnh MỚI NHẤT, không kẹt cache ảnh cũ.
- [ ] Không có `TransactionTooLargeException` trong logcat khi apply ảnh.
- [ ] Reboot máy → widget vẫn giữ đúng background (đọc lại `SharedPreferences` mỗi lần `renderWidget()`).
- [ ] Xóa background (None) → `ImageView` set `GONE`, chỉ còn overlay mặc định.
- [ ] Thêm widget mới → nhận đúng background hiện tại ngay từ lần render đầu.
- [ ] Cả `editor_screen.dart` VÀ `home_screen.dart` đều dùng tên file có timestamp — không chỉ 1 trong 2.

---

## ĐỐI CHIẾU `checklist.md` SAU KHI HOÀN THÀNH TASK 1-3

| Yêu cầu trong `checklist.md` | Sau khi hoàn thành plan này |
| --- | --- |
| Mọi thao tác mượt, process ngầm có loading | ✅ Task 1 |
| Chọn background image có loading | ✅ Task 1 |
| Pro qua ads, chỉ dùng trong ngày, hôm sau phải xem ads lại | 🟡 Đã có từ `plan4_final.md` (Daily Reward Entitlement) — **không thuộc phạm vi plan này**, nếu muốn QA lại cần chạy riêng theo `ACCEPTANCE_P0.md`/`plan4_final.md`, không lặp lại ở đây. |
| App không giật, process nặng chạy nền | 🟡 Task 1 giảm rủi ro treo UI khi chọn ảnh; không có process nặng nào khác trong phạm vi Background feature cần đưa ra background thread ở vòng này. |
| Lỗi phải báo qua toast | ✅ Task 1 (SnackBar khi xử lý ảnh lỗi) |
| Widget phải hiển thị đúng như preview | ✅ Task 2 + Task 3 |

**Lưu ý:** Dòng "Pro qua ads / daily entitlement" trong `checklist.md` là một checklist chung cho toàn app, không phải riêng cho Background feature — plan này chỉ xử lý đúng phạm vi Background + Loading theo đúng 2 vấn đề bạn báo cáo. Không mở rộng sang QA lại toàn bộ hệ thống reward ads ở đây.

---

## QUY TẮC CHUNG CHO AGENT

- Không thêm tính năng mới ngoài Task 1/2/3.
- Không hard-code lại `#CC000000` làm nền chính trên root layout.
- Không dùng `setImageViewBitmap` với bitmap full-size qua Binder.
- Không bake lại ảnh mỗi `ACTION_TIME_TICK` — chỉ bake lúc Save/Apply.
- **Bắt buộc sửa cả `editor_screen.dart` VÀ `home_screen.dart`** cho phần cache-busting (Task 3.5) — đây là lỗi dễ bị bỏ sót nhất trong toàn bộ plan này.
- Thứ tự: Task 1 (nhanh) → Task 2 → Task 3.
- Task 2/3 là native Kotlin, **không unit-test được** — bắt buộc build APK thật và cài lên thiết bị/emulator để verify bằng mắt, không được chỉ báo "đã sửa xong" dựa trên việc code biên dịch được.
- Kiểm tra thủ công tối thiểu sau khi xong:
  1. Chọn ảnh lớn (>5MB) → có loading, không đứng hình.
  2. Đổi Solid/Gradient/Image trong Editor → Save → Home Widget thật đổi theo.
  3. Đổi ảnh 2 lần liên tiếp → widget hiện đúng ảnh thứ 2, không phải ảnh cũ.
  4. Tạo 1 design mới qua "My Designs" (không phải Editor chính) → áp dụng → widget cũng đổi đúng (xác nhận bug cache/480x480 đã hết ở CẢ 2 luồng).
  5. Reboot máy → widget giữ nguyên background.
  6. Kiểm tra logcat không có `TransactionTooLargeException`.
- Nếu phát hiện conflict với code hiện tại không có trong plan này, ưu tiên giải pháp đơn giản, ổn định, ít phá kiến trúc, và báo lại trước khi tự ý mở rộng phạm vi.
