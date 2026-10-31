import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One of the user's choices saved on the phone as text, for choices that
/// aren't a single enum (SavedSetting covers those): a switch, an optional
/// method, a set of angles, minute changes.
class SavedValue<T> extends ValueNotifier<T> {
  /// [read] turns the saved text back into a value and throws a
  /// [FormatException] if it is broken or fails its checks; the choice then
  /// starts at [fallback]. `write` turns a value into text to save.
  SavedValue(
    SharedPreferences storage, {
    required this.key,
    required T Function(String saved) read,
    required this._write,
    required T fallback,
  }) : _storage = storage,
       super(_load(storage.getString(key), read, fallback));

  final SharedPreferences _storage;
  final String Function(T value) _write;

  /// Where the choice is saved. Never rename one: saved choices would be lost.
  final String key;

  static T _load<T>(String? saved, T Function(String) read, T fallback) {
    if (saved == null) return fallback;
    try {
      return read(saved);
    } on FormatException catch (error) {
      // Saved by another version, or damaged: never stop the app starting.
      log('Ignoring a saved choice', error: error);
      return fallback;
    }
  }

  /// Changing the value also saves it, so it is remembered next launch.
  @override
  set value(T choice) {
    super.value = choice;
    unawaited(_storage.setString(key, _write(choice)));
  }
}
