# Plan Final — Date & Time Widget (Status Bar Companion)

> Nguồn: tổng hợp + phản biện từ `plan1.md` và `plan1_review1-5.md`
> Trạng thái: READY FOR DEV — scope đã freeze, không tự mở rộng khi code
> Framework: Flutter (UI) + Native Android/Kotlin (widget, notification, overlay)

---

## 0. Tóm tắt quyết định (đọc trước khi code)

| Vấn đề | Các review trước nói | Quyết định final | Lý do |
| --- | --- | --- | --- |
| Vẽ text đè lên **status bar thật** | Review 2, 3 cho rằng khả thi qua `TYPE_APPLICATION_OVERLAY` | **KHÔNG khả thi từ Android 8.0 (API 26)+.** Google cố tình chặn app vẽ đè System UI (status bar/nav bar/IME) bằng `TYPE_APPLICATION_OVERLAY`. App kinh điển "Status" đã chết vì lý do này và không có cách lách. | Đây là sự thật kỹ thuật, không phải rủi ro chính sách — không có workaround. |
| Cách duy nhất để nội dung nằm *trong* status bar thật | Review 4, 5 ưu tiên notification nhưng không giải thích rõ tại sao | **Notification icon** — do SystemUI tự vẽ theo `NotificationManager`, không phải app tự overlay | Đây là API chính thống duy nhất chèn được nội dung vào chính status bar |
| Giới hạn của notification icon | Không review nào đề cập | Icon nhỏ, đơn sắc, thường chỉ hiện được số/icon đơn giản (vd "30"), **không hiện được chuỗi "SUN 30 AUG"** như mockup | OEM giới hạn icon slot + rendering monochrome |
| Floating bar "gần" status bar | Review 2, 3 gọi là "status bar overlay" | Đổi tên nội bộ + trong UI thành **"Floating Bar"** — nằm ngay dưới status bar thật, KHÔNG chồng lên nó | Tránh hứa hẹn sai với user → tránh 1-sao vì "không giống status bar Samsung" |
| Home widget | Review 1 coi là core, review 2/3 coi là bỏ USP | **P0 bắt buộc**, là nền tảng ổn định + ASO đẹp, không phải "thay thế" mà là 1 trong 3 lớp | Là phần chắc-chắn-chạy-được trên mọi máy |
| Monetization | Review 1: chỉ banner. Review 2/3: rewarded mạnh + overlay clickable + interstitial. Review 4/5: rewarded + banner + IAP, cấm ads ngoài app | **Đồng ý hướng review 4/5**: Rewarded (P0) + Banner trong app (P0) + IAP remove ads (P0) + Interstitial rất hạn chế (P2). Cấm tuyệt đối ads trên widget/notification/floating bar | Cân bằng giữa doanh thu và tỉ lệ gỡ cài đặt |

**Việc bắt buộc làm TRƯỚC khi bắt đầu 8 ngày code:** dựng prototype nửa ngày test riêng notification icon + floating bar trên máy Android thật (ưu tiên Pixel, vì đây là target user chính) để biết hình dạng thực tế trước khi thiết kế UI/ASO xoay quanh nó.

---

## 1. Product Concept

**Tên nội bộ:** Date & Time Widget (tên Store sẽ chốt sau khi có build thật)

**Positioning (copy an toàn, không hứa quá):**
> "Always see the day, date & time — home widget + status bar icon."

**Không dùng trong copy/ASO:** "thay đổi status bar", "giống Samsung 100%", "status bar mod" — vì dễ gây kỳ vọng sai → review 1 sao.

**3 lớp hiển thị (ưu tiên theo độ tin cậy kỹ thuật):**

```
                    APP
                     │
        ┌────────────┼────────────┐
        ▼            ▼            ▼
  HOME WIDGET   NOTIFICATION   FLOATING BAR
  (P0, chắc     ICON (P0,      (P1, optional,
   chắn chạy)    giới hạn      nằm dưới status
                 icon nhỏ)     bar thật)
```

---

## 2. User Flows

### Flow 1 — First launch
```
Mở app → "See day, date & time everywhere" (screen giới thiệu 3 lớp,
kèm ảnh thật, không phải mockup phóng đại)
 → Preview live
 → Chọn style
 → "Add to Home Screen" → Android widget picker
 → Bật notification icon (permission POST_NOTIFICATIONS, Android 13+)
 → (optional, giải thích rõ) Bật Floating Bar → xin "Display over other apps"
 → DONE
```

