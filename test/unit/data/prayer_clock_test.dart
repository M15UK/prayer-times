import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

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

  test('formatCountdown shows hours, minutes and seconds', () {
    expect(
      formatCountdown(const Duration(hours: 2, minutes: 8, seconds: 5)),
      '2:08:05',
    );
    expect(formatCountdown(const Duration(minutes: 45)), '0:45:00');
  });
}
