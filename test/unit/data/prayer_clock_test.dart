import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/timetable.dart';

import 'sample_timetable.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('momentOf follows the clock change (13:10 BST is 12:10 GMT)', () {
    final london = tz.getLocation('Europe/London');

    expect(
      momentOf(london, '2026-03-28', '12:11').toUtc(),
      DateTime.utc(2026, 3, 28, 12, 11),
    );
    expect(
      momentOf(london, '2026-03-29', '13:10').toUtc(),
      DateTime.utc(2026, 3, 29, 12, 10),
    );
  });

  test("dateIn gives London's date even when the phone is elsewhere", () {
    // 20:00 on New Year's Eve in New York is already 1 January in London.
    final newYork = tz.getLocation('America/New_York');
    final newYearsEve = tz.TZDateTime(newYork, 2026, 12, 31, 20);

    expect(dateIn(tz.getLocation('Europe/London'), newYearsEve), '2027-01-01');
  });

  group('nextPrayer', () {
    test('is Asr just after Dhuhr', () {
      final next = nextPrayer(
        sampleTimetable(),
        DateTime.utc(2026, 10, 25, 12, 9),
      );

      expect(next?.prayer, Prayer.asr);
      expect(next?.at.toUtc(), DateTime.utc(2026, 10, 25, 14, 17));
    });

    test('uses the later Asr time when Hanafi is chosen', () {
      final next = nextPrayer(
        sampleTimetable(),
        DateTime.utc(2026, 10, 25, 12, 9),
        asr: AsrMethod.hanafi,
      );

      expect(next?.prayer, Prayer.asr);
      expect(next?.at.toUtc(), DateTime.utc(2026, 10, 25, 14, 57));
    });

    test('skips sunrise, which is not a prayer', () {
      final next = nextPrayer(sampleTimetable(), DateTime.utc(2026, 10, 25, 6));

      expect(next?.prayer, Prayer.dhuhr);
    });

    test("is tomorrow's Fajr after Isha", () {
      final next = nextPrayer(
        sampleTimetable(),
        DateTime.utc(2026, 10, 25, 22),
      );

      expect(next?.prayer, Prayer.fajr);
      expect(next?.at.toUtc(), DateTime.utc(2026, 10, 26, 5, 5));
    });

    test('is null when the timetable has no more days', () {
      expect(
        nextPrayer(sampleTimetable(), DateTime.utc(2026, 10, 26, 22)),
        isNull,
      );
    });

    test('works when the phone is in another time zone', () {
      // 14:00 in Riyadh is 11:00 in London: before London's Dhuhr at 11:50.
      final riyadh = tz.getLocation('Asia/Riyadh');
      final now = tz.TZDateTime(riyadh, 2026, 10, 25, 14);

      final next = nextPrayer(sampleTimetable(), now);

      expect(next?.prayer, Prayer.dhuhr);
      expect(next?.at.toUtc(), DateTime.utc(2026, 10, 25, 11, 50));
    });
  });

  group('upcomingPrayers', () {
    final lunchtime = DateTime.utc(2026, 10, 25, 12, 9);

    test('lists every prayer still to come, day by day, without sunrise', () {
      final upcoming = upcomingPrayers(sampleTimetable(), lunchtime, days: 10);

      expect(upcoming.map((next) => next.prayer), [
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
        ...countdownPrayers,
      ]);
      expect(upcoming.first.date, '2026-10-25');
      expect(upcoming.first.time, '14:17');
      expect(upcoming.last.date, '2026-10-26');
      expect(upcoming.last.at.toUtc(), DateTime.utc(2026, 10, 26, 18, 15));
    });

    test('stops after the number of days asked for', () {
      final upcoming = upcomingPrayers(sampleTimetable(), lunchtime, days: 1);

      expect(upcoming.map((next) => next.prayer), [
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]);
    });

    test('uses the later Asr time when Hanafi is chosen', () {
      final upcoming = upcomingPrayers(
        sampleTimetable(),
        lunchtime,
        asr: AsrMethod.hanafi,
      );

      expect(upcoming.first.time, '14:57');
    });

    // A full calculated year for London, for windows of several days. Late:
    // built inside a test, once the time zones are loaded.
    late final calculatedLondon = calculateTimetable(
      latitude: 51.5072,
      longitude: -0.1276,
      timeZone: 'Europe/London',
      year: 2026,
      method: CalculatedMethod.muslimWorldLeague,
    );

    test('keeps each prayer at its clock time across the clock change', () {
      // London's clocks go back an hour on 25 October 2026.
      final upcoming = upcomingPrayers(
        calculatedLondon,
        DateTime.utc(2026, 10, 20, 12),
        days: 10,
      );

      expect(upcoming.map((next) => next.date).toSet(), hasLength(10));
      for (final next in upcoming) {
        expect(
          next.at.toIso8601String(),
          startsWith('${next.date}T${next.time}'),
        );
      }
      expect(upcoming.first.at.timeZoneOffset, const Duration(hours: 1));
      expect(upcoming.last.at.timeZoneOffset, Duration.zero);
    });

    test("stops at the end of the timetable's year", () {
      final upcoming = upcomingPrayers(
        calculatedLondon,
        DateTime.utc(2026, 12, 28, 12),
        days: 10,
      );

      expect(upcoming.map((next) => next.date).toSet(), {
        '2026-12-28',
        '2026-12-29',
        '2026-12-30',
        '2026-12-31',
      });
    });

    test('skips days the timetable does not have', () {
      // After Isha on the 25th, only the 26th is left of the three days asked.
      final upcoming = upcomingPrayers(
        sampleTimetable(),
        DateTime.utc(2026, 10, 25, 22),
        days: 3,
      );

      expect(upcoming.map((next) => next.prayer), countdownPrayers);
      expect(upcoming.every((next) => next.date == '2026-10-26'), isTrue);
    });
  });

  test('formatCountdown shows hours, minutes and seconds', () {
    expect(
      formatCountdown(const Duration(hours: 2, minutes: 8, seconds: 5)),
      '2:08:05',
    );
    expect(formatCountdown(const Duration(minutes: 45)), '0:45:00');
  });
}
