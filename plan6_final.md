# plan6_final.md — Correction Prompt cho AI Coding Agent (Background Feature)

Tổng hợp từ `plan6.md` + `plan6_review1..4.md`, đã **verify trực tiếp với source code thực tế** tại:
`/Users/hoang/htdocs_apps/CustomizableStatusBarWidget/source/date_time_widget/`

**QUAN TRỌNG:** Source code hiện tại đã tiến triển hơn so với những gì `plan6.md` mô tả ban đầu (đã có `WidgetDesign` gộp `ClockConfig` + `BackgroundConfig`, đã có `StorageService.loadBackground()/saveBackground()` riêng, `EditorScreen` đã truyền `background` vào `ClockPreview` đúng). Vì vậy **một phần lớn root cause mà 4 bản review suy đoán (state mismatch phức tạp, object không immutable, thiếu rebuild trigger...) KHÔNG còn đúng với code hiện tại.** Tôi đã tìm ra **nguyên nhân thật, đơn giản hơn nhiều** cho phần "Preview trong app" — xem Bug A bên dưới. Phần "Widget mất background" thì **plan6.md đúng chính xác 100%**, đã verify từng dòng.

STOP FEATURE DEVELOPMENT. Không thêm tính năng mới. Làm tuần tự Bug A → Bug B → Bug C, pass acceptance criteria từng phần.

---

## BUG A — PREVIEW TRONG APP KHÔNG HIỆN BACKGROUND (root cause thật, khác hoàn toàn 4 bản review)

### Root cause đã xác nhận (đọc trực tiếp `home_screen.dart`)

`HomeScreenState` load và cập nhật `_background` **hoàn toàn đúng** ở mọi nơi:
```dart
BackgroundConfig _background = const BackgroundConfig();

@override
void initState() {
  super.initState();
  _config = widget.storage.loadConfig();
  _background = widget.storage.loadBackground();   // ĐÚNG
  ...
}

Future<void> _openEditor() async {
  ...
  setState(() {
    _config = result.config;
    _background = result.background;               // ĐÚNG
  });
  ...
}
```

Nhưng trong `build()`, dòng gọi `ClockPreview` lại **thiếu hẳn tham số `background`**:
```dart
// Live preview
ClockPreview(config: _config),   // ← BUG: thiếu background: _background
```

`ClockPreview` có `background` là optional param mặc định `const BackgroundConfig()` (tức `BackgroundType.none`), nên khi không truyền, preview trên Home Screen **luôn luôn hiển thị như không có background nào được set**, bất kể `_background` trong state đang là gì. Đây chính là điều user báo cáo: "chỉnh background... nhưng preview ko thể hiện background".

**Không phải do:** state không đồng bộ, object không immutable, thiếu rebuild trigger, image path bị mất, color picker đọc sai biến — như 4 bản review đều suy đoán. Đây chỉ là **1 tham số bị quên khi gọi widget**, một lỗi rất đơn giản.

**Lưu ý phân biệt 2 màn hình preview khác nhau:**
- `EditorScreen` — preview **đã đúng**: `ClockPreview(config: _config, background: _background)` (dòng trong `build()` của `editor_screen.dart`). Không cần sửa gì ở đây cho phần truyền tham số.
- `HomeScreen` — preview **sai**, đây là nơi cần sửa.

### Fix

**File:** `lib/screens/home_screen.dart`

```dart
// Live preview
ClockPreview(config: _config, background: _background),
```

### Bug phụ đã xác nhận (đúng như plan6.md/review đều nêu, nhưng chỉ ảnh hưởng UI, KHÔNG phải nguyên nhân chính)

Trong `editor_screen.dart`, `_ColorPicker` cho phần **Background → Solid color** đang dùng sai biến để xác định swatch nào đang "được chọn" (viền/tick hiển thị):
```dart
if (_background.type == BackgroundType.solid) ...[
  ...
  _ColorPicker(
    selected: _parsedColor,   // ← đọc _config.color (màu CHỮ), không phải _background.solidColor
    onChanged: (c) => _updateBackground(
        (b) => b.copyWith(solidColor: _colorToHex(c))),
  ),
],
```
`onChanged` vẫn ghi đúng vào `_background.solidColor`, nên **màu nền vẫn áp dụng đúng khi bấm** — bug này chỉ khiến vòng tròn "đang chọn" trong bảng màu hiển thị sai (highlight theo màu chữ thay vì màu nền), gây rối mắt chứ không phải nguyên nhân khiến preview "mất" background.

