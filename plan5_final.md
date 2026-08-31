# Plan5 Final — V1.0 Personalization Spec
## Background Image · My Designs · Share Preview

> Nguồn: `plan5.md` + `plan5_review1-4.md` + `features.md`/`features1.md` + forensic đọc trực tiếp
> source thật tại `/Users/hoang/htdocs_apps/CustomizableStatusBarWidget/source/date_time_widget/`
> qua aki mcp (ngày 31/08/2026).
> Trạng thái: READY FOR DEV — P0 cũ đã đóng hoàn toàn, có thể code feature mới ngay.

---

## 0. Xác nhận trạng thái nền tảng (forensic, không suy đoán)

Trước khi thêm bất kỳ feature mới nào, đã verify trực tiếp source và xác nhận **toàn bộ P0 từ các vòng review trước đã được đóng, tốt hơn cả review3 từng ghi nhận**:

| Hạng mục | review3 ghi nhận | Thực tế xác nhận bằng code |
| --- | --- | --- |
| Premium UI ẩn | "Chưa ẩn" | **Đã ẩn** — `settings_screen.dart:34`: `static const bool kShowPremiumUi = false;` |
| Apply config sau reward | "Cần xác nhận" | **Đã đúng** — `home_screen.dart`: cả `_openEditor()` và `_openPresets()` đều gọi đủ chuỗi `saveConfig` → `WidgetBridge.updateWidgets` → `_notifService.update()` → `FloatingBarBridge.update()` |
| `canUsePreset()` logic | Đã sửa | Xác nhận có test coverage đầy đủ trong `reward_service_test.dart` — free preset luôn true, locked preset chỉ true khi đã unlock hôm nay hoặc còn lượt |
| `showSeconds` cleanup | Đã sạch | Xác nhận — chỉ còn xuất hiện trong test để chứng minh field đã bị loại bỏ khỏi `ClockConfig` |

**Kết luận:** không cần Correction Prompt nào thêm. Có thể bắt tay Background Image / My Designs / Share ngay.

---

## 1. Định vị sản phẩm V1.0

| Trước | Sau |
| --- | --- |
| Date & Time Widget | **Photo Clock Widget** |
| Customize màu/font | Design clock từ ảnh của bạn |
| 8 preset cố định | Preset + **My Designs** (user-owned, lưu được) |

USP status bar (Notification icon) **giữ nguyên là P0**. Lớp personalization mới gắn chủ yếu vào **Home Widget + In-app Preview**. Floating Bar dùng style đơn giản (solid/gradient/glass) trước, ảnh đầy đủ để sau nếu ổn định.

---

## 2. Ba phát hiện kỹ thuật mới (từ forensic review, chưa từng được nêu trong review1-4)

Đây là phần khác biệt quan trọng nhất so với spec ban đầu của review3 — xác nhận trực tiếp bằng cách đọc `widget_4x2.xml`, `widget_info.xml`, và `DateTimeWidgetProvider.kt`.

### 2.1 Layout hiện tại KHÔNG có `ImageView`
Cả 4 file (`widget_2x1.xml`, `widget_3x1.xml`, `widget_4x1.xml`, `widget_4x2.xml`) hiện chỉ có `LinearLayout` nền màu đặc (`#CC000000`) + 3 `TextView` (day/date/time). Thêm ảnh nền = thay đổi cấu trúc, không phải chỉnh nhỏ:
```xml
<!-- Cấu trúc mới cần có, ví dụ widget_4x2.xml -->
<FrameLayout ...>
    <ImageView
        android:id="@+id/widget_background"
        android:layout_width="match_parent"
        android:layout_height="match_parent"
        android:scaleType="centerCrop" />
    <LinearLayout ...> <!-- giữ nguyên 3 TextView như cũ, đè lên trên -->
        ...
    </LinearLayout>
</FrameLayout>
```

