import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One of the user's choices (e.g. Asr time or language), saved on the
/// phone. Screens listen to it and redraw when it changes.
///
/// [T] is an enum; the chosen option is saved by its name under [key].
class SavedSetting<T extends Enum> extends ValueNotifier<T> {
  SavedSetting(
    SharedPreferences storage, {
    required this.key,
    required List<T> values,
    required T fallback,
  }) : _storage = storage,
       super(values.asNameMap()[storage.getString(key)] ?? fallback);

  final SharedPreferences _storage;

  /// Where the choice is saved. Never rename one: saved choices would be lost.
  final String key;

  /// Changing the value also saves it, so it is remembered next launch.
  @override
  set value(T option) {
    super.value = option;
    unawaited(_storage.setString(key, option.name));
  }
}
