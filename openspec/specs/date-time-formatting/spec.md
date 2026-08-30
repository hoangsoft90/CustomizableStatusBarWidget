# Date/Time Formatting

## Purpose

Custom date, time, and day-of-week formatting using Dart built-in `DateTime` — no external date library. Produces display strings from ClockConfig patterns. Returns a `ClockDisplay` model with three lines: day, date, time.

## Requirements

### R1: formatTime handles 12h and 24h

Replaces `HH` (24h hour), `hh` (12h hour), `mm` (minute), `ss` (second), `a` (AM/PM) in the `timeFormat` string.

**Scenario: 24h format**
- Given `config.timeFormat = 'HH:mm'` and `now = DateTime(2026, 8, 30, 14, 5)`
- When `DateFormatter.formatTime(now, config)` is called
- Then the result is `'14:05'`
- Reference: `lib/utils/date_formatter.dart:12-30`

**Scenario: 12h format with AM**
- Given `config.timeFormat = 'hh:mm a'` and `now = DateTime(2026, 8, 30, 8, 30)`
- When `DateFormatter.formatTime(now, config)` is called
- Then the result is `'08:30 AM'`
- Reference: `lib/utils/date_formatter.dart:12-30`

**Scenario: 12h format midnight**
- Given `config.timeFormat = 'hh:mm a'` and `now = DateTime(2026, 8, 30, 0, 0)`
- When `formatTime` is called
- Then the result is `'12:00 AM'` (hour 0 maps to 12)
- Reference: `lib/utils/date_formatter.dart:16`

**Scenario: showSeconds appends :ss**
- Given `config.timeFormat = 'HH:mm'`, `config.showSeconds = true`, and `now` with second=45
- When `formatTime` is called
- Then the result contains `':45'`
- Reference: `lib/utils/date_formatter.dart:22-24`

**Scenario: showSeconds=false strips :ss**
- Given `config.timeFormat = 'HH:mm:ss'` and `config.showSeconds = false`
- When `formatTime` is called
- Then `:ss` is removed from the output
- Reference: `lib/utils/date_formatter.dart:22-24`

### R2: formatDate uses pattern matching

Formats date using the `format` pattern from ClockConfig, replacing tokens: `yyyy`, `yy`, `MMMM`, `MMM`, `MM`, `dd`, `d`, `EEEE`, `EEE`, `E`.

**Scenario: dd/MM/yyyy pattern**
- Given `config.format = 'dd/MM/yyyy'` and `now = DateTime(2026, 8, 30)`
- When `DateFormatter.formatDate(now, config)` is called
- Then the result is `'30/08/2026'`
- Reference: `lib/utils/date_formatter.dart:95-119`

**Scenario: MMMM full month name**
- Given `config.format = 'MMMM d'` and `now = DateTime(2026, 8, 30)`
- When `formatDate` is called
- Then the result is `'August 30'`
- Reference: `lib/utils/date_formatter.dart:104-106`

**Scenario: No date tokens returns empty**
- Given `config.format = 'HH:mm'` (time-only)
- When `formatDate` is called
- Then the result is `''`
- Reference: `lib/utils/date_formatter.dart:38-41`

### R3: formatDay renders day of week

Returns full or short day name based on format pattern. Uppercase if format contains `EEE`.

**Scenario: Full day name**
- Given `config.showDay = true`, `config.format = 'dd MMM'` (no day tokens), `now = DateTime(2026, 8, 30)` (Sunday)
- When `DateFormatter.formatDay(now, config)` is called
- Then the result is `'Sunday'`
- Reference: `lib/utils/date_formatter.dart:49-70`

**Scenario: Short uppercase day**
- Given `config.format` contains `'EEE'` (checked case-insensitively against uppercase)
- When `formatDay` is called
- Then the result is `'SUN'` (uppercase)
- Reference: `lib/utils/date_formatter.dart:64-67`

**Scenario: showDay=false returns empty**
- Given `config.showDay = false`
- When `formatDay` is called
- Then the result is `''`
- Reference: `lib/utils/date_formatter.dart:57`

**Scenario: Day tokens in format returns empty**
- Given `config.format = 'EEEE, dd MMM'` (contains day tokens)
- When `formatDay` is called
- Then the result is `''` (day is already rendered by `formatDate`)
- Reference: `lib/utils/date_formatter.dart:58-59`

### R4: buildDisplay composes three lines

`buildDisplay` returns a `ClockDisplay(time, day, date)` by combining formatTime, formatDate, and formatDay, handling mixed day+date format strings.

**Scenario: Mixed format (day + date in one string)**
- Given `config.format = 'EEEE, dd MMM'` and `config.showDay = true`
- When `buildDisplay` is called
- Then `display.day == ''` (day included in date line)
- And `display.date` contains the full formatted string (e.g., `'Sunday, 30 Aug'`)
- And `display.time` is the formatted time
- Reference: `lib/utils/date_formatter.dart:78-88`

**Scenario: Day-only format**
- Given `config.format = 'EEEE'` and `config.showDay = true`
- When `buildDisplay` is called
- Then `display.day` contains the day name
- And `display.date == ''`
- Reference: `lib/utils/date_formatter.dart:80-82`

### R5: ClockDisplay data class

`ClockDisplay` has three String fields: `time` (required), `day` (default `''`), `date` (default `''`).

**Scenario: Construction**
- Given `ClockDisplay(time: '14:05', day: 'Sunday', date: '30 Aug')`
- Then all fields are accessible
- Reference: `lib/utils/date_formatter.dart:121-127`

## Need to clear

1. **`formatTime` replaces ALL occurrences of `a` with AM/PM** — if a user custom format contained the letter `a` as literal text (not AM/PM token), it would be incorrectly replaced. Current code does not validate format strings against this edge case.
