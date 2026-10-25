import 'package:prayer_times/data/timetable.dart';

/// A one-day timetable for tests: London's real times for 25 October 2026,
/// checked against londonprayertimes.com.
Timetable sampleTimetable({
  String sourceName = 'London Unified Prayer Timetable (East London Mosque)',
}) => Timetable(
  sourceId: 'london-unified',
  sourceName: sourceName,
  timeZone: 'Europe/London',
  days: const {
    '2026-10-25': DayTimes(
      start: {
        Prayer.fajr: '05:04',
        Prayer.sunrise: '06:39',
        Prayer.dhuhr: '11:50',
        Prayer.asr: '14:17',
        Prayer.maghrib: '16:50',
        Prayer.isha: '18:17',
      },
      asrHanafi: '14:57',
      jamaah: {
        Prayer.fajr: '05:24',
        Prayer.dhuhr: '12:45',
        Prayer.asr: '15:15',
        Prayer.maghrib: '16:57',
        Prayer.isha: '19:30',
      },
    ),
  },
);
