import 'clock_config.dart';
import 'preset.dart';

/// Built-in presets. 6 are free, 2 are locked (require rewarded ad or premium).
const List<Preset> builtInPresets = [
  // ── Free presets ──────────────────────────────────────────
  Preset(
    id: 'basic1',
    name: 'Classic White',
    description: 'Clean and minimal — white on transparent.',
    config: ClockConfig(
      format: 'EEE dd MMM',
      timeFormat: 'HH:mm',
      fontSize: 32,
      color: '#FFFFFF',
      alignment: 'center',
    ),
  ),
  Preset(
    id: 'basic2',
    name: 'Modern Black',
    description: 'Sleek black text for light backgrounds.',
    config: ClockConfig(
      format: 'EEE dd MMM',
      timeFormat: 'HH:mm',
      fontSize: 28,
      color: '#000000',
      alignment: 'left',
    ),
  ),
  Preset(
    id: 'basic3',
    name: 'Digital Blue',
    description: 'Cool blue digital clock style.',
    config: ClockConfig(
      format: 'dd/MM/yyyy',
      timeFormat: 'HH:mm',
      fontSize: 30,
      color: '#2196F3',
      alignment: 'center',
    ),
  ),
  Preset(
    id: 'basic4',
    name: 'Warm Gold',
    description: 'Warm golden tone for a cozy feel.',
    config: ClockConfig(
      format: 'EEEE, MMMM d',
      timeFormat: 'hh:mm a',
      fontSize: 26,
      color: '#FFC107',
      alignment: 'left',
    ),
  ),
  Preset(
    id: 'basic5',
    name: 'Compact',
    description: 'Small and tight — fits any widget size.',
    config: ClockConfig(
      format: 'dd MMM',
      timeFormat: 'HH:mm',
      fontSize: 20,
      color: '#9E9E9E',
      alignment: 'center',
    ),
  ),
  Preset(
    id: 'basic6',
    name: 'Date Only',
    description: 'Date and day of week, no time.',
    config: ClockConfig(
      format: 'EEEE, dd MMMM yyyy',
      timeFormat: 'HH:mm',
      showDate: true,
      showDay: true,
      fontSize: 24,
      color: '#FFFFFF',
      alignment: 'center',
    ),
  ),

  // ── Locked presets (require rewarded ad or premium) ───────
  Preset(
    id: 'premium1',
    name: 'Sunset Gradient',
    description: 'Vibrant sunset orange — unlock with a quick ad.',
    config: ClockConfig(
      format: 'EEE dd MMM',
      timeFormat: 'HH:mm',
      fontSize: 34,
      color: '#FF5722',
      alignment: 'center',
    ),
    isLocked: true,
  ),
  Preset(
    id: 'premium2',
    name: 'Neon Green',
    description: 'Eye-catching neon green for dark themes.',
    config: ClockConfig(
      format: 'EEE dd MMM',
      timeFormat: 'HH:mm',
      fontSize: 30,
      color: '#00E676',
      alignment: 'left',
    ),
    isLocked: true,
  ),
];
