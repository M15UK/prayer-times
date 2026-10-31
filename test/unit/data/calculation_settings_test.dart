import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/timetable.dart';

import 'saved_setting_test.dart' show storageWith;

void main() {
  test('starts as the app works today: official first, automatic method', () {
    final current = CalculationSettings().current;

    expect(current.officialFirst, isTrue);
    expect(current.method, isNull);
    expect(current.custom, defaultCustomAngles);
    expect(current.highLatitude, HighLatitude.automatic);
    expect(current.minutes, isEmpty);
  });

  test('saved choices start the same way', () async {
    final saved = CalculationSettings.saved(await storageWith({}));

    expect(saved.current, CalculationSettings().current);
  });

  test('remembers every choice the next time the app starts', () async {
    final storage = await storageWith({});
    const angles = (
      fajrAngle: 16.5,
      ishaAngle: 15.0,
      ishaMinutes: 80,
      maghribAngle: 4.0,
    );

    CalculationSettings.saved(storage)
      ..officialFirst.value = false
      ..method.value = CalculatedMethod.northAmerica
      ..custom.value = angles
      ..highLatitude.value = HighLatitude.twilightAngle
      ..minutes.value = {Prayer.fajr: 2, Prayer.isha: -3};
    final again = CalculationSettings.saved(storage).current;

    expect(again.officialFirst, isFalse);
    expect(again.method, CalculatedMethod.northAmerica);
    expect(again.custom, angles);
    expect(again.highLatitude, HighLatitude.twilightAngle);
    expect(again.minutes, {Prayer.fajr: 2, Prayer.isha: -3});
  });

  test('can go back to the automatic method', () async {
    final storage = await storageWith({});
    CalculationSettings.saved(storage).method.value = CalculatedMethod.karachi;

    CalculationSettings.saved(storage).method.value = null;

    expect(CalculationSettings.saved(storage).current.method, isNull);
  });

  test('ignores saved values that are broken or out of range', () async {
    final storage = await storageWith({
      'officialFirst': 'perhaps',
      'calculationMethod': 'notAMethod',
      'customAngles':
          '{"fajrAngle": 45, "ishaAngle": 17, '
          '"ishaMinutes": null, "maghribAngle": null}',
      'minuteChanges': '{"fajr": 300}',
    });

    expect(
      CalculationSettings.saved(storage).current,
      CalculationSettings().current,
    );
  });

  test('ignores minute changes for times it does not know', () async {
    final storage = await storageWith({'minuteChanges': '{"tahajjud": 2}'});

    expect(CalculationSettings.saved(storage).current.minutes, isEmpty);
  });

  test('the saved minute changes cannot be changed in place', () async {
    final storage = await storageWith({'minuteChanges': '{"fajr": 2}'});

    final minutes = CalculationSettings.saved(storage).current.minutes;

    expect(() => minutes[Prayer.isha] = 1, throwsUnsupportedError);
  });

  test('tells listeners when any choice changes', () {
    final settings = CalculationSettings();
    var heard = 0;
    settings.changes.addListener(() => heard++);

    settings.officialFirst.value = false;
    settings.minutes.value = {Prayer.asr: 1};

    expect(heard, 2);
  });
}
