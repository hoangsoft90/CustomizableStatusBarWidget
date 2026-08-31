# Operating Rules — Date & Time Widget

> Rules riêng của project này. Không lặp lại nội dung từ AGENTS.md.

## Scope Rules

1. **KHÔNG thêm feature ngoài plan.** Mọi tính năng mới phải có plan.md tương ứng trước khi code.
2. **KHÔNG đổi product positioning.** Không thêm weather/calendar/alarm dù có vẻ hữu ích.
3. **KHÔNG tự ý mở scope.** Nếu phát hiện bug ngoài plan, ghi vào working.md hoặc spec "Cần làm rõ", không tự fix.
4. **KHÔNG refactor lớn khi chưa được yêu cầu.** ClockData duplication là known tech debt, chấp nhận.

## Code Rules

5. **Whitelist packages ONLY:** shared_preferences, google_mobile_ads, in_app_purchase, flutter_local_notifications, permission_handler. Không thêm package khác without user approval.
6. **No state management library.** setState() là đủ cho app này.
7. **No code generation.** JSON serialize thủ công, không json_serializable/freezed.
8. **ClockConfig = source of truth.** Mọi display layer đọc từ cùng 1 config.
9. **Config sync one-direction.** Flutter → Native. Native KHÔNG tự gọi lại Flutter.

## Native Rules

10. **parseClockData uses regex.** Chấp nhận vì config flat. Không thêm JSON parser library.
11. **Each native file has own ClockData.** Known DRY violation. Không refactor trừ khi user yêu cầu.
12. **In-place overlay update.** Không stop/start FloatingBarService chỉ để update text.
13. **ACTION_TIME_TICK only.** Không AlarmManager/Handler cho tick updates.

## Test Rules

14. **91 tests minimum.** Không giảm. Thêm feature phải thêm test.
15. **Test legacy migration.** JSON cũ (showSeconds, unlockedPresets) phải load được không crash.
16. **Device testing cho native.** Notification icon, floating bar, widget phải test trên máy thật.

## Build Rules

17. **GitHub Actions ONLY.** KHÔNG build APK local (lack of disk space).
18. **targetSdk = 36.** Google Play requirement từ 31/8/2026.
19. **Core library desugaring = true.** Required by flutter_local_notifications.
20. **XML escape.** `&` trong AndroidManifest → `&amp;`.

## Monetization Rules

21. **TUYỆT ĐỐI KHÔNG ads trên Widget/Notification/FloatingBar.** Google Play policy violation.
22. **testAds = true ở dev.** Flip sang false trước khi release.
23. **Production ad IDs = placeholder.** Phải thay trước khi upload lên Play Console.

## Git Rules

24. **Commit message tiếng Anh, concise.** format: `<type>: <description>`
25. **KHÔNG push without user permission.** Commit được, push phải được confirm.
26. **KHÔNG force push.** Không rebase/reset mà chưa có xác nhận.

## Naming Rules

27. **Package ID:** `com.example.date_time_widget` (tạm, đổi trước release).
28. **SharedPreferences keys:** `clock_config`, `reward_state`, `flutter.notification_enabled`, `flutter.floatingBarEnabled`.
29. **MethodChannel:** `com.example.date_time_widget/<service>`.
30. **Notification channels:** `date_time_icon`, `floating_bar`.
