import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/saved_setting.dart';
import 'package:prayer_times/data/saved_value.dart';
import 'package:prayer_times/data/timetable.dart';

/// The Custom method's angle limits, in degrees, and their step.
const minCustomAngle = 10.0;
const maxCustomAngle = 20.0;
const minMaghribAngle = 1.0;
const maxMaghribAngle = 7.0;
const angleStep = 0.5;

/// The Custom method's "Isha minutes after sunset" limits, and their step.
const minIshaMinutes = 60;
const maxIshaMinutes = 150;
const ishaMinutesStep = 5;

/// Where Maghrib and Isha start when switched to an angle or minutes: the
/// Jafari Maghrib angle, and the Umm al-Qura Isha.
const startMaghribAngle = 4.0;
const startIshaMinutes = 90;

/// How far the user can move any one time, in minutes, either way.
const maxMinuteChange = 30;

/// Everything on the Prayer calculation page except Asr, as one value.
typedef Calculation = ({
  /// Official timetables where there's one, the method elsewhere. Off: the
  /// method everywhere.
  bool officialFirst,

  /// Null: automatic (Umm al-Qura in Saudi Arabia, Muslim World League
  /// elsewhere).
  CalculatedMethod? method,
  MethodAngles custom,
  HighLatitude highLatitude,

  /// Minutes each time is moved by (none: as published or calculated).
  Map<Prayer, int> minutes,
});

/// How the app worked before the Prayer calculation page.
const Calculation defaultCalculation = (
  officialFirst: true,
  method: null,
  custom: defaultCustomAngles,
  highLatitude: HighLatitude.automatic,
  minutes: {},
);

/// The Prayer calculation page's choices, each listened to on its own.
class CalculationSettings {
  /// Unsaved choices that start as [defaultCalculation] (for tests).
  CalculationSettings({
    ValueNotifier<bool>? officialFirst,
    ValueNotifier<CalculatedMethod?>? method,
    ValueNotifier<MethodAngles>? custom,
    ValueNotifier<HighLatitude>? highLatitude,
    ValueNotifier<Map<Prayer, int>>? minutes,
  }) : officialFirst =
           officialFirst ?? ValueNotifier(defaultCalculation.officialFirst),
       method = method ?? ValueNotifier(defaultCalculation.method),
       custom = custom ?? ValueNotifier(defaultCalculation.custom),
       highLatitude =
           highLatitude ?? ValueNotifier(defaultCalculation.highLatitude),
       minutes = minutes ?? ValueNotifier(defaultCalculation.minutes);

  /// The choices saved on the phone. Never rename these keys.
  factory CalculationSettings.saved(SharedPreferences storage) =>
      CalculationSettings(
        officialFirst: SavedValue(
          storage,
          key: 'officialFirst',
          read: bool.parse,
          write: (on) => '$on',
          fallback: defaultCalculation.officialFirst,
        ),
        method: SavedValue(
          storage,
          key: 'calculationMethod',
          read: _readMethod,
          write: (method) => method?.name ?? _automatic,
          fallback: defaultCalculation.method,
        ),
        custom: SavedValue(
          storage,
          key: 'customAngles',
          read: _readAngles,
          write: _writeAngles,
          fallback: defaultCalculation.custom,
        ),
        highLatitude: SavedSetting(
          storage,
          key: 'highLatitude',
          values: HighLatitude.values,
          fallback: defaultCalculation.highLatitude,
        ),
        minutes: SavedValue(
          storage,
          key: 'minuteChanges',
          read: _readMinutes,
          write: (minutes) => jsonEncode({
            for (final MapEntry(key: prayer, value: change) in minutes.entries)
              prayer.name: change,
          }),
          fallback: defaultCalculation.minutes,
        ),
      );

  final ValueNotifier<bool> officialFirst;
  final ValueNotifier<CalculatedMethod?> method;

  /// The Custom method's angles (kept when another method is chosen).
  final ValueNotifier<MethodAngles> custom;
  final ValueNotifier<HighLatitude> highLatitude;

  /// Set a new map to change them: changing the map in place would skip the
  /// save and the listeners.
  final ValueNotifier<Map<Prayer, int>> minutes;

  /// Fires when any choice changes, so the times can be worked out again.
  late final Listenable changes = Listenable.merge([
    officialFirst,
    method,
    custom,
    highLatitude,
    minutes,
  ]);

  /// The choices as they are now.
  Calculation get current => (
    officialFirst: officialFirst.value,
    method: method.value,
    custom: custom.value,
    highLatitude: highLatitude.value,
    minutes: minutes.value,
  );
}

const _automatic = 'automatic';

CalculatedMethod? _readMethod(String saved) => saved == _automatic
    ? null
    : CalculatedMethod.values.asNameMap()[saved] ??
          (throw FormatException('Unknown method "$saved"'));

String _writeAngles(MethodAngles angles) => jsonEncode({
  'fajrAngle': angles.fajrAngle,
  'ishaAngle': angles.ishaAngle,
  'ishaMinutes': angles.ishaMinutes,
  'maghribAngle': angles.maghribAngle,
});

bool _isAngle(num angle, double min, double max) =>
    angle >= min && angle <= max;

/// Saved angles, only if every one is within the page's limits.
MethodAngles _readAngles(String saved) => switch (jsonDecode(saved)) {
  {
    'fajrAngle': final num fajr,
    'ishaAngle': final num isha,
    'ishaMinutes': final int? ishaMinutes,
    'maghribAngle': final num? maghrib,
  }
      when _isAngle(fajr, minCustomAngle, maxCustomAngle) &&
          _isAngle(isha, minCustomAngle, maxCustomAngle) &&
          (ishaMinutes == null ||
              (ishaMinutes >= minIshaMinutes &&
                  ishaMinutes <= maxIshaMinutes)) &&
          (maghrib == null ||
              _isAngle(maghrib, minMaghribAngle, maxMaghribAngle)) =>
    (
      fajrAngle: fajr.toDouble(),
      ishaAngle: isha.toDouble(),
      ishaMinutes: ishaMinutes,
      maghribAngle: maghrib?.toDouble(),
    ),
  _ => throw FormatException('Not custom angles: $saved'),
};

/// Saved minute changes, skipping times this version doesn't know.
Map<Prayer, int> _readMinutes(String saved) {
  final json = jsonDecode(saved);
  if (json is! Map<String, dynamic>) {
    throw FormatException('Not minute changes: $saved');
  }
  final byName = Prayer.values.asNameMap();
  return Map.unmodifiable({
    for (final MapEntry(key: name, value: change) in json.entries)
      ?byName[name]: _checkedChange(change),
  });
}

int _checkedChange(Object? change) =>
    change is int && change.abs() <= maxMinuteChange
    ? change
    : throw FormatException('Not a minute change: $change');
