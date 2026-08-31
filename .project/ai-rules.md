# AI Rules for This Project

## Scope Rules

1. **KHÔNG thêm feature ngoài plan.** Mọi tính năng mới phải được user approve trước khi code.
2. **KHÔNG đổi product positioning.** Không thêm "weather", "calendar", "alarm" dù có vẻ hữu ích.
3. **KHÔNG đặt ads lên Widget / Notification / Floating Bar.** Đây là Google Play policy violation.
4. **KHÔNG build APK trên local.** Luôn push code lên GitHub Actions để build.
5. **KHÔNG sửa code khi đang viết docs.** Nếu thấy bug trong lúc đọc code, ghi vào "Cần làm rõ" trong spec, không tự sửa.

## Code Rules

6. **Whitelist packages only.** Chỉ dùng: `shared_preferences`, `google_mobile_ads`, `in_app_purchase`, `flutter_local_notifications`, `permission_handler`.
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

## Test Rules

16. **91 tests minimum.** Không giảm số lượng test.
17. **Test cho migration.** Legacy JSON (showSeconds, unlockedPresets) phải load được không crash.
18. **Test cho RewardService.** Reset qua ngày, limit 2/day, idempotent unlock.
19. **Device testing required.** Notification icon, floating bar, widget phải test trên máy thật.

## Build Rules

20. **GitHub Actions only.** Workflow: checkout → Java 17 → Flutter → pub get → analyze → test → build apk --debug → upload artifact.
21. **targetSdk = 36.** Google Play requirement từ 31/8/2026.
22. **Core library desugaring enabled.** Required by `flutter_local_notifications`.
23. **XML entities.** `&` trong AndroidManifest phải escape thành `&amp;`.

## Naming Rules

24. **Package ID:** `com.example.date_time_widget` (tạm, sẽ đổi trước khi release).
25. **SharedPreferences keys:** `clock_config`, `reward_state`, `notification_enabled`, `floatingBarEnabled`.
26. **MethodChannel names:** `com.example.date_time_widget/<service>`.
27. **Notification channels:** `date_time_icon` (notif), `floating_bar` (overlay).
