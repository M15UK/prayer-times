import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/timetable.dart';

/// Riyadh's official times from ummulqura.org.sa (2026, Gregorian year
/// view): Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha. Ramadan 1447 ran from
/// 18 February to 19 March.
const officialRiyadh = {
  '2026-01-01': ['05:15', '06:37', '11:57', '14:57', '17:17', '18:47'],
  '2026-02-17': ['05:07', '06:25', '12:08', '15:24', '17:49', '19:19'],
  '2026-02-18': ['05:06', '06:25', '12:08', '15:24', '17:50', '19:50'],
  '2026-03-01': ['04:58', '06:16', '12:06', '15:27', '17:56', '19:56'],
  '2026-03-19': ['04:40', '05:58', '12:02', '15:27', '18:04', '20:04'],
  '2026-03-20': ['04:39', '05:57', '12:01', '15:27', '18:05', '19:35'],
  '2026-04-15': ['04:10', '05:31', '11:54', '15:23', '18:16', '19:46'],
  '2026-05-15': ['03:43', '05:09', '11:50', '15:15', '18:30', '20:00'],
  '2026-06-21': ['03:34', '05:04', '11:56', '15:16', '18:46', '20:16'],
  '2026-07-15': ['03:45', '05:13', '12:00', '15:23', '18:45', '20:15'],
  '2026-08-15': ['04:05', '05:27', '11:58', '15:26', '18:28', '19:58'],
  '2026-09-15': ['04:21', '05:38', '11:49', '15:17', '17:59', '19:29'],
  '2026-10-25': ['04:38', '05:56', '11:38', '14:53', '17:19', '18:49'],
  '2026-11-15': ['04:49', '06:09', '11:38', '14:45', '17:07', '18:37'],
  '2026-12-21': ['05:10', '06:33', '11:52', '14:50', '17:10', '18:40'],
};

int minutesOf(String clockTime) {
  final [hour, minute] = clockTime.split(':').map(int.parse).toList();
  return hour * 60 + minute;
}

