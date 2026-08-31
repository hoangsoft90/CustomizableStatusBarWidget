# RewardState Model

## Purpose

Immutable data model tracking daily reward entitlement: how many rewarded ads the user has watched today and which presets they've unlocked for today's use. Persisted separately from ClockConfig in SharedPreferences under key `"reward_state"`.

Created in plan3_final.md Task B to replace the permanent `unlockedPresets` field in ClockConfig.

## Requirements

### R1: 3-field model

RewardState holds exactly 3 named fields:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `date` | `String` | (required) | Local date string `yyyy-MM-dd` when state was last reset |
| `unlockCount` | `int` | `0` | Number of rewarded ads watched today (max 2) |
| `unlockedToday` | `List<String>` | `const []` | Preset IDs unlocked for today's use |

**Scenario: Empty construction**
- Given `RewardState.empty('2026-08-30')`
- Then `date == '2026-08-30'`, `unlockCount == 0`, `unlockedToday == []`
- Reference: `lib/models/reward_state.dart:22`

### R2: JSON serialization round-trip

RewardState can be serialized to JSON and deserialized back with lossless round-trip.

**Scenario: toJson produces correct keys**
- Given a RewardState with `date: '2026-08-30'`, `unlockCount: 1`, `unlockedToday: ['premium1']`
- When `toJson()` is called
- Then the map contains keys `date`, `unlockCount`, `unlockedToday`
- Reference: `lib/models/reward_state.dart:40-47`

**Scenario: fromJsonString round-trips**
- Given a RewardState instance
- When `fromJsonString(state.toJsonString())` is called
- Then the result equals the original
- Reference: `lib/models/reward_state.dart:50-52`

**Scenario: fromJson tolerates missing fields**
- Given a JSON map with only `"date": "2026-08-30"`
- When `RewardState.fromJson(json)` is called
- Then `unlockCount` defaults to `0` and `unlockedToday` defaults to `[]`
- Reference: `lib/models/reward_state.dart:30-36`

### R3: copyWith for selective mutation

`copyWith` returns a new instance with only specified fields overridden.

**Scenario: Single field override**
- Given `RewardState.empty('2026-08-30')`
- When `copyWith(unlockCount: 1, unlockedToday: ['premium1'])` is called
- Then `date` remains `'2026-08-30'`, `unlockCount == 1`, `unlockedToday == ['premium1']`
- Reference: `lib/models/reward_state.dart:54-64`

### R4: Value equality

Two RewardState instances are equal if and only if all 3 fields match. `unlockedToday` list is compared element-by-element.

**Scenario: Identical states are equal**
- Given two RewardState with same date, count, and list
- Then `a == b` is `true`
- Reference: `lib/models/reward_state.dart:66-73`

**Scenario: Different count**
- Given `a = RewardState(date: '2026-08-30', unlockCount: 0)` and `b` with `unlockCount: 1`
- Then `a == b` is `false`
- Reference: `lib/models/reward_state.dart:66-73`
