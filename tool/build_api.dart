/// Builds our timetable API: fetches the London Unified Prayer Timetable,
/// checks it, converts it to our format (lib/data/timetable.dart) and writes
/// one JSON file per year for GitHub Pages to serve to the app.
///
/// Run locally:
///   LONDON_PRAYER_TIMES_API_KEY=... dart run tool/build_api.dart [outDir]
library;

import 'dart:convert';
import 'dart:io';

import 'package:prayer_times/data/timetable.dart';

const _apiKeyVariable = 'LONDON_PRAYER_TIMES_API_KEY';
const _requestTimeout = Duration(seconds: 30);

/// The credit wording agreed with London Prayer Times by email.
const _londonSourceName =
    'London Unified Prayer Timetable (East London Mosque)';

/// The API's field name for each start time. Note its spelling "magrib".
const _londonStartFields = {
  Prayer.fajr: 'fajr',
  Prayer.sunrise: 'sunrise',
  Prayer.dhuhr: 'dhuhr',
  Prayer.asr: 'asr',
  Prayer.maghrib: 'magrib',
  Prayer.isha: 'isha',
};

/// The API's field name for each jama'ah time (sunrise has none).
const _londonJamaahFields = {
  Prayer.fajr: 'fajr_jamat',
  Prayer.dhuhr: 'dhuhr_jamat',
  Prayer.asr: 'asr_jamat',
  Prayer.maghrib: 'magrib_jamat',
  Prayer.isha: 'isha_jamat',
};

/// Each list must run in time order. The first is the whole day; the rest
/// keep each jama'ah between its own start time and the next one. This also
/// catches 12-hour times, which arrive without am or pm (maghrib "04:42").
const _londonOrderRules = [
  ['fajr', 'sunrise', 'dhuhr', 'asr', 'asr_2', 'magrib', 'isha'],
  ['fajr', 'fajr_jamat', 'sunrise'],
  ['dhuhr', 'dhuhr_jamat', 'asr'],
  ['asr', 'asr_jamat', 'magrib'],
  ['magrib', 'magrib_jamat', 'isha'],
  ['isha', 'isha_jamat'],
];

final _clockTime = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

Future<void> main(List<String> args) async {
  final apiKey = Platform.environment[_apiKeyVariable] ?? '';
  if (apiKey.isEmpty) {
    stderr.writeln('Set $_apiKeyVariable to the London Prayer Times API key.');
    exitCode = 64; // Standard "usage error" code.
    return;
  }
  final outDir = args.isEmpty ? 'public' : args.first;
  final thisYear = DateTime.now().year;

  // Any error stops the job, so nothing bad is published and the files
  // already online stay as they were.
  if (!await _publishLondonYear(apiKey, thisYear, outDir)) {
    stderr.writeln('London $thisYear: the API returned no times.');
    exitCode = 1;
    return;
  }
  // Next year's times are usually added in late October. Until then the app
  // falls back to labelled calculated times.
  if (!await _publishLondonYear(apiKey, thisYear + 1, outDir)) {
    stdout.writeln('London ${thisYear + 1}: not published yet, skipped.');
  }
}

/// Converts one month from the London Prayer Times API into our format.
///
/// Returns no days for a month that is not published yet. Throws
/// [FormatException] if anything looks wrong, so bad data is never published.
Map<String, DayTimes> parseLondonMonth(Object? response) {
  final times = response is Map<String, dynamic> ? response['times'] : null;
  // An empty month comes back as [] or {}.
  if (times is List && times.isEmpty) return const {};
  if (times is! Map<String, dynamic>) {
    throw FormatException(
      'Expected {"times": {...}}, got: ${_preview(response)}',
    );
  }
  return {
    for (final MapEntry(key: date, value: day) in times.entries)
      date: _parseLondonDay(date, day),
  };
}

/// Throws unless [dates] are exactly every date of [year], once each.
/// Guards against a short or wrong year being published as if complete.
void checkFullYear(int year, Iterable<String> dates) {
  final daysInYear = DateTime.utc(year + 1)
      .difference(DateTime.utc(year))
      .inDays;
  final datesInYear = dates.where((date) => date.startsWith('$year-')).toSet();
  if (datesInYear.length != daysInYear || dates.length != daysInYear) {
    throw FormatException(
      '$year: expected all $daysInYear days, got ${dates.length} '
      '(${datesInYear.length} in $year)',
    );
  }
}

