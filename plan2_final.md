# Plan2 Final — Forensic Review & Correction Plan

> Nguồn: `plan2.md` + `plan2_review1-4.md` + đọc trực tiếp source thật tại
> `/Users/hoang/htdocs_apps/CustomizableStatusBarWidget/source/date_time_widget/`
> qua aki mcp (không suy đoán — mọi dòng dưới đây đều trích từ code thật).
> Trạng thái: READY — đưa Correction Prompt ở mục 4 cho agent ngay, không rewrite từ đầu.

---

## 0. Verdict tổng thể

Agent **không bỏ Status Bar Companion**, đã code đủ 3 lớp (Home Widget + Notification + Floating Bar), nhưng:

- **Thứ tự ưu tiên UI sai**: Home Widget xuất hiện trước Notification trên Home screen, trong khi Notification mới là USP thật (nội dung duy nhất nằm *trong* status bar thật).
- **9 lỗi kỹ thuật đã xác nhận bằng bằng chứng dòng code** (6 lỗi các review trước đã nêu + 3 lỗi mới phát hiện khi đọc source).
- Không cần vứt source. Sửa đúng 9 điểm dưới đây là đủ để app đạt lại đúng lời hứa "Status Bar Companion".

---

## 1. Bảng Plan → Code thật → Đúng/Sai → Cách sửa

