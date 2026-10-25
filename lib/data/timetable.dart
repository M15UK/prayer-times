/// The timetable format our API publishes and the app reads.
///
/// Times are kept exactly as the source prints them: local "HH:mm" clock
/// times. The timetable carries its IANA time zone (e.g. Europe/London), so
/// clock changes are handled when the app turns them into real moments.
library;

/// The times a timetable lists, in the order they happen in a day.
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// Which Asr time to use. Standard (Shafi'i, Maliki, Hanbali) is earlier;
/// Hanafi is later.
enum AsrMethod { standard, hanafi }

final _clockTime = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// True for a 24-hour "HH:mm" time such as "05:04" or "18:17".
bool isClockTime(Object? value) =>
    value is String && _clockTime.hasMatch(value);

/// True if [start] has all six times, each later than the one before.
/// "HH:mm" text sorts like the times, so an Isha after midnight ("00:05")
/// counts as out of order.
bool startTimesInOrder(Map<Prayer, String> start) {
  for (var i = 0; i < Prayer.values.length; i++) {
    final time = start[Prayer.values[i]];
    if (time == null) return false;
    final previous = i == 0 ? '' : start[Prayer.values[i - 1]] ?? '';
    if (time.compareTo(previous) <= 0) return false;
  }
  return true;
}

/// True for a real "yyyy-mm-dd" date such as "2026-10-25" (not "2026-13-40").
bool isIsoDate(String value) =>
    value.length == 10 &&
    (DateTime.tryParse(value)?.toIso8601String().startsWith(value) ?? false);

/// One day of times from one source.
class DayTimes {
  const DayTimes({required this.start, this.asrHanafi, this.jamaah = const {}});

  /// Reads a day from downloaded JSON. Throws [FormatException] if anything
  /// is missing or malformed, so bad data never reaches the screen.
  factory DayTimes.fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw FormatException('A day must be an object, got $json');
    }
    final start = _prayerTimesFromJson(json['start']);
    if (start.length != Prayer.values.length) {
      throw FormatException('A day needs all six start times: $start');
    }
    final asrHanafi = json['asrHanafi'];
    if (asrHanafi != null && !isClockTime(asrHanafi)) {
      throw FormatException('asrHanafi should be HH:mm, got $asrHanafi');
    }
    return DayTimes(
      start: start,
      asrHanafi: asrHanafi as String?,
      jamaah: _prayerTimesFromJson(json['jamaah'] ?? const <String, dynamic>{}),
    );
  }

  /// Start (adhan) time of every [Prayer].
  final Map<Prayer, String> start;

  /// The later, Hanafi Asr time, when the source publishes one.
  final String? asrHanafi;

  /// Congregation times, when the source publishes them.
  final Map<Prayer, String> jamaah;

  /// The start time of [prayer], using the Hanafi Asr time when [asr] asks
  /// for it and the source publishes one.
  String? startOf(Prayer prayer, AsrMethod asr) =>
      prayer == Prayer.asr && asr == AsrMethod.hanafi
      ? asrHanafi ?? start[prayer]
      : start[prayer];

  Map<String, Object> toJson() => {
    'start': _prayerTimesToJson(start),
    'asrHanafi': ?asrHanafi, // `?` leaves the key out when it is null
    if (jamaah.isNotEmpty) 'jamaah': _prayerTimesToJson(jamaah),
  };
}

/// Every day a source publishes, plus who published it.
class Timetable {
  const Timetable({
    required this.sourceId,
    required this.sourceName,
    required this.timeZone,
    required this.days,
  });

  /// Reads a timetable from downloaded JSON. Throws [FormatException] if it
  /// is not one.
  factory Timetable.fromJson(Object? json) {
    // A Dart 3 pattern: matches only if every key is there with the right
    // type, and pulls the values out into variables at the same time.
    if (json case {
      'sourceId': final String sourceId,
      'sourceName': final String sourceName,
      'timeZone': final String timeZone,
      'days': final Map<String, dynamic> days,
    }) {
      // An empty or misdated file must never replace a good saved copy.
      if (days.isEmpty || !days.keys.every(isIsoDate)) {
        throw FormatException(
          'Timetable has no days or a bad date: ${days.keys}',
        );
      }
      return Timetable(
        sourceId: sourceId,
        sourceName: sourceName,
        timeZone: timeZone,
        days: {
          for (final MapEntry(key: date, value: day) in days.entries)
            date: DayTimes.fromJson(day),
        },
      );
    }
    throw const FormatException('Not a timetable: no source, zone or days');
  }

  /// Short stable ID, e.g. "london-unified".
  final String sourceId;

  /// The name shown to the user as "Source: ...".
  final String sourceName;

  /// IANA time zone the times are in, e.g. "Europe/London".
  final String timeZone;

  /// Times for each date, keyed by "yyyy-mm-dd".
  final Map<String, DayTimes> days;

  Map<String, Object> toJson() => {
    'sourceId': sourceId,
    'sourceName': sourceName,
    'timeZone': timeZone,
    'days': {
      for (final MapEntry(key: date, value: day) in days.entries)
        date: day.toJson(),
    },
  };
}

Map<String, String> _prayerTimesToJson(Map<Prayer, String> times) => {
  for (final MapEntry(key: prayer, value: time) in times.entries)
    prayer.name: time,
};

Map<Prayer, String> _prayerTimesFromJson(Object? json) {
  if (json is! Map<String, dynamic>) {
    throw FormatException('Expected prayer times, got $json');
  }
  final prayersByName = Prayer.values.asNameMap();
  return {
    for (final MapEntry(key: name, value: time) in json.entries)
      _prayerNamed(prayersByName, name): _checkedTime(name, time),
  };
}

Prayer _prayerNamed(Map<String, Prayer> prayersByName, String name) =>
    prayersByName[name] ?? (throw FormatException('Unknown prayer "$name"'));

String _checkedTime(String name, Object? time) => isClockTime(time)
    ? time as String
    : throw FormatException('$name should be HH:mm, got $time');
