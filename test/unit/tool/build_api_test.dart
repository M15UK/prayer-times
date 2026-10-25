import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/timetable.dart';

// tool/ is outside lib/, so it can only be reached with a relative import.
import '../../../tool/build_api.dart' show checkFullYear, parseLondonMonth;

/// One day in the London Prayer Times API format.
/// Made-up values in the documented shape, not real times.
Map<String, String> londonDay() => {
  'date': '2026-10-25',
  'fajr': '05:23',
  'fajr_jamat': '05:45',
  'sunrise': '06:56',
  'dhuhr': '11:45',
  'dhuhr_jamat': '12:45',
  'asr': '14:13',
  'asr_2': '14:48',
  'asr_jamat': '15:00',
  'magrib': '16:42',
  'magrib_jamat': '16:52',
  'isha': '18:11',
  'isha_jamat': '18:30',
};

/// Wraps days in the API's month response: {"city": ..., "times": {...}}.
Map<String, Object> londonMonth(Map<String, String> day) => {
  'city': 'london',
  'times': {'2026-10-25': day},
};

void main() {
  test('converts a month into start, Hanafi Asr and jamaah times', () {
    // Act
    final days = parseLondonMonth(londonMonth(londonDay()));

    // Assert
    final day = days['2026-10-25'];
    expect(day?.start[Prayer.fajr], '05:23');
    expect(day?.start[Prayer.maghrib], '16:42'); // from the API's "magrib"
    expect(day?.asrHanafi, '14:48');
    expect(day?.jamaah[Prayer.isha], '18:30');
    expect(day?.jamaah.containsKey(Prayer.sunrise), isFalse);
  });

  test('rejects 12-hour times, which arrive without am or pm', () {
    // Arrange: what "magrib" looks like without 24hours=true.
    final day = {...londonDay(), 'magrib': '04:42'};

    // Act and assert
    expect(() => parseLondonMonth(londonMonth(day)), throwsFormatException);
  });

  test('rejects a day with a missing time', () {
    final day = {...londonDay()}..remove('isha_jamat');

    expect(() => parseLondonMonth(londonMonth(day)), throwsFormatException);
  });

  test('rejects a jamaah time before its start time', () {
    final day = {...londonDay(), 'fajr_jamat': '05:00'};

    expect(() => parseLondonMonth(londonMonth(day)), throwsFormatException);
  });

  test('rejects a response without times, such as an error message', () {
    expect(
      () => parseLondonMonth({'error': 'Invalid key'}),
      throwsFormatException,
    );
  });

  test('returns no days for a month that is not published yet', () {
    // Decoded from text, exactly as the job receives it.
    expect(parseLondonMonth(jsonDecode('{"times": []}')), isEmpty);
    expect(parseLondonMonth(jsonDecode('{"times": {}}')), isEmpty);
  });

  test('rejects a date that does not exist', () {
    final month = {
      'times': {'2026-13-40': londonDay()},
    };

    expect(() => parseLondonMonth(month), throwsFormatException);
  });

  group('checkFullYear', () {
    /// Every date of [year] as "yyyy-mm-dd".
    List<String> datesOf(int year) => [
      for (
        var day = DateTime.utc(year);
        day.year == year;
        day = day.add(const Duration(days: 1))
      )
        day.toIso8601String().substring(0, 10),
    ];

    test('accepts every date of a normal year and a leap year', () {
      expect(() => checkFullYear(2026, datesOf(2026)), returnsNormally);
      expect(() => checkFullYear(2028, datesOf(2028)), returnsNormally);
    });

    test('rejects a year with days missing', () {
      final dates = datesOf(2026).take(31); // only January

      expect(() => checkFullYear(2026, dates), throwsFormatException);
    });

    test('rejects dates from another year', () {
      final dates = [...datesOf(2026).skip(1), '2025-12-31'];

      expect(() => checkFullYear(2026, dates), throwsFormatException);
    });
  });
}