**Fix:**
```dart
Color get _parsedBackgroundColor {
  final hex = (_background.solidColor ?? '#1A1A2E').replaceFirst('#', '');
  if (hex.length == 6) return Color(int.parse('FF$hex', radix: 16));
  return const Color(0xFF1A1A2E);
}
```
Và đổi `selected: _parsedColor` → `selected: _parsedBackgroundColor` chỉ tại đúng vị trí Background Solid color picker (không đổi ở Text Colour picker phía dưới — chỗ đó vẫn dùng đúng `_parsedColor`).

### Acceptance Criteria — Bug A
- [ ] `HomeScreen` preview đổi màu/gradient/ảnh ngay khi quay lại từ Editor hoặc My Designs, không cần mở lại app.
- [ ] `EditorScreen` preview vẫn hoạt động đúng như hiện tại (không bị ảnh hưởng bởi thay đổi này).
- [ ] Bảng chọn màu Background → Solid hiển thị đúng swatch đang chọn khớp với màu nền hiện tại, không lẫn với màu chữ.
- [ ] Kill app, mở lại → `HomeScreen` preview vẫn hiển thị đúng background đã lưu (vì `loadBackground()` đã đúng sẵn, chỉ cần Bug A ở trên được fix).

---

## BUG B — HOME WIDGET (NATIVE) MẤT BACKGROUND HOÀN TOÀN

**`plan6.md` đã xác định đúng 100% — đã verify lại từng dòng, không có gì cần phản biện thêm về phần chẩn đoán.** Đây là phần việc lớn nhất, cần làm end-to-end.

### Root cause đã verify

**1. `MainActivity.kt` chưa implement 2 method Flutter đang gọi:**

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WIDGET_CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "updateWidgets" -> { ... }
            "requestWidgetPick" -> { ... }
            else -> result.notImplemented()   // ← setWidgetBackground và getActiveWidgetIds rơi vào đây
        }
    }
```

Hậu quả cụ thể: `WidgetBridge.getActiveWidgetIds()` (Dart) bắt `PlatformException` và trả về `[]`. Trong `editor_screen.dart._bakeAndSetWidgetBackground()`:
```dart
final widgetIds = await WidgetBridge.getActiveWidgetIds();
if (widgetIds.isEmpty) return;   // ← LUÔN đúng vì native chưa trả list thật → toàn bộ bake bị skip âm thầm
```
Cùng bug xảy ra y hệt ở `home_screen.dart._bakeAndSetWidgetBackground()` (dùng trong flow "My Designs").

**2. `DateTimeWidgetProvider.kt` — kể cả nếu (1) được fix, native vẫn không biết render background:**

- `data class ClockData` (cuối file) chỉ có `format, timeFormat, showDate, showDay, fontSize, color, alignment` — không có field background nào.
- `renderWidget()` chỉ gọi `setTextViewText`, `setTextColor`, `setTextViewTextSize` — không có `setImageViewBitmap` hoặc `setImageViewUri` ở đâu cả.
- Widget hoàn toàn không đọc bitmap path mà `setWidgetBackground` (giả sử được implement) sẽ lưu.

**3. Layout XML hard-code nền đen, không có `ImageView`:**

Đã đọc `widget_2x1.xml` — xác nhận:
```xml
<LinearLayout ...
    android:background="#CC000000">
