# Reward Service

## Purpose

Manages daily reward entitlement for preset unlocking. Replaces the permanent `unlockedPresets` mechanism from ClockConfig. Business rules: free presets always usable, premium always usable, locked presets require watching a rewarded ad (max 2/day), resets at midnight.

Created in plan3_final.md Task B.

## Requirements

### R1: resetIfNewDay

Checks if the stored state date differs from today. If so, resets to empty state. Safe to call multiple times.

**Scenario: Resets on new day**
- Given stored state has `date: '2026-08-29'` (yesterday)
- When `resetIfNewDay()` is called on 2026-08-30
- Then state is reset to `RewardState.empty('2026-08-30')`
- And `remainingUnlocksToday() == 2`
- Reference: `lib/services/reward_service.dart:35-41`

**Scenario: No reset on same day**
- Given stored state has `date: '2026-08-30'` (today)
- When `resetIfNewDay()` is called
- Then state is unchanged
- And `remainingUnlocksToday()` reflects the stored count
- Reference: `lib/services/reward_service.dart:35-41`

### R2: canUsePreset

Determines if a preset can be used right now based on business rules.

**Scenario: Free preset always true**
- Given `isFreePreset == true`
- When `canUsePreset` is called
- Then it returns `true` regardless of other state
- Reference: `lib/services/reward_service.dart:47-48`

**Scenario: Premium always true**
- Given `isPremium == true`
- When `canUsePreset` is called
- Then it returns `true` regardless of other state
- Reference: `lib/services/reward_service.dart:49`

**Scenario: Already unlocked today**
- Given `presetId` is in `unlockedToday`
- When `canUsePreset` is called
- Then it returns `true`
- Reference: `lib/services/reward_service.dart:53`

**Scenario: Remaining unlocks available**
- Given `unlockCount < 2` and preset not in `unlockedToday`
- When `canUsePreset` is called
- Then it returns `true` (ad will be shown to unlock)
- Reference: `lib/services/reward_service.dart:55`

**Scenario: No remaining unlocks**
- Given `unlockCount >= 2` and preset not in `unlockedToday`
- When `canUsePreset` is called
- Then it returns `false`
- Reference: `lib/services/reward_service.dart:55`

### R3: remainingUnlocksToday

Returns `maxDailyUnlocks - unlockCount`, clamped to `[0, 2]`.

**Scenario: Fresh day**
- Given `unlockCount == 0`
- When `remainingUnlocksToday()` is called
- Then result is `2`
- Reference: `lib/services/reward_service.dart:58-60`

**Scenario: After one unlock**
- Given `unlockCount == 1`
- When `remainingUnlocksToday()` is called
- Then result is `1`
- Reference: `lib/services/reward_service.dart:58-60`

**Scenario: At limit**
- Given `unlockCount == 2`
- When `remainingUnlocksToday()` is called
- Then result is `0`
- Reference: `lib/services/reward_service.dart:58-60`

### R4: unlockToday

Records that the user watched an ad to unlock a preset today. Reads fresh state from SharedPreferences (no stale writes). Idempotent — if already unlocked today, returns `true` without incrementing count.

**Scenario: Successful unlock**
- Given `unlockCount == 0` and `presetId` not in `unlockedToday`
- When `unlockToday('premium1')` is called
- Then `unlockCount` becomes `1`
- And `unlockedToday` contains `'premium1'`
- And the method returns `true`
- Reference: `lib/services/reward_service.dart:66-80`

**Scenario: Idempotent — already unlocked**
- Given `unlockCount == 1` and `'premium1'` already in `unlockedToday`
- When `unlockToday('premium1')` is called again
- Then `unlockCount` remains `1` (not incremented)
- And the method returns `true`
- Reference: `lib/services/reward_service.dart:72-73`

**Scenario: At limit**
- Given `unlockCount == 2`
- When `unlockToday('premium3')` is called
- Then the method returns `false`
- And state is unchanged
- Reference: `lib/services/reward_service.dart:69-70`

**Scenario: Auto-resets on new day**
- Given stored state from yesterday with `unlockCount: 2`
- When `unlockToday('premium1')` is called
- Then state is auto-reset to today's empty state first
- And the unlock succeeds with `unlockCount: 1`
- Reference: `lib/services/reward_service.dart:66-70`

### R5: Persistence

State is stored in SharedPreferences under key `"reward_state"` as JSON string. Each `unlockToday` call writes the updated state immediately.

**Scenario: State persists across app restarts**
- Given user unlocked 1 preset today
- When app is restarted
- Then `remainingUnlocksToday()` returns `1`
- And `canUsePreset` for the unlocked preset returns `true`
- Reference: `lib/services/reward_service.dart:24-30`

### R6: maxDailyUnlocks constant

`maxDailyUnlocks` is `2` — the maximum number of rewarded ad unlocks per day.

**Scenario: Constant value**
- Given `RewardService.maxDailyUnlocks`
- Then the value is `2`
- Reference: `lib/services/reward_service.dart:14`
