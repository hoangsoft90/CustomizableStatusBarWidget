# LocalStorage (SharedPreferences)

## Purpose

Persists ClockConfig and app-level state locally using `shared_preferences`. No backend, no cloud sync — all data stays on-device. Single entry point for all Flutter-side config reads/writes.

## Requirements

### R1: Singleton creation

`StorageService.create()` initializes SharedPreferences once and returns a StorageService instance.

**Scenario: create returns initialized service**
- When `StorageService.create()` is awaited
- Then the returned instance has a non-null `prefs` getter
- Reference: `lib/services/storage_service.dart:16-19`

### R2: loadConfig returns saved config or defaults

`loadConfig()` reads from SharedPreferences key `'clock_config'`. If nothing is saved, returns `ClockConfig.defaults()`.

**Scenario: First launch — no saved config**
- Given SharedPreferences has no `'clock_config'` key
- When `storage.loadConfig()` is called
- Then the result equals `ClockConfig.defaults()`
- Reference: `lib/services/storage_service.dart:27-33`

**Scenario: Saved config is loaded**
- Given a ClockConfig with `fontSize: 48` was previously saved
- When `storage.loadConfig()` is called
- Then `config.fontSize == 48`
- Reference: `lib/services/storage_service.dart:27-33`

**Scenario: Corrupted JSON falls back to defaults**
- Given SharedPreferences has `'clock_config'` set to `"not valid json"`
- When `storage.loadConfig()` is called
- Then the result equals `ClockConfig.defaults()` (catch block)
- Reference: `lib/services/storage_service.dart:31-33`

### R3: saveConfig persists config

`saveConfig(config)` serializes the config to JSON string and stores it under `'clock_config'`.

**Scenario: Round-trip save/load**
- Given a ClockConfig with `format: 'dd/MM/yyyy'`, `color: '#FF5722'`
- When `saveConfig(config)` is awaited, then `loadConfig()` is called
- Then the loaded config equals the saved config
- Reference: `lib/services/storage_service.dart:36-38`

### R4: clearAll removes all data

`clearAll()` delegates to `SharedPreferences.clear()`.

**Scenario: After clearAll, loadConfig returns defaults**
- Given a config was previously saved
- When `clearAll()` is awaited, then `loadConfig()` is called
- Then the result equals `ClockConfig.defaults()`
- Reference: `lib/services/storage_service.dart:41`

### R5: Raw prefs access

The `prefs` getter exposes the underlying SharedPreferences for edge cases (e.g., Settings screen reading `notificationEnabled` bool directly).

**Scenario: Direct prefs read**
- Given `storage.prefs.getBool('notificationEnabled')`
- Then the value is read directly from SharedPreferences, bypassing ClockConfig
- Reference: `lib/services/storage_service.dart:44`
