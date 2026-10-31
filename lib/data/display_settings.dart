import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/app_colour.dart';
import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/data/saved_set.dart';
import 'package:prayer_times/data/saved_setting.dart';
import 'package:prayer_times/data/timetable.dart';

/// The display choices from the Display page, kept together so they travel
/// through the app as one. Each is listened to on its own.
class DisplaySettings {
  /// Unsaved choices that start as the app looks today (for tests).
  DisplaySettings({
    ValueNotifier<ThemeMode>? themeMode,
    ValueNotifier<AppColour>? colour,
    ValueNotifier<ClockFormat>? clock,
    ValueNotifier<Set<Prayer>>? hiddenTimes,
  }) : themeMode = themeMode ?? ValueNotifier(ThemeMode.system),
       colour = colour ?? ValueNotifier(AppColour.teal),
       clock = clock ?? ValueNotifier(ClockFormat.phone),
       hiddenTimes = hiddenTimes ?? ValueNotifier(const {});

  /// The choices saved on the phone. Never rename these keys.
  factory DisplaySettings.saved(SharedPreferences storage) => DisplaySettings(
    themeMode: SavedSetting(
      storage,
      key: 'themeMode',
      values: ThemeMode.values,
      fallback: ThemeMode.system,
    ),
    colour: SavedSetting(
      storage,
      key: 'appColour',
      values: AppColour.values,
      fallback: AppColour.teal,
    ),
    clock: SavedSetting(
      storage,
      key: 'clockFormat',
      values: ClockFormat.values,
      fallback: ClockFormat.phone,
    ),
    hiddenTimes: SavedSet(storage, key: 'hiddenTimes', values: Prayer.values),
  );

  /// Light, dark, or as the phone.
  final ValueNotifier<ThemeMode> themeMode;
  final ValueNotifier<AppColour> colour;

  /// 12- or 24-hour times, or as the phone.
  final ValueNotifier<ClockFormat> clock;

  /// Times left out of the list and the widgets (still counted down to).
  final ValueNotifier<Set<Prayer>> hiddenTimes;
}