```
Không có `ImageView` nào để làm layer nền ảnh. Cần kiểm tra tương tự cho `widget_3x1.xml`, `widget_4x1.xml`, `widget_4x2.xml` (khả năng cao đều giống pattern này).

### Yêu cầu fix — pipeline hoàn chỉnh

Đồng thuận với cả `plan6.md` và 4 bản review về hướng kiến trúc; dưới đây là bản rút gọn, có thứ tự ưu tiên rõ để agent làm theo, tránh làm dở dang:

**B1. `MainActivity.kt` — thêm 2 case còn thiếu trong `WIDGET_CHANNEL` handler:**
```kotlin
"getActiveWidgetIds" -> {
    val mgr = AppWidgetManager.getInstance(this)
    val ids = mgr.getAppWidgetIds(ComponentName(this, DateTimeWidgetProvider::class.java))
    result.success(ids.toList())
}
"setWidgetBackground" -> {
    val widgetId = call.argument<Int>("widgetId")
    val bitmapPath = call.argument<String?>("bitmapPath")
    if (widgetId != null) {
        DateTimeWidgetProvider.setBackground(this, widgetId, bitmapPath)
    }
    result.success(true)
}
```

**B2. `DateTimeWidgetProvider.kt` — lưu bitmap path theo widgetId, và render trong `renderWidget()`:**

Lưu mapping đơn giản (không cần theo từng widgetId riêng nếu app chỉ hỗ trợ 1 background chung cho mọi instance — đúng như thiết kế hiện tại của `editor_screen.dart`/`home_screen.dart` đang push CÙNG 1 file `current_bg.png` cho MỌI widgetId). Vì vậy cách đơn giản và nhất quán với thiết kế hiện có: lưu **1 path chung** trong `SharedPreferences` (không cần map theo từng ID):

```kotlin
companion object {
    private const val BG_PREFS = "widget_background"
    private const val BG_PATH_KEY = "bg_bitmap_path"

    fun setBackground(context: Context, widgetId: Int, bitmapPath: String?) {
        context.getSharedPreferences(BG_PREFS, Context.MODE_PRIVATE)
            .edit().putString(BG_PATH_KEY, bitmapPath).apply()
        updateAllWidgets(context)
    }

    private fun readBackgroundPath(context: Context): String? {
        return context.getSharedPreferences(BG_PREFS, Context.MODE_PRIVATE)
            .getString(BG_PATH_KEY, null)
    }
}
```

Trong `renderWidget()`, sau khi set text/color, thêm:
```kotlin
val bgPath = readBackgroundPath(context)
if (bgPath != null && File(bgPath).exists()) {
    val uri = FileProvider.getUriForFile(
        context, "${context.packageName}.fileprovider", File(bgPath)
    )
    context.grantUriPermission(
        "com.android.systemui", uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
    )
    views.setImageViewUri(R.id.widget_bg_image, uri)
    views.setViewVisibility(R.id.widget_bg_image, android.view.View.VISIBLE)
} else {
    views.setViewVisibility(R.id.widget_bg_image, android.view.View.GONE)
}
```

**Dùng `setImageViewUri` + `FileProvider`, KHÔNG dùng `setImageViewBitmap`** — đúng như review1/review2 cảnh báo: `RemoteViews` truyền qua Binder IPC giới hạn ~1MB tổng transaction; bitmap ARGB_8888 480×480 đã chiếm ~921KB, cộng thêm text/color/size của 4 widget instance rất dễ vượt giới hạn → `TransactionTooLargeException`. `setImageViewUri` để Launcher tự đọc file qua URI, không đóng gói bitmap vào Binder transaction.

**B3. `AndroidManifest.xml` + `res/xml/file_paths.xml` — khai báo FileProvider:**
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
```xml
<!-- res/xml/file_paths.xml -->
<paths>
    <files-path name="widget_bg" path="widget_bg/" />
