# Utils & Tests

## DateFormatter (`lib/utils/date_formatter.dart`)

Custom date/time/day formatting without external libraries.

**Methods:**
- `formatTime(DateTime, ClockConfig)` → `String` — replaces HH, hh, mm, a tokens
- `formatDate(DateTime, ClockConfig)` → `String` — replaces yyyy, MM, dd, EEEE tokens
- `formatDay(DateTime, ClockConfig)` → `String` — full/short/uppercase day name
- `buildDisplay(DateTime, ClockConfig)` → `ClockDisplay` — composes all three lines

**Supported time formats:** `HH:mm` (24h), `hh:mm a` (12h only). No seconds.

**Edge case:** `formatTime` replaces ALL `a` characters — if format contains literal "a", it's incorrectly replaced. Known limitation.

## AppConstants (`lib/utils/constants.dart`)

Centralized configuration for ads and IAP.

```dart
class AppConstants {
  static const bool testAds = true;  // ← flip to false for production
  
  static String get bannerAdUnitId => testAds ? _testBannerId : _prodBannerId;
  static String get rewardedAdUnitId => testAds ? _testRewardedId : _prodRewardedId;
  static const String iapProductId = 'remove_ads_unlock_all';
}
```

**Production ad IDs:** Currently placeholders `XXXXXXXXXX`. Must be replaced before release.

## Test Suite (91 tests)

| Test File | Tests | Coverage |
|-----------|-------|----------|
| `plan2_fixes_test.dart` | 32 | plan2 fixes + plan3 Task A/B |
| `date_formatter_test.dart` | 14 | Time/date/day formatting |
| `storage_service_test.dart` | 5 | SharedPreferences CRUD |
| `editor_config_test.dart` | 6 | copyWith + serialization |
| `notification_config_test.dart` | 5 | notificationEnabled state |
| `floating_bar_config_test.dart` | 5 | floatingBarEnabled state |
| `reward_service_test.dart` | 15 | Daily reward logic |
| `iap_premium_test.dart` | 8 | RewardState + isPremium |
| `widget_test.dart` | 1 | Placeholder |

**Key test scenarios:**
- Legacy JSON migration (showSeconds, unlockedPresets)
- normalizeTimeFormat (HH:mm:ss → HH:mm)
- RewardService daily reset, limit 2/day, idempotent unlock
- ClockConfig JSON roundtrip
- All 3 native ClockData parseClockData equivalence

**Running tests:**
```bash
cd date_time_widget && flutter test
```
