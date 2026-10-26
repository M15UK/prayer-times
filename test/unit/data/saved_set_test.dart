import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/saved_set.dart';
import 'package:prayer_times/data/timetable.dart';

import 'saved_setting_test.dart' show storageWith;

SavedSet<Prayer> hiddenTimes(SharedPreferences storage) =>
    SavedSet(storage, key: 'hiddenTimes', values: Prayer.values);

void main() {
  test('starts empty until the user chooses', () async {
    final storage = await storageWith({});

    expect(hiddenTimes(storage).value, isEmpty);
  });

  test('remembers the chosen set the next time the app starts', () async {
    final storage = await storageWith({});

    hiddenTimes(storage).value = {Prayer.sunrise, Prayer.dhuhr};

    expect(hiddenTimes(storage).value, {Prayer.sunrise, Prayer.dhuhr});
  });

  test('ignores names this version does not know', () async {
    final storage = await storageWith({
      'hiddenTimes': ['sunrise', 'midnight'],
    });

    expect(hiddenTimes(storage).value, {Prayer.sunrise});
  });

  test('can only be changed by choosing a new set, which saves it', () async {
    final storage = await storageWith({});
    final setting = hiddenTimes(storage)..value = {Prayer.sunrise};

    expect(() => setting.value.add(Prayer.isha), throwsUnsupportedError);
  });
}
