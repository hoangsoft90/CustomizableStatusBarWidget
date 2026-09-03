# AI Rules for This Project

## Scope Rules

1. **KHÔNG thêm feature ngoài plan.** Mọi tính năng mới phải được user approve trước khi code.
2. **KHÔNG đổi product positioning.** Không thêm "weather", "calendar", "alarm" dù có vẻ hữu ích.
3. **KHÔNG đặt ads lên Widget / Notification / Floating Bar.** Đây là Google Play policy violation.
4. **KHÔNG build APK trên local.** Luôn push code lên GitHub Actions để build.
5. **KHÔNG sửa code khi đang viết docs.** Nếu thấy bug trong lúc đọc code, ghi vào "Cần làm rõ" trong spec, không tự sửa.

## Code Rules

6. **Whitelist packages only.** Chỉ dùng: `shared_preferences`, `google_mobile_ads`, `in_app_purchase`, `flutter_local_notifications`, `permission_handler`, `image_picker`, `image_cropper`, `path_provider`, `share_plus`, `sentry_flutter`.
7. **No state management libraries.** Dùng `setState` — app quá nhỏ cho Riverpod/Bloc.
8. **No code generation.** JSON serialization thủ công, không dùng `json_serializable`.
9. **Config sync là one-direction.** Flutter → Native qua MethodChannel. Native KHÔNG tự gọi lại Flutter.
10. **ClockConfig là source of truth.** Mọi display layer đọc từ cùng 1 config.

## Native Rules

11. **Kotlin files each have own ClockData.** tech debt đã known, KHÔNG refactor trừ khi user yêu cầu.
12. **parseClockData uses regex.** Chấp nhận vì config flat. KHÔNG thêm JSON parser library.
13. **In-place update cho FloatingBar.** KHÔNG stop/start service chỉ để update text.
14. **TimeTickService uses ACTION_TIME_TICK.** KHÔNG dùng AlarmManager/Handler cho tick.
15. **BootReceiver restarts services.** Kiểm tra `isEnabled()` trước khi start.

## Widget Background Rules (plan6-9)

16. **Bitmap thay vì URI + Binder budget (plan9).** Dùng `setImageViewBitmap` + `inSampleSize` + **400px max side** + **hard cap ~400KB raw** (vòng scale 85% khi width×height×4 > 400_000). KHÔNG dùng `setImageViewUri` + `FileProvider`. Đừng quay lại 480/800 — TransactionTooLargeException crash widget host (plan9).
16b. **Mọi dimension scale phải `coerceAtLeast(1)`.** Ảnh méo cực hiếm (width=1) có thể ra 0-dim → `createScaledBitmap` throw. Clamp cả 2 chiều ở cả nhánh scale lẫn vòng hard-cap.
17. **Resize KHÔNG xóa background.** `onAppWidgetOptionsChanged` chỉ gọi `renderWidget()`, KHÔNG remove SharedPreferences key.
18. **Text shadow thay vì overlay.** `shadowColor="#AA000000"` trên TextViews, KHÔNG dùng `#59000000` overlay trên LinearLayout.
19. **Cache-busting bằng timestamp.** Filename `bg_{millis}.png`, cleanup file cũ best-effort.
20. **Background shared prefs namespace.** Dùng `widget_background` với key `bg_bitmap_path`, KHÔNG dùng per-widgetId keys.

## Ad Rules (plan8)

21. **enableAds = true (production).** Master switch bật ads thật. `testAds = false` dùng production IDs.
22. **Ads disabled = all methods short-circuit.** Khi `enableAds == false`, mọi method trong AdsService return immediately.

## Test Rules

23. **91 tests minimum.** Không giảm số lượng test.
24. **Test cho migration.** Legacy JSON (showSeconds, unlockedPresets) phải load được không crash.
25. **Test cho RewardService.** Reset qua ngày, limit 2/day, idempotent unlock.
26. **Device testing required.** Notification icon, floating bar, widget phải test trên máy thật.

## Build Rules

27. **GitHub Actions only.** Workflow: checkout → Java 17 → Flutter → pub get → analyze → test → build apk --debug → upload artifact.
28. **targetSdk = 36.** Google Play requirement từ 31/8/2026.
29. **Core library desugaring enabled.** Required by `flutter_local_notifications`.
30. **XML entities.** `&` trong AndroidManifest phải escape thành `&amp;`.
31. **Release keystore fixed.** `photoclock-release.jks`, alias `photoclock`, pass `83793900`. KHÔNG thay đổi giữa các lần build. Lưu trong GH Secret `KEYSTORE_BASE64`.
32. **R8 disabled for release.** `isMinifyEnabled = false`, `isShrinkResources = false`. Flutter deferred components chưa tương thích R8 → crash.
33. **Release signing config.** `build.gradle.kts` đọc từ env vars: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`. Decode base64 →写入 /tmp/release.jks tại build time.
34. **Two workflows.** `build-debug-apk.yml` (debug, unsigned) + `build-release-aab.yml` (release, signed). Cả 2 trigger on push to main.

## Naming Rules

35. **Package ID:** `io.photoclock.widget` (đã đổi từ `com.example.date_time_widget`).
36. **SharedPreferences keys:** `clock_config`, `reward_state`, `notification_enabled`, `floatingBarEnabled`, `widget_background/bg_bitmap_path`, `status_bar_config/clock_config`.
37. **MethodChannel names:** `io.photoclock.widget/<service>` (widgets, notification, floating_bar, deep_link).
38. **Notification channels:** `date_time_icon` (notif), `floating_bar` (overlay).
39. **Sentry DSN:** `https://804452b03a096aa2c383654938dd213c@o4505474077753344.ingest.us.sentry.io/4512003956015104`
40. **GH Secrets:** `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD` — keystore release signing.

## Widget Host Crash Rules (plan9 P0)

41. **IPC guard cho widget update.** Mọi `mgr.updateAppWidget()` bọc try/catch `Log.e(TAG, ...)`; build RemoteViews cũng chạy trong guard (renderWidget → renderWidgetInner). Transaction fail KHÔNG được crash widget host / abort vòng onUpdate.
42. **Log tag 1/file = tên class.** Native dùng `private const val TAG = "DateTimeWidgetProvider"` + `Log.e(TAG, ...)`. KHÔNG dùng nhiều tag chuỗi cứng khác nhau trong cùng file (logcat lọc 1 tag là đủ).
