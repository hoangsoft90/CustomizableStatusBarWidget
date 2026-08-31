import 'package:shared_preferences/shared_preferences.dart';

import '../models/reward_state.dart';

/// Manages daily reward entitlement for preset unlocking.
///
/// Business rules:
/// - Free presets: always usable (no ad needed).
/// - Premium users: always usable (IAP).
/// - Locked presets: require watching a rewarded ad, max 2 per day.
/// - Resets automatically at midnight (local calendar).
class RewardService {
  static const _prefsKey = 'reward_state';
  static const int maxDailyUnlocks = 2;

  final SharedPreferences _prefs;

  RewardService(this._prefs);

  /// Load current state from SharedPreferences.
  RewardState _loadState() {
    final json = _prefs.getString(_prefsKey);
    if (json == null) return RewardState.empty(_today());
    return RewardState.fromJsonString(json);
  }

  /// Save state to SharedPreferences.
  Future<void> _saveState(RewardState state) async {
    await _prefs.setString(_prefsKey, state.toJsonString());
  }

  /// Get today's date string (yyyy-MM-dd) using local calendar.
  String _today() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Reset state if it's a new day. Safe to call multiple times.
  Future<void> resetIfNewDay() async {
    final state = _loadState();
    final today = _today();
    if (state.date != today) {
      await _saveState(RewardState.empty(today));
    }
  }

  /// Whether [presetId] can be used right now.
  ///
  /// - Free presets (`isFreePreset == true`): always true.
  /// - Premium users (`isPremium == true`): always true.
  /// - Already unlocked today: true.
  /// - Remaining unlocks available but NOT yet unlocked: false (ad must be watched).
  /// - No remaining unlocks: false.
  bool canUsePreset(String presetId,
      {required bool isPremium, required bool isFreePreset}) {
    if (isFreePreset) return true;
    if (isPremium) return true;

    final state = _loadState();
    return state.unlockedToday.contains(presetId);
  }

  /// Number of ad unlocks remaining today.
  int remainingUnlocksToday() {
    final state = _loadState();
    return (maxDailyUnlocks - state.unlockCount).clamp(0, maxDailyUnlocks);
  }

  /// Record that the user watched an ad to unlock [presetId] today.
  ///
  /// Reads fresh state from storage (no stale writes).
  /// Returns `true` if unlock was recorded, `false` if no remaining unlocks.
  Future<bool> unlockToday(String presetId) async {
    final today = _today();
    var state = _loadState();

    // Reset if new day
    if (state.date != today) {
      state = RewardState.empty(today);
    }

    // Check limit
    if (state.unlockCount >= maxDailyUnlocks) return false;

    // Already unlocked today?
    if (state.unlockedToday.contains(presetId)) return true;

    // Record unlock
    final updated = state.copyWith(
      unlockCount: state.unlockCount + 1,
      unlockedToday: [...state.unlockedToday, presetId],
    );
    await _saveState(updated);
    return true;
  }
}