</paths>
```
Đường dẫn `files-path` phải khớp với nơi Flutter đang lưu file thật: `${appDir.path}/widget_bg/current_bg.png` (đã xác nhận đúng trong cả `editor_screen.dart` và `home_screen.dart` — 2 nơi bake dùng chung 1 path).

**B4. Layout XML (`widget_2x1.xml`, `widget_3x1.xml`, `widget_4x1.xml`, `widget_4x2.xml`) — bỏ hard-code, thêm ImageView nền:**

Đổi cấu trúc từ `LinearLayout` phẳng có `android:background="#CC000000"` sang `FrameLayout` bọc ngoài, với `ImageView` nền nằm dưới cùng, `LinearLayout` chứa text nằm trên:
```xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <ImageView
        android:id="@+id/widget_bg_image"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="centerCrop"
        android:visibility="gone" />

    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:orientation="vertical"
        android:gravity="center"
        android:padding="6dp"
        android:background="#59000000">
        <!-- giữ lại lớp phủ tối nhẹ mặc định để chữ luôn đọc được kể cả khi
             không có background ảnh — không hard-code #CC000000 làm nền chính nữa -->

        <TextView android:id="@+id/widget_day" .../>
        <TextView android:id="@+id/widget_date" .../>
        <TextView android:id="@+id/widget_time" .../>
    </LinearLayout>
</FrameLayout>
```
Áp dụng đúng pattern này cho cả 4 file layout, giữ nguyên id các TextView hiện có để không phải sửa `renderWidget()` phần text.

**B5. Bake size — KHÔNG bắt buộc phải sửa ngay, nhưng cần biết đây là nợ kỹ thuật đã xác nhận thật:**

`editor_screen.dart` và `home_screen.dart` đều đang bake cứng `width: 480, height: 480` trong khi comment của `ImageUtils` (theo mô tả từ review, đã không tự đọc lại file này) ngụ ý nên bake theo kích thước thật của từng layout (2x1 vs 4x2 t�system lệ khác nhau). Vì layout mới ở B4 dùng `scaleType="centerCrop"`, ảnh vuông 480×480 sẽ **không bị méo** (centerCrop tự crop theo tỷ lệ khung chứa, không stretch), nên đây **không phải bug chặn release**, chỉ là có thể mất một phần ảnh ở cạnh dài khi tỷ lệ khung quá chênh (ví dụ 4x1 rất dẹt). Xếp việc bake theo kích thước động vào P1, làm sau khi pipeline cơ bản đã chạy được.

### Acceptance Criteria — Bug B
- [ ] `getActiveWidgetIds` trả về danh sách ID thật (không còn `[]` do notImplemented).
- [ ] `setWidgetBackground` lưu path và trigger `updateAllWidgets`.
- [ ] Chọn Solid color → save → Home Widget đổi màu nền thật (không chỉ preview trong app).
- [ ] Chọn Gradient → save → Home Widget hiện gradient.
- [ ] Chọn Image → save → Home Widget hiện ảnh, không méo, chữ vẫn đọc được (nhờ overlay `#59000000` mặc định + `textShadow` từ Flutter side vẫn giữ nguyên ý nghĩa cho phần preview, còn native layout có overlay riêng của nó).
- [ ] Không có `TransactionTooLargeException` khi apply ảnh — do dùng `setImageViewUri`, không `setImageViewBitmap`.
- [ ] Reboot máy → widget vẫn giữ đúng background (vì lưu trong `SharedPreferences` riêng `widget_background`, đọc lại mỗi lần `renderWidget()`).
- [ ] Xóa background (chọn None) → `setBackground(context, widgetId, null)` → widget quay về chỉ còn overlay mặc định `#59000000`, `ImageView` set `GONE`.
- [ ] Thêm widget mới vào Home Screen → nhận đúng background hiện tại ngay từ lần render đầu (vì `renderWidget()` luôn đọc lại `readBackgroundPath()` mỗi lần, không phụ thuộc thời điểm add).

---

## BUG C — DATA CONTRACT: Có cần gộp `BackgroundConfig` vào `ClockConfig` như review đề xuất không?

**Phản biện của tôi với 3/4 bản review (review1, review2, review4 đều đề xuất gộp `BackgroundConfig` vào bên trong `ClockConfig`):** Sau khi đọc kỹ source thực tế, tôi **không đồng ý gộp**. Lý do:

1. `WidgetDesign` (trong `widget_design.dart`) đã là lớp bundle đúng đắn cho trường hợp cần cả hai cùng lúc (dùng cho tính năng "My Designs") — `ClockConfig` và `BackgroundConfig` cố tình tách riêng ở tầng lưu trữ (`StorageService.loadConfig()/loadBackground()` là 2 key `SharedPreferences` riêng: `status_bar_config` và `widget_background`), và được **gộp lại theo nhu cầu** thông qua `WidgetDesign` khi cần đóng gói cùng nhau. Đây là thiết kế hợp lý — tách concern giữa "clock rendering" và "styling/background", không nhất thiết phải gộp cứng thành 1 struct.

