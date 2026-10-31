import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/saved_value.dart';

import 'saved_setting_test.dart' show storageWith;

/// A saved number, read back with checks like the real settings.
SavedValue<int> savedCount(SharedPreferences storage) => SavedValue(
  storage,
  key: 'count',
  read: (saved) {
    final count = int.parse(saved); // throws FormatException if not a number
    if (count < 0) throw FormatException('Negative count: $count');
    return count;
  },
  write: (count) => '$count',
  fallback: 1,
);

void main() {
  test('starts at its fallback until the user chooses', () async {
    expect(savedCount(await storageWith({})).value, 1);
  });

  test('remembers the choice the next time the app starts', () async {
    final storage = await storageWith({});

    savedCount(storage).value = 5;

    expect(storage.getString('count'), '5');
    expect(savedCount(storage).value, 5);
  });

  test(
    'falls back when the saved value is broken or fails its checks',
    () async {
      expect(savedCount(await storageWith({'count': 'five'})).value, 1);
      expect(savedCount(await storageWith({'count': '-3'})).value, 1);
    },
  );

  test('tells listeners when the choice changes', () async {
    final count = savedCount(await storageWith({}));
    var heard = 0;
    count.addListener(() => heard++);

    count.value = 2;

    expect(heard, 1);
  });
}
