import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/saved_place.dart';

const riyadh = Place(
  id: 'saudi-1001',
  timetablePath: 'saudi/1001',
  nameEn: 'Riyadh',
  nameAr: 'الرياض',
  latitude: 24.67,
  longitude: 46.69,
  timeZone: 'Asia/Riyadh',
);
const places = [eastLondonMosque, london, riyadh];

/// Phone storage that starts with [saved], kept in memory for the test.
Future<SharedPreferences> storageWith(Map<String, Object> saved) {
  SharedPreferences.setMockInitialValues(saved);
  return SharedPreferences.getInstance();
}

void main() {
  test('is automatic on the first launch, and knows it is the first', () async {
    final saved = SavedPlace(await storageWith({}), places: places);

    expect(saved.value, isNull);
    expect(saved.isFirstLaunch, isTrue);
  });

  test('remembers a chosen place', () async {
    final storage = await storageWith({});

    SavedPlace(storage, places: places).value = riyadh;

    // A fresh SavedPlace, as on the next launch, reads what was saved.
    final nextLaunch = SavedPlace(storage, places: places);
    expect(nextLaunch.value, riyadh);
    expect(nextLaunch.isFirstLaunch, isFalse);
  });

  test(
    'remembers choosing automatic, so it is no longer a first launch',
    () async {
      final storage = await storageWith({});

      SavedPlace(storage, places: places).value = null;

      final nextLaunch = SavedPlace(storage, places: places);
      expect(nextLaunch.value, isNull);
      expect(nextLaunch.isFirstLaunch, isFalse);
    },
  );

  test('falls back to automatic for a place it no longer knows', () async {
    final saved = SavedPlace(
      await storageWith({'place': 'saudi-99999'}),
      places: places,
    );

    expect(saved.value, isNull);
    expect(saved.isFirstLaunch, isFalse);
  });
}