### 2.2 Widget dùng resizable definition động — bitmap phải bake theo từng `widgetId`, không dùng chung
`widget_info.xml` khai `resizeMode="horizontal|vertical"`, và `DateTimeWidgetProvider.chooseLayout()` đọc `AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH/HEIGHT` để **chọn layout động theo từng widget instance thực tế trên máy**. Hệ quả: 2 user cùng áp 1 design nhưng đặt widget size khác nhau (2x1 vs 4x2) sẽ cần crop/scale ảnh khác nhau. Bake 1 bitmap dùng chung cho mọi instance (như spec cũ giả định) sẽ khiến ảnh bị stretch/pixelate ở size không khớp.

**Sửa:** bake bitmap riêng theo từng `widgetId`, đọc kích thước thực từ `AppWidgetManager.getAppWidgetOptions(widgetId)` tại thời điểm bake, cache theo key `(designId, widgetId)`.

### 2.3 Giới hạn bộ nhớ RemoteViews Bitmap — không nên cố định "1080px, JPEG 80%" cho mọi trường hợp
Từ Android 12 trở lên, `AppWidgetManager.updateAppWidget()` áp giới hạn tổng bộ nhớ bitmap tính theo tỉ lệ với kích thước màn hình thiết bị. Vượt quá → toàn bộ widget update thất bại âm thầm phía OS (không crash app, nhưng widget đứng hình, khó debug vì exception xảy ra ngoài tầm kiểm soát của code Flutter/Kotlin).

**Sửa:** resize ảnh theo pixel thực tế của từng widget instance (từ mục 2.2) thay vì luôn ép về 1080px. Đặt trần an toàn tuyệt đối, ví dụ 480×480px cho size lớn nhất (4x2) — vừa nhẹ hơn, vừa né giới hạn OS này.

---

## 3. Data Model

```dart
class WidgetDesign {
  final String id;              // uuid
  final String name;            // "Home", "Night", "Travel"
  final ClockConfig clock;      // format, timeFormat, showDay, showDate, fontSize, color, alignment
  final BackgroundConfig background;
  final DateTime updatedAt;
}

class BackgroundConfig {
  final BackgroundType type;    // none | solid | gradient | image
  final String? solidColor;
  final List<String>? gradientColors;
  final String? imagePath;      // local path, đã copy vào app documents
  final double cropScale;
  final Offset cropOffset;
  final double blurSigma;       // 0 = off, gợi ý 6-8 nếu bật
  final double overlayOpacity;  // 0-0.7
  final OverlayMode overlayMode; // dark | light | none
  final bool autoTextContrast;  // default true
  final bool textShadow;        // default true
}

enum BackgroundType { none, solid, gradient, image }
enum OverlayMode { none, dark, light }
```

**Giới hạn Free:** My Designs tối đa **3**; 1 ảnh/design; nguồn ảnh gốc lưu ở resolution vừa phải để tái sử dụng khi bake lại cho widget size mới (không cần đè lên nguồn gốc bằng bản đã resize nhỏ cho 1 size cụ thể).

**Premium (sau này):** không giới hạn số design.

### Persistence

| Data | Nơi lưu |
| --- | --- |
| `ClockConfig` đang áp dụng | `SharedPreferences` (như hiện tại) |
| Danh sách `WidgetDesign` | `SharedPreferences` JSON list |
| Ảnh gốc (đã resize vừa phải, ví dụ max cạnh 1600px) | `getApplicationDocumentsDirectory()/designs/{designId}_source.jpg` |
| Bitmap đã bake cho từng widget instance | `getApplicationDocumentsDirectory()/designs/{designId}_{widgetId}.png`, tạo khi cần, xóa khi design/widget bị gỡ |

---

## 4. Feature A — Background Image Pipeline

### User flow
```
Editor / Design Editor
    ↓
Background section: None / Solid / Gradient / Image
    ↓ (nếu Image)
Pick from gallery → Crop screen (zoom + pan)
    ↓
Smart Defaults tự áp:
  - dark overlay 35%
  - auto text contrast
  - text shadow bật
  - blur = 0 (tắt mặc định, bật tay nếu muốn)
    ↓
Live Preview → [Fine-tune nếu muốn] → Save
```

