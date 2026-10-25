import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/asr_setting.dart';
import 'package:prayer_times/data/timetable.dart';

/// Phone storage that starts with [saved], kept in memory for the test.
Future<SharedPreferences> storageWith(Map<String, Object> saved) {
  SharedPreferences.setMockInitialValues(saved);
  return SharedPreferences.getInstance();
}

void main() {
  test('is Standard until the user chooses', () async {
    final setting = AsrSetting(await storageWith({}));

    expect(setting.value, AsrMethod.standard);
  });

  test('remembers the choice the next time the app starts', () async {
    final storage = await storageWith({});

    AsrSetting(storage).value = AsrMethod.hanafi;

    // A fresh AsrSetting, as on the next launch, reads what was saved.
    expect(AsrSetting(storage).value, AsrMethod.hanafi);
  });

  test('is Standard if the saved value is not one it knows', () async {
    final setting = AsrSetting(await storageWith({'asrMethod': 'nonsense'}));

    expect(setting.value, AsrMethod.standard);
  });
}
