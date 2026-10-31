/// The user's minute changes (Prayer calculation page), applied to any
/// timetable, official or calculated. Adjusted times always say so.
library;

import 'package:prayer_times/data/timetable.dart';

/// Thrown when minute changes would put a day's times out of order, or move
/// one past midnight: wrong times are never shown.
class TimesOutOfOrder implements Exception {
  const TimesOutOfOrder(this.message);

  final String message;

  @override
  String toString() => 'TimesOutOfOrder: $message';
}

/// True if the user moved any of [timetable]'s times.
bool isAdjusted(Timetable timetable) => timetable.adjustments.isNotEmpty;

const _minutesInADay = 24 * 60;

/// A copy of [timetable] with each time in [minutes] moved that many minutes
/// later (earlier when negative), every day. The Hanafi Asr moves with the
/// Asr; jama'ah times are set by the mosque, so they stay as published.
///
/// Throws [TimesOutOfOrder] if any day would come out of order.
Timetable adjustTimetable(Timetable timetable, Map<Prayer, int> minutes) {
  final changes = Map<Prayer, int>.unmodifiable({
    for (final MapEntry(key: prayer, value: change) in minutes.entries)
      if (change != 0) prayer: change,
  });
  if (changes.isEmpty) return timetable;
  return Timetable(
    sourceId: timetable.sourceId,
    sourceName: timetable.sourceName,
    timeZone: timetable.timeZone,
    adjustments: changes,
    days: {
      for (final MapEntry(key: date, value: day) in timetable.days.entries)
        date: _adjustDay(date, day, changes),
    },
  );
}

DayTimes _adjustDay(String date, DayTimes day, Map<Prayer, int> changes) {
  String moved(Prayer prayer, String time) =>
      _addMinutes(time, changes[prayer] ?? 0, date);
  final start = {
    for (final MapEntry(key: prayer, value: time) in day.start.entries)
      prayer: moved(prayer, time),
  };
  if (!startTimesInOrder(start)) {
    throw TimesOutOfOrder('$date: out of order: $start');
  }
  return DayTimes(
    start: start,
    asrHanafi: switch (day.asrHanafi) {
      final hanafi? => moved(Prayer.asr, hanafi),
      null => null,
    },
    jamaah: day.jamaah,
  );
}

/// "HH:mm" [time] moved by [change] minutes, on the same day.
String _addMinutes(String time, int change, String date) {
  final [hour, minute] = time.split(':').map(int.parse).toList();
  final total = hour * 60 + minute + change;
  if (total < 0 || total >= _minutesInADay) {
    throw TimesOutOfOrder('$date: $time moved by $change crosses midnight');
  }
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(total ~/ 60)}:${twoDigits(total % 60)}';
}
