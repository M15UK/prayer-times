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
}
