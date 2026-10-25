/// The timetable format our API publishes and the app reads.
///
/// Times are kept exactly as the source prints them: local "HH:mm" clock
/// times. The timetable carries its IANA time zone (e.g. Europe/London), so
/// clock changes are handled when the app turns them into real moments.
library;

/// The times a timetable lists, in the order they happen in a day.
enum Prayer { fajr, sunrise, dhuhr, asr, maghrib, isha }

/// One day of times from one source.
class DayTimes {
  const DayTimes({required this.start, this.asrHanafi, this.jamaah = const {}});

  factory DayTimes.fromJson(Map<String, dynamic> json) => DayTimes(
    start: _prayerTimesFromJson(json['start']),
    asrHanafi: json['asrHanafi'] as String?,
    jamaah: _prayerTimesFromJson(json['jamaah'] ?? const <String, dynamic>{}),
  );

  /// Start (adhan) time of every [Prayer].
  final Map<Prayer, String> start;

  /// The later, Hanafi Asr time, when the source publishes one.
  final String? asrHanafi;

  /// Congregation times, when the source publishes them.
  final Map<Prayer, String> jamaah;

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

  factory Timetable.fromJson(Map<String, dynamic> json) => Timetable(
    sourceId: json['sourceId'] as String,
    sourceName: json['sourceName'] as String,
    timeZone: json['timeZone'] as String,
    days: {
      for (final MapEntry(key: date, value: day)
          in (json['days'] as Map<String, dynamic>).entries)
        date: DayTimes.fromJson(day as Map<String, dynamic>),
    },
  );

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

Map<Prayer, String> _prayerTimesFromJson(Object? json) => {
  for (final MapEntry(key: name, value: time)
      in (json as Map<String, dynamic>).entries)
    Prayer.values.byName(name): time as String,
};