/// True if [date] is "yyyy-mm-dd" and really exists (not e.g. 2026-13-40).
bool _isRealDate(String date) =>
    DateTime.tryParse(date)?.toIso8601String().startsWith(date) ?? false;

/// A short preview of an API response for error messages.
String _preview(Object? value) {
  final text = '$value';
  return text.length <= 200 ? text : '${text.substring(0, 200)}…';
}

DayTimes _parseLondonDay(String date, Object? day) {
  if (date.length != 10 || !_isRealDate(date) || day is! Map<String, dynamic>) {
    throw FormatException('$date: expected a real date and an object of times');
  }

  String timeOf(String field) {
    final value = day[field];
    if (value is! String || !_clockTime.hasMatch(value)) {
      throw FormatException('$date: "$field" should be HH:mm, got $value');
    }
    return value;
  }

  for (final fields in _londonOrderRules) {
    _checkInOrder(date, fields, timeOf);
  }

  return DayTimes(
    start: {
      for (final MapEntry(key: prayer, value: field)
          in _londonStartFields.entries)
        prayer: timeOf(field),
    },
    asrHanafi: timeOf('asr_2'),
    jamaah: {
      for (final MapEntry(key: prayer, value: field)
          in _londonJamaahFields.entries)
        prayer: timeOf(field),
    },
  );
}

/// Throws unless each field's time is no earlier than the one before it.
/// "HH:mm" text sorts the same way as the times themselves.
void _checkInOrder(
  String date,
  List<String> fields,
  String Function(String field) timeOf,
) {
  for (var i = 1; i < fields.length; i++) {
    final earlier = timeOf(fields[i - 1]);
    final later = timeOf(fields[i]);
    if (later.compareTo(earlier) < 0) {
      throw FormatException(
        '$date: ${fields[i]} ($later) is before ${fields[i - 1]} ($earlier)',
      );
    }
  }
}

/// Writes [year]'s timetable file. Returns false if the year is not
/// published at all; throws if it is only partly there or looks wrong.
Future<bool> _publishLondonYear(String apiKey, int year, String outDir) async {
  final months = [
    for (var month = 1; month <= 12; month++)
      parseLondonMonth(
        jsonDecode(await _fetch(_londonUrl(apiKey, year, month))),
      ),
  ];
  final days = {for (final month in months) ...month};
  if (days.isEmpty) return false;
  checkFullYear(year, [for (final month in months) ...month.keys]);

  final timetable = Timetable(
    sourceId: 'london-unified',
    sourceName: _londonSourceName,
    timeZone: 'Europe/London',
    days: days,
  );
  final file = File('$outDir/v1/london/$year.json');
  await file.parent.create(recursive: true);
  await file.writeAsString(jsonEncode(timetable.toJson()));
  stdout.writeln('London $year: ${days.length} days written to ${file.path}');
  return true;
}

Uri _londonUrl(String apiKey, int year, int month) =>
    Uri.https('www.londonprayertimes.com', '/api/times/', {
      'format': 'json',
      'year': '$year',
      'month': '$month',
      // Without this, times come back as 12-hour clock with no am or pm.
      '24hours': 'true',
      'key': apiKey,
    });

Future<String> _fetch(Uri url) async {
  // Never print the key: every error carries this copy of the URL instead.
  final safeUrl = url.replace(
    queryParameters: {...url.queryParameters, 'key': 'hidden'},
  );
  final client = HttpClient()..connectionTimeout = _requestTimeout;
  try {
    final request = await client.getUrl(url);
    final response = await request.close().timeout(_requestTimeout);
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_requestTimeout);
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: safeUrl);
    }
    return body;
  } on HttpException catch (error) {
    // Dart's own HTTP errors include the full URL, key and all.
    throw HttpException(error.message, uri: safeUrl);
  } finally {
    client.close();
  }
}
