import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/timetable.dart';

// tool/ is outside lib/, so it can only be reached with a relative import.
import '../../../tool/fetch_umm_al_qura.dart';

/// The table's heading row and three real rows from ummulqura.org.sa
/// (Riyadh, Gregorian 2026, year view), as the page shows them.
const riyadhRows = [
  [
    'Day',
    'Gregorian date',
    'Hijri date',
    'Fajr',
    'Sunrise',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ],
  ['January'],
  [
    'Thursday',
    'Jan 1',
    '12 / 7 / 1447 AH',
    '05:15 AM',
    '06:37 AM',
    '11:57 AM',
    '02:57 PM',
    '05:17 PM',
    '06:47 PM',
  ],
  [
    'Friday',
    'Jan 2',
    '13 / 7 / 1447 AH',
    '05:15 AM',
    '06:37 AM',
    '11:58 AM',
    '02:57 PM',
    '05:17 PM',
    '06:47 PM',
  ],
  [
    'Wednesday',
    'Feb 18',
    '1 / 9 / 1447 AH',
    '05:06 AM',
    '06:25 AM',
    '12:08 PM',
    '03:24 PM',
    '05:50 PM',
    '07:50 PM',
  ],
];

void main() {
  test('citySlug makes the page address the site uses', () {
    expect(citySlug('Riyadh'), 'riyadh');
    expect(citySlug('Al Kharj'), 'al-kharj');
    expect(citySlug("Al 'Is"), 'al-is');
    expect(citySlug("Simira'"), 'simira');
    expect(citySlug('Wadi ad-Dawasir'), 'wadi-ad-dawasir');
  });

  test('to24Hour converts the page’s 12-hour times', () {
    expect(to24Hour('05:15 AM'), '05:15');
    expect(to24Hour('12:05 PM'), '12:05');
    expect(to24Hour('12:30 AM'), '00:30');
    expect(to24Hour('06:47 PM'), '18:47');
    expect(() => to24Hour('5:15'), throwsFormatException);
    expect(() => to24Hour('13:15 PM'), throwsFormatException);
  });

  group('parseUmmAlQuraYear', () {
    test('reads day rows and skips headings', () {
      final days = parseUmmAlQuraYear(riyadhRows, 2026);

      expect(days.keys, ['2026-01-01', '2026-01-02', '2026-02-18']);
      expect(days['2026-01-01']?.start[Prayer.fajr], '05:15');
      expect(days['2026-01-01']?.start[Prayer.isha], '18:47');
      expect(days['2026-02-18']?.start[Prayer.isha], '19:50'); // Ramadan
      expect(days['2026-01-01']?.jamaah, isEmpty);
    });

    test('accepts the "Today" badge the page adds to the current day', () {
      final today = [
        [
          'Sunday Today',
          'Oct 25',
          '14 / 5 / 1448 AH',
          '04:38 AM',
          '05:56 AM',
          '11:38 AM',
          '02:53 PM',
          '05:19 PM',
          '06:49 PM',
        ],
      ];

      expect(
        parseUmmAlQuraYear(today, 2026)['2026-10-25']?.start[Prayer.asr],
        '14:53',
      );
    });

    test('rejects a table for a different year (weekdays do not match)', () {
      // These rows are 2026's: 1 January 2027 is a Friday, not a Thursday.
      expect(() => parseUmmAlQuraYear(riyadhRows, 2027), throwsFormatException);
    });

    test('rejects times out of order', () {
      final broken = [
        [
          'Thursday',
          'Jan 1',
          '12 / 7 / 1447 AH',
          '05:15 AM',
          '06:37 AM',
          '11:57 AM',
          '02:57 PM',
          '05:17 AM',
          '06:47 PM',
        ],
      ];

      expect(() => parseUmmAlQuraYear(broken, 2026), throwsFormatException);
    });
  });

  test('checkCityHeading catches the site quietly showing Makkah instead', () {
    const city = (id: 151, nameEn: "Al 'Is");

    expect(
      () => checkCityHeading("Prayer Times in Al 'Is, Madinah", city),
      returnsNormally,
    );
    expect(
      () => checkCityHeading('Prayer times in Mecca', city),
      throwsFormatException,
    );
  });

  group('parseUmmAlQuraCities', () {
    test('keeps what the app needs from the official city list', () {
      final cities = parseUmmAlQuraCities(
        jsonDecode('''[{"id": 1001, "region_id": 1001, "latitude": 24.67,
          "longitude": 46.69, "name_ar": "الرياض", "name_en": "Riyadh",
          "name_ur": "ریاض", "type": "city", "is_region_capital": true}]'''),
      );

      expect(cities, [
        {
          'id': 1001,
          'nameEn': 'Riyadh',
          'nameAr': 'الرياض',
          'latitude': 24.67,
          'longitude': 46.69,
        },
      ]);
    });

    test('rejects a list with missing fields', () {
      expect(
        () => parseUmmAlQuraCities(jsonDecode('[{"id": 1, "name_en": "X"}]')),
        throwsFormatException,
      );
    });
  });
}
