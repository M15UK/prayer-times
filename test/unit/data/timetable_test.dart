import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/timetable.dart';

void main() {
  test('survives a trip through JSON unchanged', () {
    // Arrange: one day with every optional part, one day with none.
    const timetable = Timetable(
      sourceId: 'london-unified',
      sourceName: 'London Unified Prayer Timetable (East London Mosque)',
      timeZone: 'Europe/London',
      days: {
        '2026-10-25': DayTimes(
          start: {
            Prayer.fajr: '05:23',
            Prayer.sunrise: '06:56',
            Prayer.dhuhr: '11:45',
            Prayer.asr: '14:13',
            Prayer.maghrib: '16:42',
            Prayer.isha: '18:11',
          },
          asrHanafi: '14:48',
          jamaah: {Prayer.fajr: '05:45', Prayer.isha: '18:30'},
        ),
        '2026-10-26': DayTimes(
          start: {
            Prayer.fajr: '05:25',
            Prayer.sunrise: '06:58',
            Prayer.dhuhr: '11:45',
            Prayer.asr: '14:11',
            Prayer.maghrib: '16:40',
            Prayer.isha: '18:09',
          },
        ),
      },
    );

    // Act
    final decoded = Timetable.fromJson(
      jsonDecode(jsonEncode(timetable.toJson())) as Map<String, dynamic>,
    );

    // Assert
    expect(decoded.toJson(), timetable.toJson());
    expect(decoded.days['2026-10-26']?.asrHanafi, isNull);
    expect(decoded.days['2026-10-26']?.jamaah, isEmpty);
  });

  group('fromJson rejects downloads that are not a valid timetable:', () {
    /// [day] wrapped in a timetable and sent through JSON, as if downloaded.
    Object? downloadedWith(Map<String, DayTimes> days) => jsonDecode(
      jsonEncode(
        Timetable(
          sourceId: 'test',
          sourceName: 'Test',
          timeZone: 'Europe/London',
          days: days,
        ).toJson(),
      ),
    );

    const allStartTimes = {
      Prayer.fajr: '05:04',
      Prayer.sunrise: '06:39',
      Prayer.dhuhr: '11:50',
      Prayer.asr: '14:17',
      Prayer.maghrib: '16:50',
      Prayer.isha: '18:17',
    };

    test('missing source, time zone or days', () {
      expect(
        () => Timetable.fromJson({'sourceId': 'x'}),
        throwsFormatException,
      );
      expect(() => Timetable.fromJson('<html>'), throwsFormatException);
    });

    test('a timetable with no days', () {
      expect(
        () => Timetable.fromJson(downloadedWith({})),
        throwsFormatException,
      );
    });

    test('a date that does not exist', () {
      const day = DayTimes(start: allStartTimes);

      expect(
        () => Timetable.fromJson(downloadedWith({'2026-13-40': day})),
        throwsFormatException,
      );
    });

    test('a day without all six start times', () {
      final withoutIsha = {...allStartTimes}..remove(Prayer.isha);
      final days = {'2026-10-25': DayTimes(start: withoutIsha)};

      expect(
        () => Timetable.fromJson(downloadedWith(days)),
        throwsFormatException,
      );
    });

    test('a time that is not 24-hour HH:mm', () {
      final badIsha = {...allStartTimes, Prayer.isha: '6.17pm'};
      final days = {'2026-10-25': DayTimes(start: badIsha)};

      expect(
        () => Timetable.fromJson(downloadedWith(days)),
        throwsFormatException,
      );
    });
  });
}