### Flow 2 — Customize
```
Home → Editor → chọn format/font/color/size → Live Preview → Save
→ tự động update Widget + Notification + Floating Bar (nếu bật)
```

### Flow 3 — Unlock premium format (Rewarded)
```
User chọn format khoá → "Watch a short ad to unlock" → user chủ động bấm Watch
→ Rewarded Video → unlock vĩnh viễn → lưu SharedPreferences
```

### Flow 4 — Remove Ads (IAP)
```
Settings → "Remove Ads & Unlock All" → mua 1 lần → tắt Banner + Rewarded prompt
```

### Flow 5 — Reboot recovery
```
Device reboot → BroadcastReceiver (BOOT_COMPLETED) → khởi động lại
Notification service + Floating Bar service (nếu user đã bật) → Widget
tự cập nhật qua AlarmManager/WorkManager
```

---

## 3. Wireframe (text-based)

**Home screen:**
```
┌──────────────────────────┐
│  Date & Time Widget      │
│                           │
│   ┌───────────────────┐   │
│   │   Live Preview     │   │
│   │   SUN 30 AUG        │   │
│   │   08:35             │   │
│   └───────────────────┘   │
│                           │
│  [ Customize ]            │
│  [ Add Widget ]           │
│  [ Enable Notification ]  │
│  [ Enable Floating Bar ]  │
│                           │
├──────────────────────────┤
│      AdMob Banner         │
└──────────────────────────┘
```

**Editor screen:** danh sách format → font size slider → color picker → alignment → nút Save. Không banner che preview.

---

## 4. Features — P0 / P1 / P2

### P0 (bắt buộc MVP — 8 ngày)
- Live clock: 12/24h, auto update, timezone theo device
- Date: nhiều format (DD/MM/YYYY, MMM DD, v.v.)
- Day of week: full/short/uppercase
- Home-screen widget: size 2x1, 3x1, 4x1, 4x2
- 6–8 preset đẹp + live preview
- Customization cơ bản: font size, màu, alignment
- Notification icon (hiển thị số ngày hoặc icon đơn giản — **không hứa hiện full text**)
- Auto-start sau reboot (BOOT_COMPLETED)
- Lưu config offline (`shared_preferences`)
- AdMob: Banner (Settings/Home) + Rewarded (unlock format)
- One-time IAP "Remove Ads"
- Onboarding ngắn, xin quyền notification rõ ràng lý do

### P1 (sau khi MVP chạy ổn, có data)
- Floating Bar (floating overlay dưới status bar thật) — optional, permission riêng
- Thêm preset theo mùa/tuần (tạo lý do quay lại app)
- Share preset dưới dạng ảnh (organic acquisition, chi phí thấp)
- Multiple widget instance với style khác nhau

### P2 (chỉ làm nếu có nhu cầu rõ từ user/data)
- Interstitial (chỉ sau khi Save config thành công, có nút close rõ trong 15s)
- Notification shade companion (thông tin mở rộng khi kéo xuống)
- Dark/Light theme riêng cho widget

### Không làm (out of scope, mọi giai đoạn)
- Account / cloud sync / Firebase / backend
- Weather, full calendar, alarm
- AccessibilityService
- Ads trên widget / notification / floating bar (cấm tuyệt đối — vi phạm chính sách Google Play về ads ngoài phạm vi app)
- Overlay tự nhận là "sửa status bar hệ thống"

---

## 5. Kiến trúc kỹ thuật

```
lib/
  main.dart
  models/
    clock_config.dart
    preset.dart
    widget_config.dart
  screens/
    home_screen.dart
    editor_screen.dart
    presets_screen.dart
    settings_screen.dart
    onboarding_screen.dart
  widgets/
    clock_preview.dart
    preset_card.dart
    format_selector.dart
    ad_banner.dart
  services/
    storage_service.dart       # shared_preferences
    ads_service.dart           # google_mobile_ads
    iap_service.dart           # in_app_purchase
    notification_service.dart  # flutter_local_notifications hoặc native
    widget_bridge.dart         # MethodChannel -> AppWidgetProvider
    floating_bar_bridge.dart   # MethodChannel -> OverlayService (P1)
  utils/
    date_formatter.dart
    constants.dart

android/
  app/src/main/kotlin/.../
    DateTimeWidgetProvider.kt   # AppWidgetProvider
    BootReceiver.kt             # BOOT_COMPLETED
    NotificationIconService.kt  # cập nhật icon notification
    FloatingBarService.kt       # P1, ForegroundService + TYPE_APPLICATION_OVERLAY
                                 # ĐẶT NGAY DƯỚI status bar, KHÔNG cố vẽ đè lên nó
```

