import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/timetable.dart';

/// The user's Asr choice, saved on the phone. Screens listen to it and
/// redraw when it changes.
class AsrSetting extends ValueNotifier<AsrMethod> {
  AsrSetting(this._storage) : super(_read(_storage));

  final SharedPreferences _storage;

  static const _key = 'asrMethod';

  static AsrMethod _read(SharedPreferences storage) =>
      AsrMethod.values.asNameMap()[storage.getString(_key)] ??
      AsrMethod.standard;

  /// Changing the value also saves it, so it is remembered next launch.
  @override
  set value(AsrMethod method) {
    super.value = method;
    unawaited(_storage.setString(_key, method.name));
  }
}
