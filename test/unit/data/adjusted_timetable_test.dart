import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/timetable.dart';

import 'sample_timetable.dart';

void main() {
  final london = sampleTimetable();

  test('without changes, is the timetable as published', () {
    expect(adjustTimetable(london, const {}), same(london));
    expect(adjustTimetable(london, const {Prayer.fajr: 0}), same(london));
    expect(isAdjusted(london), isFalse);
  });

  test('moves each changed time by its minutes, every day', () {
    final adjusted = adjustTimetable(london, const {
      Prayer.fajr: 2,
      Prayer.isha: -3,
    });

    final day = adjusted.days['2026-10-25'];
    expect(day?.start[Prayer.fajr], '05:06'); // was 05:04
    expect(day?.start[Prayer.isha], '18:14'); // was 18:17
    expect(day?.start[Prayer.dhuhr], '11:50'); // unchanged
    expect(adjusted.days['2026-10-26']?.start[Prayer.fajr], '05:07');
  });

  test('moves the Hanafi Asr with the Asr, and leaves jamaah times alone', () {
    final adjusted = adjustTimetable(london, const {Prayer.asr: 5});

    final day = adjusted.days['2026-10-25'];
    expect(day?.start[Prayer.asr], '14:22'); // was 14:17
    expect(day?.asrHanafi, '15:02'); // was 14:57
    expect(day?.jamaah[Prayer.asr], '15:15'); // set by the mosque
  });

  test('carries over across the hour', () {
    final adjusted = adjustTimetable(london, const {Prayer.maghrib: 10});

    expect(adjusted.days['2026-10-25']?.start[Prayer.maghrib], '17:00');
  });

  test('keeps the source and records only the real changes', () {
    final adjusted = adjustTimetable(london, const {
      Prayer.fajr: 2,
      Prayer.dhuhr: 0,
    });

    expect(adjusted.sourceId, london.sourceId);
    expect(adjusted.sourceName, london.sourceName);
    expect(adjusted.timeZone, london.timeZone);
    expect(adjusted.adjustments, {Prayer.fajr: 2});
    expect(isAdjusted(adjusted), isTrue);
  });

  test('leaves the original timetable unchanged', () {
    adjustTimetable(london, const {Prayer.fajr: 2});

    expect(london.days['2026-10-25']?.start[Prayer.fajr], '05:04');
    expect(london.adjustments, isEmpty);
  });

  test('refuses changes that put the times out of order', () {
    // Asr 14:17 moved past Maghrib at 16:50.
    expect(
      () => adjustTimetable(london, const {Prayer.asr: 160}),
      throwsA(isA<TimesOutOfOrder>()),
    );
  });

  test('refuses changes that cross midnight', () {
    const late = Timetable(
      sourceId: 'calculated-muslimWorldLeague',
      sourceName: 'Calculated',
      timeZone: 'Europe/London',
      days: {
        '2026-06-21': DayTimes(
          start: {
            Prayer.fajr: '02:40',
            Prayer.sunrise: '04:43',
            Prayer.dhuhr: '13:03',
            Prayer.asr: '17:23',
            Prayer.maghrib: '21:22',
            Prayer.isha: '23:50',
          },
        ),
      },
    );

    expect(
      () => adjustTimetable(late, const {Prayer.isha: 15}),
      throwsA(isA<TimesOutOfOrder>()),
    );
  });
}