2. Bug B thật ra **không đến từ việc 2 config tách rời ở tầng Flutter/SharedPreferences** — nó đến từ việc **Native hoàn toàn chưa có channel/handler nào cho background** (Bug B ở trên). Ở native, tôi đề xuất native **cũng giữ 2 SharedPreferences riêng** (`status_bar_config` cho text, `widget_background` cho path ảnh) — y hệt cấu trúc phía Flutter, **không cần gộp JSON**. `renderWidget()` chỉ cần đọc cả 2 nguồn khi render — điều này đơn giản hơn nhiều so với việc sửa lại toàn bộ `ClockConfig.toJson()/fromJson()` để nhét thêm field background lồng nhau, và tránh phải sửa lại `canUsePreset`, các preset hiện có, và mọi nơi khác đang so sánh `ClockConfig` bằng `==` (đã có rất nhiều chỗ dùng `ClockConfig` thuần trong `presets.dart`, `reward_service.dart` từ các plan trước — gộp thêm field background vào đây sẽ lan rủi ro sang toàn bộ hệ thống preset/reward đã ổn định).

3. Rủi ro thực tế mà review1 nêu ("nếu user reboot máy, `onUpdate()` chỉ đọc `ClockConfig` không có background → mất nền") **đã được giải quyết** bởi thiết kế ở Bug B: native đọc `readBackgroundPath()` từ `SharedPreferences` riêng **mỗi lần `renderWidget()`chạy**, kể cả khi `onUpdate()` được OS gọi sau reboot (không phụ thuộc `saveConfig()` có được gọi lại hay không) — vì bitmap path được lưu **persistent** ngay tại thời điểm `setWidgetBackground()` được gọi, không phải truyền tạm trong bộ nhớ.

**Kết luận Bug C:** Giữ nguyên kiến trúc tách `ClockConfig`/`BackgroundConfig` ở cả Flutter lẫn Native. Không cần task gộp config. Điều thực sự cần chỉ là Bug A (thiếu tham số) và Bug B (native thiếu toàn bộ pipeline) — cả hai đều không đòi hỏi đổi cấu trúc dữ liệu.

---

## QUY TẮC CHUNG CHO AGENT

- Không thêm tính năng mới (không đổi cách bake, không thêm loại background mới...) ngoài phạm vi Bug A/B/C.
- Không gộp `BackgroundConfig` vào `ClockConfig` (xem Bug C — đã phản biện rõ lý do không làm).
- Thứ tự khuyến nghị: Bug A trước (rất nhanh, 1 dòng + 1 fix nhỏ color picker) → Bug B (việc lớn, làm theo đúng B1→B2→B3→B4) → bỏ qua B5 trừ khi còn thời gian.
- Sau khi xong, build thử trên thiết bị/emulator thật (không chỉ code review) vì phần lớn Bug B liên quan tới RemoteViews/FileProvider — chỉ có thể xác nhận đúng khi chạy trên Android thật, `flutter test` không cover được phần native rendering.
- Kiểm tra thủ công tối thiểu các case sau khi xong (dùng luôn làm checklist):
  1. Đổi Solid color trong Editor → Home Screen preview (không phải Editor preview) đổi theo ngay khi quay lại.
  2. Save background bất kỳ loại nào → Home Widget thật trên màn hình chính đổi theo.
  3. Reboot máy (hoặc force-stop app rồi mở lại) → Home Widget vẫn giữ đúng background.
  4. Thêm 1 widget instance mới → nhận đúng background hiện tại ngay từ đầu.
  5. Không có crash/log lỗi `TransactionTooLargeException` trong logcat khi apply ảnh.
- Nếu phát hiện conflict với code hiện tại không có trong plan này, ưu tiên giải pháp đơn giản, ổn định, ít phá kiến trúc, và báo lại trước khi tự ý mở rộng phạm vi.