**Nguyên tắc kiến trúc:**
- Flutter chỉ xử lý UI/config/ads/IAP.
- Native Android xử lý widget, notification, floating bar — vì đây là phần OS-level, Flutter không đủ khả năng làm ổn định.
- MethodChannel một chiều: Flutter đẩy config xuống native, native tự chạy độc lập kể cả khi app Flutter bị kill.
- Storage: `shared_preferences` đủ dùng — không cần Hive/sqflite ở MVP vì data rất nhỏ (1 JSON config + trạng thái unlock).

**Config schema mẫu:**
```json
{
  "format": "EEE dd MMM",
  "timeFormat": "HH:mm",
  "showSeconds": false,
  "showDate": true,
  "showDay": true,
  "fontSize": 32,
  "color": "#FFFFFF",
  "alignment": "center",
  "notificationEnabled": true,
  "floatingBarEnabled": false,
  "unlockedPresets": ["basic1", "basic2"],
  "isPremium": false
}
```

---

## 6. Monetization chi tiết

| Format | Vị trí | Ưu tiên | Điều kiện |
| --- | --- | --- | --- |
| Rewarded Video | Unlock preset/font/màu premium | P0 | User chủ động bấm "Watch" |
| Banner (Adaptive) | Bottom Home/Settings | P0 | Không che Preview trong Editor |
| One-time IAP Remove Ads | Settings | P0 | Tắt toàn bộ ads sau khi mua |
| Interstitial | Sau khi Save config thành công | P2 | Có nút close rõ ràng, không chặn thao tác đang làm dở |
| Ads trên widget/notification/floating bar | — | **Cấm tuyệt đối** | Vi phạm chính sách Google Play |

**Free vs Premium:** Free có đủ widget + notification + 6-8 preset cơ bản + banner. Premium (qua rewarded hoặc IAP) mở thêm preset đẹp, font, floating bar, không quảng cáo. **Không khoá widget/notification cơ bản sau paywall** — đây là lý do chính user cài app.

---

## 7. Implementation Plan (8 ngày)

| Ngày | Công việc |
| --- | --- |
| 0 (nửa ngày, trước khi bắt đầu) | Prototype test notification icon + floating bar thật trên máy Android — xác nhận hình dạng thực tế |
| 1 | Flutter project + kiến trúc + models + storage + Home UI skeleton |
| 2 | Clock engine: time/date/day, format, 12/24h, timezone, live preview |
| 3 | Editor UI + preset + customization + save |
| 4 | Home-screen widget: AppWidgetProvider + MethodChannel + nhiều size |
| 5 | Notification icon service + BootReceiver + edge case (reboot, screen on/off) |
| 6 | AdMob (Banner + Rewarded) + unlock logic + IAP Remove Ads |
| 7 | Floating Bar (P1, optional) — ForegroundService + permission flow + onboarding giải thích rõ đây không phải sửa status bar hệ thống |
| 8 | QA đa máy (Pixel, Samsung, Xiaomi), Android 12–16, dark mode, font scale, battery optimization, policy self-check |

---

## 8. Acceptance Criteria

- [ ] Widget hiển thị đúng time/date/day, tự cập nhật theo thời gian thực, sống sót qua reboot
- [ ] Notification icon hiển thị và cập nhật đúng (đã test thực tế hình dạng, không dựa mockup)
- [ ] Config thay đổi trong Editor phản ánh ngay trong Preview, Widget, Notification trong vòng vài giây
- [ ] Rewarded Video unlock đúng preset đã chọn, lưu trạng thái bền vững qua restart app
- [ ] IAP Remove Ads tắt toàn bộ banner/rewarded prompt vĩnh viễn
- [ ] Không có bất kỳ AdMob nào xuất hiện trên Widget/Notification/Floating Bar
- [ ] Floating Bar (nếu bật) không chồng lên status bar thật, không chặn thao tác vuốt notification
- [ ] Onboarding giải thích đúng bản chất kỹ thuật, không hứa "sửa status bar Samsung 100%"
- [ ] App hoạt động offline hoàn toàn (trừ tải quảng cáo)
- [ ] Test pass trên Android 12, 13, 14, 15, 16 và tối thiểu 3 dòng máy (Pixel, Samsung, Xiaomi)

