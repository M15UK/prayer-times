/// Turns a timetable's clock times into real moments, so the app can count
/// down correctly across clock changes and wherever the phone is.
library;

import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/timetable.dart';

/// The prayers the countdown counts to. Sunrise ends Fajr's time but is not
/// a prayer itself.
const countdownPrayers = [
  Prayer.fajr,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
  Prayer.isha,
];

/// The calendar date ("yyyy-mm-dd") that [moment] falls on in [zone].
String dateIn(tz.Location zone, DateTime moment) =>
    tz.TZDateTime.from(moment, zone).toIso8601String().substring(0, 10);

/// The real moment of [clockTime] ("HH:mm") on [date] in [zone].
/// On 29 March, "13:10" in London is 12:10 UTC because the clocks went
/// forward; the timezone database knows every such change.
tz.TZDateTime momentOf(tz.Location zone, String date, String clockTime) {
  final day = DateTime.parse(date);
  // A Dart 3 list pattern: splits "13:10" into hour 13 and minute 10.
  final [hour, minute] = clockTime.split(':').map(int.parse).toList();
  return tz.TZDateTime(zone, day.year, day.month, day.day, hour, minute);
}

/// The first prayer that starts after [now], looking at today and then
/// tomorrow in the timetable's own time zone, with Asr chosen by [asr].
/// Null if the timetable has no more days (e.g. after Isha on 31 December).
({Prayer prayer, tz.TZDateTime at})? nextPrayer(
  Timetable timetable,
  DateTime now, {
  AsrMethod asr = AsrMethod.standard,
}) {
  final zone = tz.getLocation(timetable.timeZone);
  final today = DateTime.parse(dateIn(zone, now));
  for (final offset in [0, 1]) {
    // Built from the calendar date, not by adding 24 hours, which would be
    // wrong on the 23- and 25-hour days when the clocks change.
    final date = DateTime.utc(
      today.year,
      today.month,
      today.day + offset,
    ).toIso8601String().substring(0, 10);
    final day = timetable.days[date];
    if (day == null) continue;
    for (final prayer in countdownPrayers) {
      if (day.startOf(prayer, asr) case final time?) {
        final at = momentOf(zone, date, time);
        if (at.isAfter(now)) return (prayer: prayer, at: at);
      }
    }
  }
  return null;
}

/// "2:08:05" for 2 hours, 8 minutes and 5 seconds.
String formatCountdown(Duration remaining) {
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  final minutes = twoDigits(remaining.inMinutes.remainder(60));
  final seconds = twoDigits(remaining.inSeconds.remainder(60));
  return '${remaining.inHours}:$minutes:$seconds';
}