### Pipeline xử lý (thứ tự bắt buộc)
1. Decode + resize ảnh gốc về max cạnh 1600px, lưu làm `_source.jpg`.
2. Khi bake cho 1 widget instance cụ thể: đọc kích thước thực (mục 2.2) → crop theo vùng user chọn, scale xuống đúng pixel cần cho instance đó (trần 480×480, mục 2.3).
3. (Optional) Blur nếu user bật.
4. Overlay dark/light theo config.
5. Tính luminance vùng chữ → set text color nếu `autoTextContrast`.
6. Lưu file bake `_{widgetId}.png`, gọi `RemoteViews.setImageViewBitmap`.

**Nguyên tắc:** mọi hiệu ứng nặng (blur, contrast, bake) chạy **một lần lúc Save/Apply hoặc khi widget instance mới được thêm**, không chạy trong `onUpdate()` định kỳ mỗi phút — chỉ TextView (giờ/ngày) mới cập nhật theo `ACTION_TIME_TICK`, ảnh nền giữ nguyên bitmap đã bake.

### Surfaces

| Surface | Background Image V1.0 |
| --- | --- |
| In-app Preview | Full pipeline, không giới hạn size vì render trong Flutter |
| Home Widget | Ảnh đã bake theo từng widgetId (mục 2.2, 2.3) |
| Floating Bar | Solid/gradient/glass trước; ảnh đầy đủ để sau (surface là 1 View thật, ít ràng buộc hơn RemoteViews nhưng chưa cần thiết cho V1.0) |
| Notification | Không dùng ảnh — giữ nguyên text/icon nhỏ |

---

## 5. Feature B — My Designs

```
My Designs
├── [Built-in Presets]   ← clone được, không ghi đè
├── ──────────────────
├── ★ Home
├── ★ Night
├── ★ Travel
└── [+ Create New]       ← disabled nếu đã đủ 3 (free)
```

| Hành động | Free | Ghi chú |
| --- | --- | --- |
| Create | ≤ 3 | Từ editor hiện tại + background |
| Rename / Delete | ✅ | Delete xóa cả file ảnh (`_source.jpg` + mọi `_{widgetId}.png` liên quan) |
| Clone từ preset | ✅ | Tính vào quota 3 |
| Apply (1 tap) | ✅ | `saveConfig` + sync 3 surface, tái dùng đúng chuỗi update đã xác nhận đúng ở mục 0 |

Flow Apply tái sử dụng nguyên luồng đã có sẵn và đã verify đúng trong `home_screen.dart` (`saveConfig` → `WidgetBridge.updateWidgets` → `_notifService.update()` → `FloatingBarBridge.update()`) — không cần viết luồng mới, chỉ cần `PresetsScreen`/`MyDesignsScreen` trả `ClockConfig` (+ background info riêng) như `PresetsScreen` đang làm.

---

## 6. Feature C — Share Design Preview

- Output: ảnh PNG cố định (ví dụ theo tỉ lệ 4x2: 1080×540), gồm background đã xử lý + time/date theo design + branding nhỏ góc (tắt được cho bản Premium sau).
- Share qua system share sheet (`share_plus`, đã có trong whitelist package từ `plan1.md`).
- V1.0 không cần share JSON/QR — để V1.1.

---

## 7. Monetization gắn feature (V1.0)

| Hạng mục | Free | Sau này (Rewarded/Premium) |
| --- | --- | --- |
| Background image | ✅ (trong quota design) | — |
| My Designs | 3 slots | Unlimited (Premium) |
| Overlay/Blur cơ bản | ✅ | Advanced levels (optional, không bắt buộc V1.0) |
| Share preview | ✅ (watermark nhẹ) | No watermark (Premium) |
| Auto Day/Night | Chưa có ở V1.0 | V1.0.1/V1.1 |

Nguyên tắc: **không khóa Background Image sau paywall** — để user "nghiện" personalization trước, chặn ở số lượng design + hiệu ứng nâng cao + automation.

---

## 8. Thứ tự implement