| # | Vấn đề | Mức độ | Bằng chứng trong source | Cách sửa |
| --- | --- | --- | --- | --- |
| 1 | **Sunday crash** — chỉ ở Notification | P0 | `NotificationIconService.kt`: `dayNames[dayOfWeek - Calendar.MONDAY]` → Sunday: `1-2=-1` → `ArrayIndexOutOfBoundsException`. `DateTimeWidgetProvider.kt` và `FloatingBarService.kt` đã có `if (dayIdx < 0) 6 else dayIdx`, **chỉ Notification thiếu**. | Thêm cùng safe-index guard, hoặc chuyển hẳn sang `calendar.getDisplayName(Calendar.DAY_OF_WEEK, Calendar.SHORT, locale)` cho cả 3 nơi để tránh lặp lỗi tương tự trong tương lai. |
| 2 | **Notification không follow ClockConfig** — chỉ đọc `color` | P0 | `NotificationIconService.parseClockData()`: `return ClockData(color = extract("color") ?: "#FFFFFF")` — không đọc `format`, `timeFormat`, `showSeconds`, `showDate`, `showDay`. Thời gian hard-code `SimpleDateFormat("HH:mm")`, ngày hard-code `"$dayName, $dayOfMonth $monthName $year"`. | Parse đầy đủ field giống `DateTimeWidgetProvider.parseClockData()` đang làm (đã có sẵn logic đúng ở file kia — chỉ cần copy sang), rồi dùng để build `fullDate`/`time` thay vì hard-code. |
| 3 | **Config sync fragile hơn cả các review mô tả** | P0 | `widget_bridge.dart`: `_channel.invokeMethod<void>('updateWidgets')` — **không truyền JSON**, chỉ là tín hiệu "đọc lại". Cả 3 native file vẫn đọc thẳng `context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)` rồi tự regex-parse `flutter.clock_config`. Đề xuất "Flutter → MethodChannel JSON → Native tự lưu riêng" trong các review **chưa được implement**, mới chỉ có bridge rỗng. | Sửa `WidgetBridge.updateWidgets()` để nhận `configJson` làm tham số, truyền xuống native qua `invokeMethod('updateWidgets', configJson)`; native parse JSON này rồi tự lưu vào `SharedPreferences` riêng (`status_bar_config`, không phải `FlutterSharedPreferences`). Cả 3 service (Notification, Widget, FloatingBar) đọc từ file riêng này. |
| 4 | **Alignment không áp dụng (Widget) / không parse luôn (FloatingBar)** | P1 | `DateTimeWidgetProvider.kt`: parse `alignment` nhưng không có `setGravity()` hay layout variant nào dùng nó — dead field. `FloatingBarService.parseClockData()`: **không có dòng `extract("alignment")` nào cả** — field bị bỏ hẳn, không phải "parse nhưng không dùng". | Widget: thêm `views.setViewLayoutDirection`/dùng layout variant theo alignment, hoặc `setGravity` trên container. Floating Bar: thêm `extract("alignment")` vào `ClockData`, áp `layout.gravity` tương ứng left/center/right. |
| 5 | **Không có `ACTION_TIME_TICK`** | P0 | Grep toàn repo: không có kết quả nào chứa `ACTION_TIME_TICK`. Cơ chế update hiện tại là `Handler.postDelayed` 60s (Notification) và `AlarmManager.setExactAndAllowWhileIdle` mỗi 60s (Widget) — cả hai đều chết khi process bị kill hoặc bị OEM (MIUI/OneUI) hạn chế background. | Thay bằng `BroadcastReceiver` đăng ký **động** (`registerReceiver` trong `onCreate` của Foreground Service, không khai trong Manifest vì API 26+ cấm implicit broadcast) lắng nghe `Intent.ACTION_TIME_TICK`. Khi nhận được, update đồng thời Notification + Widget + Floating Bar. |
| 6 | **`SCHEDULE_EXACT_ALARM` khai báo nhưng zero runtime check** | P1 | `AndroidManifest.xml` có `<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />`. Grep toàn repo: không có `canScheduleExactAlarms()` hay `ACTION_REQUEST_SCHEDULE_EXACT_ALARM` ở đâu cả. `setExactAndAllowWhileIdle()` có thể fail âm thầm trên thiết bị/OS chặn quyền này. | Sau khi chuyển sang `ACTION_TIME_TICK` (mục #5), permission này **không còn cần thiết** — nên gỡ hẳn khỏi Manifest thay vì thêm flow xin quyền, đơn giản hóa app. |
| 7 | **Notification hard-code tên thứ/tháng tiếng Anh, bỏ qua locale máy** *(phát hiện mới)* | P1 | `NotificationIconService.kt`: `dayNames`/`monthNames` là mảng string tiếng Anh cứng. Chỉ riêng `time = SimpleDateFormat("HH:mm", Locale.getDefault())` có dùng locale — ngày/thứ thì không. User máy tiếng Việt/Nhật/Hàn vẫn thấy "Sunday, 30 August 2026". | Dùng `SimpleDateFormat(fullDatePattern, Locale.getDefault())` hoặc `calendar.getDisplayName(..., locale)` thay cho mảng hard-code, đồng bộ với cách 2 file kia đã làm đúng hơn (dùng `Locale.getDefault()` cho time format). |
| 8 | **`FloatingBarService.update()` = stop() + start() toàn bộ service mỗi lần Save** *(phát hiện mới)* | P1 | ```kotlin\nfun update(context: Context) {\n    if (!isEnabled(context)) return\n    stop(context)\n    start(context)\n}\n``` — mỗi lần user đổi 1 field trong Editor, overlay bị gỡ và add lại từ đầu (nháy hình). Trên Android 12+, start foreground service liên tục trong thời gian ngắn có thể bị hệ thống throttle. | Đổi `update()` thành cập nhật in-place: gọi thẳng `updateOverlay()` (hàm đã có sẵn trong service) để chỉ set lại text/màu trên view đang tồn tại, không gỡ/tạo lại `WindowManager` view. Chỉ dùng stop/start thật khi user bật/tắt tính năng. |
| 9 | **Home UI hierarchy: Widget đứng trước Notification** *(xác nhận bằng dòng code)* | P1 | `home_screen.dart`: thứ tự nút thật là Customize → Presets → **Add Widget** → Enable Notification → Enable Floating Bar → Settings. Notification — USP thật — nằm sau Widget. | Đổi thứ tự UI: **STATUS BAR (Notification)** lên đầu tiên, sau đó Home Widget, cuối cùng Floating Bar (optional). Có thể nhóm 3 mục theo section header như mockup ở mục 3 dưới. |

**Việc agent đã làm đúng (không cần đổi):**
- Floating Bar đặt `y = statusBarHeight`, không cố đè lên status bar thật (`TYPE_APPLICATION_OVERLAY` — đúng giới hạn Android 8+ đã thống nhất từ `plan1_final.md`).
- Dialog `_onEnableFloatingBar` nói rõ "This does NOT modify your phone's status bar" — đúng hướng minh bạch, tránh review 1 sao vì hiểu lầm.
- Notification chỉ hiện số ngày trên small icon (không cố nhồi full text) — đúng giới hạn kỹ thuật của notification small icon.
- Zero ads trên Notification / Widget / Floating Bar.
- Có BootReceiver, Foreground Service, offline-first, cấu trúc MethodChannel bridge cơ bản đã tồn tại (chỉ cần bổ sung nội dung JSON truyền qua).

---

## 2. Kiến trúc Config chuẩn (mục tiêu sau khi sửa #3)

```
User Save trong Editor
       ↓
Flutter ClockConfig → toJsonString()
       ↓
WidgetBridge.updateWidgets(configJson)   ← SỬA: truyền JSON, không còn rỗng
NotificationService.update(configJson)
FloatingBarBridge.update(configJson)
       ↓
Native: mỗi bridge nhận JSON qua MethodChannel
       ↓
Native tự lưu vào SharedPreferences RIÊNG của mình
  context.getSharedPreferences("status_bar_config", MODE_PRIVATE)
       ↓ (KHÔNG còn đọc "FlutterSharedPreferences" / "flutter.clock_config")
NotificationController / DateTimeWidgetProvider / FloatingBarService
đọc từ "status_bar_config" — độc lập hoàn toàn với Flutter process,
kể cả sau reboot (BootReceiver đọc cùng file này).
```

---

## 3. Home UI hierarchy sau khi sửa #9

```
┌───────────────────────────────┐
│ Date & Time Widget            │
│                               │
│      LIVE PREVIEW              │
│                               │
├───────────────────────────────┤
│ STATUS BAR (P0 — USP)         │
│ ✓ Notification icon           │
│   [ Configure / Enable ]      │
│                               │
│ HOME SCREEN (P0)              │
│ ✓ Widget                      │
│   [ Add Widget ]              │
│                               │
│ FLOATING BAR (P1 — optional)  │
│ ○ Sits below status bar       │
│   [ Enable ]                  │
├───────────────────────────────┤
│           AdMob Banner        │
└───────────────────────────────┘
```

Không cần đổi Store name/product identity — chỉ đổi thứ tự + gom nhóm 3 mục trên Home screen.

---

## 4. Correction Prompt (copy-paste cho coding agent)

```
STOP DEVELOPMENT. Không thêm feature mới. Không đổi product thành
Date-Time Widget thuần túy, không đổi Store name/positioning.

Tôi đã forensic-review source thật và xác nhận 9 lỗi cụ thể dưới đây,
mỗi lỗi kèm bằng chứng dòng code. Sửa đúng thứ tự, không nhảy bước,
không rewrite lại từ đầu — chỉ sửa đúng các điểm này:

1. Fix Sunday crash trong NotificationIconService.kt: dayNames[dayOfWeek
   - Calendar.MONDAY] cho ra index -1 vào Chủ Nhật. Áp dụng safe-index
   guard giống DateTimeWidgetProvider.kt và FloatingBarService.kt đã
   làm đúng (if (dayIdx < 0) 6 else dayIdx), hoặc dùng
   calendar.getDisplayName(Calendar.DAY_OF_WEEK, Calendar.SHORT, locale)
   cho cả 3 file để tránh lặp lại lỗi tương tự.

2. NotificationIconService.parseClockData() hiện chỉ đọc "color", bỏ
   qua format/timeFormat/showSeconds/showDate/showDay. Copy logic parse
   đầy đủ đang có sẵn trong DateTimeWidgetProvider.parseClockData() sang
   NotificationIconService, dùng để build fullDate/time thay vì hard-code
   SimpleDateFormat("HH:mm") và "$dayName, $dayOfMonth $monthName $year".

3. Sửa config sync boundary: WidgetBridge.updateWidgets() hiện gọi
   invokeMethod('updateWidgets') KHÔNG truyền JSON gì — sửa thành truyền
   configJson làm tham số. Tương tự cho NotificationService.update() và
   FloatingBarBridge.update() nếu chúng cũng đang gọi rỗng. Phía native,
   3 service (NotificationIconService, DateTimeWidgetProvider,
   FloatingBarService) đang đọc thẳng
   context.getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
   và key "flutter.clock_config" — đổi sang: mỗi khi nhận JSON qua
   MethodChannel, native tự lưu vào SharedPreferences riêng
   ("status_bar_config", MODE_PRIVATE), và cả 3 service đọc config từ
   file riêng này, không đọc chéo file của Flutter plugin nữa.

4. Alignment: DateTimeWidgetProvider.kt parse "alignment" nhưng không hề
   gọi setGravity hay chọn layout variant theo nó — thêm logic áp dụng
   thật. FloatingBarService.parseClockData() không hề có dòng
   extract("alignment") — thêm field này vào ClockData và áp
   layout.gravity tương ứng left/center/right khi build/update bar.

5. Gỡ toàn bộ Handler.postDelayed (NotificationIconService) và
   AlarmManager.setExactAndAllowWhileIdle (DateTimeWidgetProvider). Thay
   bằng BroadcastReceiver đăng ký ĐỘNG (registerReceiver trong onCreate
   của một Foreground Service, không khai trong AndroidManifest.xml vì
   API 26+ cấm implicit broadcast) lắng nghe Intent.ACTION_TIME_TICK.
   Khi nhận broadcast, update đồng thời cả Notification, Widget, và
   Floating Bar.

6. Sau khi hoàn thành bước 5, gỡ permission
   android.permission.SCHEDULE_EXACT_ALARM khỏi AndroidManifest.xml —
   không còn cần thiết vì đã chuyển sang ACTION_TIME_TICK, và hiện tại
   permission này được khai báo nhưng không có bất kỳ runtime check nào
   (không có canScheduleExactAlarms ở đâu trong source).

7. NotificationIconService.kt đang hard-code dayNames/monthNames bằng
   mảng tiếng Anh cứng, bỏ qua locale máy (chỉ time dùng
   Locale.getDefault(), ngày/thứ thì không). Sửa để dùng
   SimpleDateFormat với Locale.getDefault() hoặc calendar.getDisplayName
   với locale, đồng bộ cách 2 file kia đang xử lý locale đúng hơn.

8. FloatingBarService.update() hiện gọi stop(context) rồi start(context)
   — gỡ và tạo lại toàn bộ overlay mỗi lần user Save trong Editor, gây
   nháy hình và có thể bị Android throttle nếu start foreground service
   liên tục. Sửa update() để gọi thẳng updateOverlay() (hàm đã có sẵn
   trong service) — chỉ cập nhật text/màu trên view đang tồn tại, không
   gỡ/tạo lại WindowManager view. Chỉ dùng stop()/start() thật khi user
   bật/tắt tính năng, không dùng cho mỗi lần Save config.

9. Đổi thứ tự UI trên home_screen.dart: hiện tại là Customize → Presets
   → Add Widget → Enable Notification → Enable Floating Bar → Settings.
   Đổi thành 3 nhóm rõ ràng theo section: "STATUS BAR" (Notification,
   P0 — đứng đầu) → "HOME SCREEN" (Widget, P0) → "FLOATING BAR"
   (optional, P1) — theo đúng mockup trong plan2_final.md mục 3. Không
   đổi tên app/Store listing, chỉ đổi hierarchy hiển thị trên Home
   screen.

Sau khi hoàn thành cả 9 điểm, chạy lại toàn bộ test trong
test/*.dart hiện có (đã thấy: date_formatter_test, editor_config_test,
floating_bar_config_test, iap_premium_test, notification_config_test,
storage_service_test) và bổ sung test case cho: Sunday không crash,
notification follow đủ config, config sync qua MethodChannel JSON có
đúng key/value, alignment áp dụng đúng trên Widget + Floating Bar.

Chỉ khi tất cả 9 điểm trên pass mới được tiếp tục polish Ads/IAP/ASO
hoặc thêm feature mới.
```

---

## 5. Việc tiếp theo sau khi agent fix xong

- Chạy test matrix thật trên Pixel/Samsung/Xiaomi, Android 12–16 (như `plan1_final.md` mục 8-9 đã định nghĩa).
- Đặc biệt kiểm tra: Sunday (đổi giờ máy sang Chủ Nhật để test), đổi locale máy sang tiếng Việt/Nhật để test mục #7, tắt/mở lại Floating Bar nhiều lần liên tiếp để test mục #8 không bị throttle, reboot máy để xác nhận Notification/Widget/Floating Bar đọc đúng `status_bar_config` sau khi sửa mục #3.
- Nếu cả 9 điểm pass, có thể coi source đạt production-ready theo đúng kiến trúc "Status Bar Companion" đã thống nhất từ `plan1_final.md`.