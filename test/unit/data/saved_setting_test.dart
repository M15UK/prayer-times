import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/saved_setting.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';

/// Phone storage that starts with [saved], kept in memory for the test.
Future<SharedPreferences> storageWith(Map<String, Object> saved) {
  SharedPreferences.setMockInitialValues(saved);
  return SharedPreferences.getInstance();
}

SavedSetting<AsrMethod> asrSetting(SharedPreferences storage) => SavedSetting(
  storage,
  key: 'asrMethod',
  values: AsrMethod.values,
  fallback: AsrMethod.standard,
);

SavedSetting<AppLanguage> languageSetting(SharedPreferences storage) =>
    SavedSetting(
      storage,
      key: 'language',
      values: AppLanguage.values,
      fallback: AppLanguage.phone,
    );

void main() {
  test('starts at its fallback until the user chooses', () async {
    final storage = await storageWith({});

    expect(asrSetting(storage).value, AsrMethod.standard);
    expect(languageSetting(storage).value, AppLanguage.phone);
  });

  test('remembers the choice the next time the app starts', () async {
    final storage = await storageWith({});

    asrSetting(storage).value = AsrMethod.hanafi;

    // A fresh setting, as on the next launch, reads what was saved.
    expect(asrSetting(storage).value, AsrMethod.hanafi);
  });

  test('keeps a choice saved by the earlier Asr-only version', () async {
    // Your phone already saved "hanafi" under this key in Step 5.
    final storage = await storageWith({'asrMethod': 'hanafi'});

    expect(asrSetting(storage).value, AsrMethod.hanafi);
  });

  test('uses its fallback if the saved value is not one it knows', () async {
    final storage = await storageWith({'asrMethod': 'nonsense'});

    expect(asrSetting(storage).value, AsrMethod.standard);
  });

  test('keeps each setting separate', () async {
    final storage = await storageWith({});

    languageSetting(storage).value = AppLanguage.arabic;

    expect(languageSetting(storage).value, AppLanguage.arabic);
    expect(asrSetting(storage).value, AsrMethod.standard);
  });
}