```
Phase 1 — Model & Storage
  1. WidgetDesign + BackgroundConfig models
  2. DesignStorageService (CRUD, quota 3)
  3. Image copy/resize vào app documents (nguồn gốc max 1600px)

Phase 2 — Background trong App Preview
  4. UI Background section trong Editor
  5. Gallery pick + crop screen
  6. Pipeline overlay + auto contrast + shadow (chạy trong Flutter cho preview)
  7. Live preview đúng

Phase 3 — Home Widget (đã cập nhật theo mục 2)
  8. Sửa 4 file layout XML: thêm ImageView làm layer nền dưới TextView hiện có
  9. Native: đọc AppWidgetManager.getAppWidgetOptions(widgetId) để lấy size thực khi bake
  10. Bake bitmap RIÊNG theo từng widgetId, trần an toàn 480×480px cho size lớn nhất
  11. Cache bitmap đã bake theo (designId, widgetId); chỉ re-bake khi đổi design hoặc khi
      onAppWidgetOptionsChanged báo size instance thay đổi (user resize widget)
  12. Update giờ/ngày qua ACTION_TIME_TICK KHÔNG re-bake ảnh — chỉ set lại TextView

Phase 4 — My Designs
  13. Màn My Designs (list + create/rename/delete)
  14. Apply 1 tap (tái dùng luồng update đã xác nhận đúng ở mục 0)
  15. Quota 3 + thông báo khi đầy

Phase 5 — Share
  16. Render preview image
  17. System share sheet

Phase 6 — QA
  18. Test trên nhiều size widget cùng lúc (đặt 1 design lên cả widget 2x1 và 4x2 trên cùng máy)
  19. Test đổi size widget bằng tay (kéo giãn) → xác nhận bitmap bake lại đúng, không stretch
  20. Test ảnh input rất lớn (12MP+) không làm app/widget lag hay bị OS từ chối update
  21. Device thật: Pixel, Samsung, Xiaomi; ảnh sáng/tối để test auto contrast
```

---

## 9. Acceptance Criteria

### Background Image
- [ ] Chọn ảnh gallery → crop → preview chữ luôn đọc được trên cả ảnh sáng và tối
- [ ] Apply → Home Widget hiện đúng ảnh + chữ, không méo/stretch
- [ ] Đặt cùng 1 design lên 2 widget instance kích thước khác nhau trên cùng máy → cả 2 đều hiển thị đúng tỉ lệ, không bị vỡ hình
- [ ] Kéo giãn (resize) 1 widget instance → ảnh bake lại đúng theo size mới, không giữ bitmap cũ bị stretch
- [ ] Không crash hay bị OS từ chối update với ảnh input 12MP+
- [ ] Xóa design → toàn bộ file ảnh liên quan (source + mọi bản bake theo widgetId) bị xóa, không leak dung lượng

### My Designs
- [ ] Lưu tối đa 3 design (free); design thứ 4 → thông báo giới hạn
- [ ] Apply 1 tap cập nhật preview + widget + notification + floating bar (nếu bật) đúng luồng đã verify ở mục 0
- [ ] Rename/Delete hoạt động đúng

### Share
- [ ] Tạo ảnh preview đúng design, mở được system share sheet
- [ ] Có branding nhỏ ở bản free

### Không được phá vỡ (regression)
- [ ] Status bar notification vẫn hoạt động, không bị ảnh hưởng bởi feature mới
- [ ] Reward daily preset flow (đã xác nhận đúng ở mục 0) vẫn hoạt động nguyên vẹn
- [ ] Không có ads trên widget/floating bar/notification
- [ ] Không xuất hiện lại `showSeconds` ở bất kỳ đâu
- [ ] Offline-first — không phát sinh network call mới

---

## 10. Out of scope V1.0 (cấm scope creep)

- Auto Day/Night (làm ngay sau nếu Phase 1-5 ổn, đây là V1.1)
- QR import/export design
- Community gallery / design packs
- Background video / live wallpaper
- Battery/Network/RAM modules (đúng theo mọi review — để V1.1)
- Full ảnh trên Floating Bar (trừ khi Phase 3 rất mượt và có dư thời gian)
- Cloud sync
