# Preset Model

## Purpose

Data class representing a visual preset that bundles a display name, description, and a ClockConfig. Presets are identified by a unique string ID. Some presets are locked and require a rewarded ad watch or premium purchase to unlock.

## Requirements

### R1: Preset fields

A Preset has exactly 5 fields:

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `id` | `String` | yes | — | Unique identifier (e.g. `"basic1"`, `"premium1"`) |
| `name` | `String` | yes | — | Display name shown in UI |
| `description` | `String` | no | `''` | Short description of the preset style |
| `config` | `ClockConfig` | yes | — | The clock configuration for this preset |
| `isLocked` | `bool` | no | `false` | Whether preset requires unlocking |

**Scenario: Full construction**
- Given `Preset(id: 'basic1', name: 'Classic White', description: 'Clean', config: ClockConfig(color: '#FFFFFF'))`
- Then `id == 'basic1'`, `name == 'Classic White'`, `isLocked == false`
- Reference: `lib/models/preset.dart:14-20`

**Scenario: Default isLocked is false**
- Given `Preset(id: 'x', name: 'X', config: ClockConfig())`
- Then `isLocked == false`
- Reference: `lib/models/preset.dart:20`

### R2: JSON serialization

Preset supports `fromJson` / `toJson` round-trip.

**Scenario: toJson produces correct structure**
- Given a Preset with `id: 'basic2'`, `name: 'Modern Black'`, `config: ClockConfig()`
- When `toJson()` is called
- Then the result contains keys: `id`, `name`, `description`, `config` (nested JSON map), `isLocked`
- Reference: `lib/models/preset.dart:38-45`

**Scenario: fromJson round-trips**
- Given a Preset instance
- When `Preset.fromJson(preset.toJson())` is called
- Then the result equals the original (via `==`)
- Reference: `lib/models/preset.dart:27-34`

### R3: Value equality

Two Presets are equal if `id`, `name`, and `config` match. The `description` and `isLocked` fields are NOT compared in `==`.

**Scenario: Same id, name, config → equal**
- Given `a = Preset(id: 'x', name: 'X', config: c, description: 'd1', isLocked: true)`
- And `b = Preset(id: 'x', name: 'X', config: c, description: 'd2', isLocked: false)`
- Then `a == b` is `true`

**Scenario: Different id → not equal**
- Given `a = Preset(id: 'x', name: 'X', config: c)`
- And `b = Preset(id: 'y', name: 'X', config: c)`
- Then `a == b` is `false`
- Reference: `lib/models/preset.dart:47-55`

## Need to clear

1. **Equality ignores `description` and `isLocked`** — two presets with the same id/name/config but different descriptions are considered equal. This seems intentional (equality used for matching current config to a preset in PresetsScreen) but may be surprising.
