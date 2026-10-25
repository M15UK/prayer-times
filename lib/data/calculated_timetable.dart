/// Prayer times calculated on the phone, for places without an official
/// timetable. The app always labels these as calculated.
library;

// Prefixed, because the library has its own Prayer and CalculationMethod.
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/timetable.dart';

/// The calculation methods the app uses.
enum CalculatedMethod {
  /// Saudi Arabia's official standard. Matches ummulqura.org.sa within a
  /// minute on every day of 2026 (see docs/sources.md).
  ummAlQura,

  /// Everywhere else. Above 48° latitude (e.g. UK summers) Fajr and Isha
  /// use the "seventh of the night" rule, as decided in Step 1.
  muslimWorldLeague,
}

/// Thrown when a method gives no sensible times for a place: inside the
/// polar circles, or where in summer Isha would fall after midnight (from
/// about 61° latitude, e.g. Trondheim or Anchorage).
class CalculationUnavailable implements Exception {
  const CalculationUnavailable(this.message);

  final String message;

  @override
  String toString() => 'CalculationUnavailable: $message';
}

/// Marks a calculated timetable's sourceId, e.g. "calculated-ummAlQura".
const _calculatedPrefix = 'calculated-';

/// Beyond the polar circles the sun can stay up, or down, all day.
const _polarCircle = 66.5;

/// True for any calculated timetable, even one from a method this version
/// does not know, so it is always labelled as calculated.
bool isCalculated(Timetable timetable) =>
    timetable.sourceId.startsWith(_calculatedPrefix);

/// The method [timetable] was calculated with, or null if it is official or
/// the method is unknown.
CalculatedMethod? calculatedMethodOf(Timetable timetable) =>
    isCalculated(timetable)
    ? CalculatedMethod.values.asNameMap()[timetable.sourceId.substring(
        _calculatedPrefix.length,
      )]
    : null;

/// A whole [year] of times for the place at [latitude], [longitude], as
/// local clock times in [timeZone].
///
/// Rounded the cautious way, as the official Umm al-Qura timetable is:
/// prayers up to the next minute (never too early), sunrise down (Fajr
/// never seems to last longer than it does).
///
/// Throws [CalculationUnavailable] where the method breaks down, rather than
/// return times that cannot be right.
Timetable calculateTimetable({
  required double latitude,
  required double longitude,
  required String timeZone,
  required int year,
  required CalculatedMethod method,
}) {
  if (latitude.abs() > _polarCircle) {
    throw CalculationUnavailable('$latitude° is inside a polar circle');
  }
  final coordinates = adhan.Coordinates(latitude, longitude);
  final zone = tz.getLocation(timeZone);
  final standard = _parameters(method, coordinates);
  final hanafi = standard.copyWith(madhab: adhan.Madhab.hanafi);
  return Timetable(
    sourceId: '$_calculatedPrefix${method.name}',
    // English fallback only: the app shows a translated "calculated" label.
    sourceName: 'Calculated (${method.name})',
    timeZone: timeZone,
    days: {
      for (
        var date = DateTime.utc(year);
        date.year == year;
        date = date.add(const Duration(days: 1))
      )
        _isoDate(date): _calculateDay(
          date,
          coordinates: coordinates,
          zone: zone,
          standard: standard,
          hanafi: hanafi,
          longerRamadanIsha: method == CalculatedMethod.ummAlQura,
        ),
    },
  );
}

DayTimes _calculateDay(
  DateTime date, {
  required adhan.Coordinates coordinates,
  required tz.Location zone,
  required adhan.CalculationParameters standard,
  required adhan.CalculationParameters hanafi,
  required bool longerRamadanIsha,
}) {
  adhan.PrayerTimes timesWith(adhan.CalculationParameters parameters) =>
      adhan.PrayerTimes(
        coordinates: coordinates,
        date: date,
        calculationParameters: parameters,
        precision: true, // keep the seconds; we round below
      );
  final times = timesWith(standard);
  // Umm al-Qura: in Ramadan, Isha is 2 hours after Maghrib, not 90 minutes.
  final isha = longerRamadanIsha && HijriCalendar.fromDate(date).hMonth == 9
      ? times.isha.add(const Duration(minutes: 30))
      : times.isha;
  String up(DateTime moment) => _clockTime(moment, zone, roundUp: true);
  final start = {
    Prayer.fajr: up(times.fajr),
    Prayer.sunrise: _clockTime(times.sunrise, zone, roundUp: false),
    Prayer.dhuhr: up(times.dhuhr),
    Prayer.asr: up(times.asr),
    Prayer.maghrib: up(times.maghrib),
    Prayer.isha: up(isha),
  };
  // E.g. an Isha after midnight ("00:00") would come before Maghrib.
  if (!startTimesInOrder(start)) {
    throw CalculationUnavailable('${_isoDate(date)}: out of order: $start');
  }
  return DayTimes(start: start, asrHanafi: up(timesWith(hanafi).asr));
}

adhan.CalculationParameters _parameters(
  CalculatedMethod method,
  adhan.Coordinates coordinates,
) => switch (method) {
  CalculatedMethod.ummAlQura => adhan.CalculationMethodParameters.ummAlQura(),
  CalculatedMethod.muslimWorldLeague =>
    adhan.CalculationMethodParameters.muslimWorldLeague().copyWith(
      // "Seventh of the night" beyond 48° north or south, "middle of the
      // night" nearer the equator. The library only checks north, hence abs.
      highLatitudeRule: adhan.HighLatitudeRule.recommended(
        adhan.Coordinates(coordinates.latitude.abs(), coordinates.longitude),
      ),
    ),
};

String _isoDate(DateTime date) => date.toIso8601String().substring(0, 10);

/// "HH:mm" for [moment] in [zone], rounded up to the next whole minute, or
/// down when [roundUp] is false.
String _clockTime(DateTime moment, tz.Location zone, {required bool roundUp}) {
  final local = tz.TZDateTime.from(moment, zone);
  final wholeMinute = local.subtract(
    Duration(
      seconds: local.second,
      milliseconds: local.millisecond,
      microseconds: local.microsecond,
    ),
  );
  final rounded = roundUp && wholeMinute != local
      ? wholeMinute.add(const Duration(minutes: 1))
      : wholeMinute;
  String twoDigits(int value) => value.toString().padLeft(2, '0');
  return '${twoDigits(rounded.hour)}:${twoDigits(rounded.minute)}';
}