/// Riyadh at the coordinates ummulqura.org.sa itself uses.
Timetable riyadh2026() => calculateTimetable(
  latitude: 24.67,
  longitude: 46.69,
  timeZone: 'Asia/Riyadh',
  year: 2026,
  method: CalculatedMethod.ummAlQura,
);

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('Riyadh is within one minute of the official Umm al-Qura times', () {
    final days = riyadh2026().days;

    for (final MapEntry(key: date, value: official) in officialRiyadh.entries) {
      for (final (index, prayer) in Prayer.values.indexed) {
        final ours = days[date]?.start[prayer] ?? 'missing';
        final gap = (minutesOf(ours) - minutesOf(official[index])).abs();
        expect(gap, lessThanOrEqualTo(1), reason: '$date $prayer: $ours');
      }
    }
  });

  test('Umm al-Qura Isha is 2 hours after Maghrib in Ramadan, 90 minutes '
      'otherwise', () {
    final days = riyadh2026().days;
    int gap(String date) =>
        minutesOf(days[date]?.start[Prayer.isha] ?? '00:00') -
        minutesOf(days[date]?.start[Prayer.maghrib] ?? '00:00');

    expect(gap('2026-02-17'), 90); // 29 Sha'ban
    expect(gap('2026-02-18'), 120); // 1 Ramadan
    expect(gap('2026-03-19'), 120); // 30 Ramadan
    expect(gap('2026-03-20'), 90); // 1 Shawwal
  });

  test('has a later Hanafi Asr every day', () {
    for (final day in riyadh2026().days.values) {
      final standard = minutesOf(day.start[Prayer.asr] ?? '00:00');
      expect(minutesOf(day.asrHanafi ?? '00:00'), greaterThan(standard));
    }
  });

  test('covers every day of the year, including leap years', () {
    expect(riyadh2026().days.length, 365);
    final leapYear = calculateTimetable(
      latitude: 24.67,
      longitude: 46.69,
      timeZone: 'Asia/Riyadh',
      year: 2028,
      method: CalculatedMethod.ummAlQura,
    );
    expect(leapYear.days.length, 366);
  });

  test('says it is calculated, and by which method', () {
    final timetable = riyadh2026();

    expect(calculatedMethodOf(timetable), CalculatedMethod.ummAlQura);
    expect(timetable.days.values.first.jamaah, isEmpty);
  });

  group('far from the equator', () {
    /// A day's six times in minutes, which must rise through the day.
    void expectInOrder(DayTimes? day, String reason) {
      final times = [
        for (final prayer in Prayer.values)
          minutesOf(day?.start[prayer] ?? '00:00'),
      ];
      for (var i = 1; i < times.length; i++) {
        expect(times[i], greaterThan(times[i - 1]), reason: reason);
      }
    }

    test("works all year at the UK's most northerly town (Lerwick)", () {
      final lerwick = calculateTimetable(
        latitude: 60.15,
        longitude: -1.15,
        timeZone: 'Europe/London',
        year: 2026,
        method: CalculatedMethod.muslimWorldLeague,
      );

      expectInOrder(lerwick.days['2026-06-21'], 'Lerwick midsummer');
    });

    test('uses the high-latitude rule in the far south too (Ushuaia)', () {
      final ushuaia = calculateTimetable(
        latitude: -54.8,
        longitude: -68.3,
        timeZone: 'America/Argentina/Ushuaia',
        year: 2026,
        method: CalculatedMethod.muslimWorldLeague,
      );

      expectInOrder(ushuaia.days['2026-12-21'], 'Ushuaia midsummer');
    });

    test('refuses places where Isha would fall after midnight', () {
      // Trondheim, Norway: in June, Isha would be at 00:00.
      expect(
        () => calculateTimetable(
          latitude: 63.43,
          longitude: 10.39,
          timeZone: 'Europe/Oslo', // an alias zone name, as phones report it
          year: 2026,
          method: CalculatedMethod.muslimWorldLeague,
        ),
        throwsA(isA<CalculationUnavailable>()),
      );
    });

    test('refuses places inside the polar circles', () {
      for (final latitude in [69.65, 90.0, -80.0]) {
        expect(
          () => calculateTimetable(
            latitude: latitude,
            longitude: 18.96,
            timeZone: 'Europe/Oslo',
            year: 2026,
            method: CalculatedMethod.muslimWorldLeague,
          ),
          throwsA(isA<CalculationUnavailable>()),
          reason: 'latitude $latitude',
        );
      }
    });
  });

  test('knows an official timetable is not calculated', () {
    const official = Timetable(
      sourceId: 'london-unified',
      sourceName: 'London Unified Prayer Timetable (East London Mosque)',
      timeZone: 'Europe/London',
      days: {},
    );

    expect(calculatedMethodOf(official), isNull);
    expect(isCalculated(official), isFalse);
  });

  test('still counts as calculated if the method is unknown', () {
    const future = Timetable(
      sourceId: 'calculated-someNewMethod',
      sourceName: 'Calculated',
      timeZone: 'Europe/London',
      days: {},
    );

    expect(isCalculated(future), isTrue);
    expect(calculatedMethodOf(future), isNull);
  });

  test("keeps London's midsummer times in order (high-latitude rule)", () {
    final london = calculateTimetable(
      latitude: 51.5072,
      longitude: -0.1276,
      timeZone: 'Europe/London',
      year: 2026,
      method: CalculatedMethod.muslimWorldLeague,
    );
    final midsummer = london.days['2026-06-21'];
    final times = [
      for (final prayer in Prayer.values)
        minutesOf(midsummer?.start[prayer] ?? '00:00'),
    ];

    // Each time later than the one before, and Isha before midnight.
    for (var i = 1; i < times.length; i++) {
      expect(
        times[i],
        greaterThan(times[i - 1]),
        reason: '${Prayer.values[i]}',
      );
    }
    expect(calculatedMethodOf(london), CalculatedMethod.muslimWorldLeague);
  });
}