## 9. Test Cases chính

1. Đổi format ngày → widget cập nhật đúng trong < 5s.
2. Reboot máy → widget + notification tự khởi động lại không cần mở app.
3. Tắt màn hình 10 phút → mở lại → thời gian hiển thị đúng (không lệch do sleep).
4. Đổi timezone hệ thống → app cập nhật theo, không cần restart app.
5. Bấm "Watch ad to unlock" → mất mạng giữa chừng → không bị mất trạng thái, không bị unlock giả.
6. Mua IAP Remove Ads → khởi động lại app → vẫn không có ads.
7. Từ chối quyền notification → app vẫn dùng được đầy đủ widget.
8. Bật Floating Bar trên máy Android 15 → kiểm tra không bị crash do giới hạn foreground-service-from-background.
9. Widget resize (2x1 → 4x2) → nội dung tự co giãn hợp lý, không vỡ layout.
10. Uninstall → reinstall → không còn dữ liệu cũ trên máy (đúng hành vi offline).

## 10. Rủi ro & Mitigation

| Rủi ro | Mitigation |
| --- | --- |
| Floating Bar không ổn định / bị OS kill | Ưu tiên Notification + Widget làm nền tảng chính; Floating Bar chỉ optional |
| Notification icon không hiện được text dài như kỳ vọng | Xác nhận sớm bằng prototype (ngày 0), điều chỉnh copy/ASO cho khớp thực tế |
| Hao pin | Chỉ update khi `ACTION_SCREEN_ON`; dùng `AlarmManager`/`WorkManager` nhẹ thay vì loop liên tục |
| User từ chối quyền overlay | App vẫn dùng được 100% với widget + notification, không ép |
| Policy Google Play về ads | Zero ads ngoài app; rewarded chỉ trong UI; interstitial rất hạn chế |
| Android 15 giới hạn foreground service từ background | Đảm bảo overlay window visible trước khi start service, xử lý đúng luồng cho phép |
| Review 1 sao vì "không giống status bar Samsung" | Copy/ASO/onboarding nói đúng bản chất, không phóng đại |

## 11. Metrics cần đo từ beta

`app_open`, `widget_added`, `notification_enabled`, `floating_bar_enabled`, `preset_selected`, `rewarded_watched`, `iap_purchase`, `ad_impression`, D1, D7, uninstall rate sau 24h/7 ngày.

**Kill criteria (sau 1.000 install):** widget/notification activation < 15% → xem lại onboarding; D1 < 12% → vấn đề value proposition; review liên tục than phiền "không giống status bar Samsung" → dừng acquisition, sửa lại copy/ASO trước khi tiếp tục.

---

## 12. Thứ tự prompt cho coding agent (gợi ý)

1. "Tạo Flutter project theo cấu trúc mục 5, models + storage_service theo schema mục 5, chưa cần UI thật."
2. "Xây Home screen + live preview theo wireframe mục 3, dùng model đã có."
3. "Xây Editor screen: format selector, font/color/alignment, save vào storage_service."
4. "Viết Android native AppWidgetProvider cho 4 size, kết nối qua MethodChannel với widget_bridge.dart."
5. "Viết NotificationIconService cập nhật icon theo config, cộng BootReceiver."
6. "Tích hợp google_mobile_ads: Banner ở Home/Settings, Rewarded unlock preset theo flow 3 mục 2."
7. "Tích hợp in_app_purchase cho Remove Ads, theo flow 4 mục 2."
8. "(P1) Viết FloatingBarService — ForegroundService + TYPE_APPLICATION_OVERLAY, đặt ngay dưới status bar, xin permission SYSTEM_ALERT_WINDOW với onboarding rõ ràng."
9. "Chạy qua toàn bộ test case mục 9, fix lỗi trên các máy Pixel/Samsung/Xiaomi, Android 12–16."

Agent không được tự thêm feature ngoài danh sách P0/P1/P2 ở mục 4 nếu không được yêu cầu rõ.