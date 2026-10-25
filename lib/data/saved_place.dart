import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/place.dart';

/// Where the user wants times for, saved on the phone: a [Place], or null
/// for automatic (the nearest official place, found by location).
class SavedPlace extends ValueNotifier<Place?> {
  SavedPlace(SharedPreferences storage, {required List<Place> places})
    : _storage = storage,
      isFirstLaunch = storage.getString(_key) == null,
      super(_find(storage.getString(_key), places));

  final SharedPreferences _storage;

  /// True if no choice has been saved yet (the main screen saves automatic
  /// after the first load that works).
  final bool isFirstLaunch;

  static const _key = 'place';
  static const _automatic = 'automatic';

  /// Unknown or missing ids (e.g. a city that was removed) mean automatic.
  static Place? _find(String? id, List<Place> places) =>
      places.where((place) => place.id == id).firstOrNull;

  /// Changing the value also saves it, even when it doesn't change (so
  /// choosing automatic on the first launch is remembered).
  @override
  set value(Place? place) {
    super.value = place;
    unawaited(_storage.setString(_key, place?.id ?? _automatic));
  }
}
