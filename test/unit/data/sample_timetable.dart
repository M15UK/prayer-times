import 'package:prayer_times/data/timetable.dart';

/// A one-day official Saudi timetable for tests: Riyadh's real times for
/// 25 October 2026 from the Umm al-Qura Calendar. Like every Saudi
/// timetable, it has no jama'ah times and no Hanafi Asr.
Timetable sampleSaudiTimetable() => const Timetable(
  sourceId: 'umm-al-qura',
  sourceName: 'Umm al-Qura Calendar',
  timeZone: 'Asia/Riyadh',
  days: {
    '2026-10-25': DayTimes(
      start: {
        Prayer.fajr: '04:38',
        Prayer.sunrise: '05:56',
        Prayer.dhuhr: '11:38',
        Prayer.asr: '14:53',
        Prayer.maghrib: '17:19',
        Prayer.isha: '18:49',
      },
    ),
  },
);

/// A two-day timetable for tests: London's real times for 25 and 26 October
/// 2026 (25 October checked against londonprayertimes.com).
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
    '2026-10-26': DayTimes(
      start: {
        Prayer.fajr: '05:05',
        Prayer.sunrise: '06:41',
        Prayer.dhuhr: '11:50',
        Prayer.asr: '14:15',
        Prayer.maghrib: '16:48',
        Prayer.isha: '18:15',
      },
      asrHanafi: '14:55',
      jamaah: {
        Prayer.fajr: '05:25',
        Prayer.dhuhr: '12:45',
        Prayer.asr: '15:15',
        Prayer.maghrib: '16:55',
        Prayer.isha: '19:30',
      },
    ),
  },
);
