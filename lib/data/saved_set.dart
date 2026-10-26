import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A set of the user's choices (e.g. the hidden prayer times), saved on the
/// phone by name. Like SavedSetting, but for several options at once.
class SavedSet<T extends Enum> extends ValueNotifier<Set<T>> {
  SavedSet(
    SharedPreferences storage, {
    required this.key,
    required List<T> values,
  }) : _storage = storage,
       super(_load(storage, key, values));

  final SharedPreferences _storage;

  /// Where the set is saved. Never rename one: saved choices would be lost.
  final String key;

  // Names this version doesn't know (from a newer or older version) are
  // skipped, so they can never stop the app starting.
  static Set<T> _load<T extends Enum>(
    SharedPreferences storage,
    String key,
    List<T> values,
  ) {
    final byName = values.asNameMap();
    return Set.unmodifiable({
      for (final name in storage.getStringList(key) ?? const <String>[])
        ?byName[name],
    });
  }

  /// Choosing a new set also saves it. The set itself can't be changed in
  /// place, which would skip both the save and the listeners.
  @override
  set value(Set<T> choices) {
    super.value = Set.unmodifiable(choices);
    unawaited(
      _storage.setStringList(key, [for (final choice in choices) choice.name]),
    );
  }
}
