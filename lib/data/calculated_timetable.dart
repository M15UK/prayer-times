/// Prayer times calculated on the phone, for places without an official
/// timetable. The app always labels these as calculated.
library;

// Prefixed, because the library has its own Prayer and CalculationMethod.
import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:hijri/hijri_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/timetable.dart';

/// The calculation methods the user can choose: every method the adhan
/// library publishes, plus the user's own angles. Never rename one: the name
/// is saved, and is part of a calculated timetable's sourceId.
enum CalculatedMethod {
  algerian,
  dubai,
  egyptian,
  france,
  gulfRegion,
  indonesian,
  jafari,
  jordan,
  karachi,
  kuwait,
  moonsightingCommittee,
  morocco,

  /// What "Automatic" uses outside Saudi Arabia.
  muslimWorldLeague,
  northAmerica,
  portugal,
  qatar,
  russia,
  singapore,
  tehran,
  tunisia,
  turkiye,

  /// Saudi Arabia's official standard, and what "Automatic" uses there.
  /// Matches ummulqura.org.sa within a minute on every day of 2026 (see
  /// docs/sources.md).
  ummAlQura,

  /// The user's own [MethodAngles].
  custom,
}

/// The sun's angles below the horizon that set Fajr, Maghrib and Isha.
typedef MethodAngles = ({
  double fajrAngle,
  double ishaAngle,

  /// Isha this many minutes after sunset instead of by [ishaAngle] (null:
  /// by angle).
  int? ishaMinutes,

  /// Maghrib when the sun is this far below the horizon (null: at sunset).
  double? maghribAngle,
});

/// Changed copies of a set of angles (records can't be changed in place).
extension MethodAnglesCopies on MethodAngles {
  MethodAngles withFajrAngle(double angle) => (
    fajrAngle: angle,
    ishaAngle: ishaAngle,
    ishaMinutes: ishaMinutes,
    maghribAngle: maghribAngle,
  );

  MethodAngles withIshaAngle(double angle) => (
    fajrAngle: fajrAngle,
    ishaAngle: angle,
    ishaMinutes: ishaMinutes,
    maghribAngle: maghribAngle,
  );

  /// Null: Isha by angle again.
  MethodAngles withIshaMinutes(int? minutes) => (
    fajrAngle: fajrAngle,
    ishaAngle: ishaAngle,
    ishaMinutes: minutes,
    maghribAngle: maghribAngle,
  );

  /// Null: Maghrib at sunset again.
  MethodAngles withMaghribAngle(double? angle) => (
    fajrAngle: fajrAngle,
    ishaAngle: ishaAngle,
    ishaMinutes: ishaMinutes,
    maghribAngle: angle,
  );
}

/// Where the Custom method starts: the Muslim World League's angles.
const MethodAngles defaultCustomAngles = (
  fajrAngle: 18,
  ishaAngle: 17,
  ishaMinutes: null,
  maghribAngle: null,
);

/// How Fajr and Isha are found where the sky never gets dark enough for
/// their angles (e.g. UK summers).
enum HighLatitude {
  /// The seventh of the night beyond 48° north or south, the middle of the
  /// night nearer the equator (as decided in Step 1).
  automatic,
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle,
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
/// [custom] is used only by [CalculatedMethod.custom].
///
/// Throws [CalculationUnavailable] where the method breaks down, rather than
/// return times that cannot be right.
Timetable calculateTimetable({
  required double latitude,
  required double longitude,
  required String timeZone,
  required int year,
  required CalculatedMethod method,
  MethodAngles custom = defaultCustomAngles,
  HighLatitude highLatitude = HighLatitude.automatic,
}) {
  if (latitude.abs() > _polarCircle) {
    throw CalculationUnavailable('$latitude° is inside a polar circle');
  }
  final coordinates = adhan.Coordinates(latitude, longitude);
  final zone = tz.getLocation(timeZone);
  final standard = _parameters(
    method,
    custom,
  ).copyWith(highLatitudeRule: _highLatitudeRule(highLatitude, coordinates));
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

/// [method]'s angles, as the method list shows them.
MethodAngles anglesOf(
  CalculatedMethod method, {
  MethodAngles custom = defaultCustomAngles,
}) {
  final parameters = _parameters(method, custom);
  final ishaMinutes = parameters.ishaInterval ?? 0;
  return (
    fajrAngle: parameters.fajrAngle,
    ishaAngle: parameters.ishaAngle,
    // The library writes "no interval" as 0.
    ishaMinutes: ishaMinutes > 0 ? ishaMinutes : null,
    maghribAngle: parameters.maghribAngle,
  );
}

/// The minutes [method] itself adds to some times (e.g. Dhuhr +1 for the
/// Muslim World League), as the method list shows them.
Map<Prayer, int> methodCorrections(CalculatedMethod method) {
  final byName = Prayer.values.asNameMap();
  return Map.unmodifiable({
    for (final MapEntry(key: prayer, value: minutes) in _parameters(
      method,
      defaultCustomAngles,
    ).methodAdjustments.entries)
      if (minutes != 0) ?byName[prayer.name]: minutes,
  });
}

/// The library's own settings for [method], including its minute
/// corrections (e.g. Dhuhr +1 minute for the Muslim World League).
adhan.CalculationParameters _parameters(
  CalculatedMethod method,
  MethodAngles custom,
) => switch (method) {
  CalculatedMethod.algerian => adhan.CalculationMethodParameters.algerian(),
  CalculatedMethod.dubai => adhan.CalculationMethodParameters.dubai(),
  CalculatedMethod.egyptian => adhan.CalculationMethodParameters.egyptian(),
  CalculatedMethod.france => adhan.CalculationMethodParameters.france(),
  CalculatedMethod.gulfRegion => adhan.CalculationMethodParameters.gulfRegion(),
  CalculatedMethod.indonesian => adhan.CalculationMethodParameters.indonesian(),
  CalculatedMethod.jafari => adhan.CalculationMethodParameters.jafari(),
  CalculatedMethod.jordan => adhan.CalculationMethodParameters.jordan(),
  CalculatedMethod.karachi => adhan.CalculationMethodParameters.karachi(),
  CalculatedMethod.kuwait => adhan.CalculationMethodParameters.kuwait(),
  CalculatedMethod.moonsightingCommittee =>
    adhan.CalculationMethodParameters.moonsightingCommittee(),
  CalculatedMethod.morocco => adhan.CalculationMethodParameters.morocco(),
  CalculatedMethod.muslimWorldLeague =>
    adhan.CalculationMethodParameters.muslimWorldLeague(),
  CalculatedMethod.northAmerica =>
    adhan.CalculationMethodParameters.northAmerica(),
  CalculatedMethod.portugal => adhan.CalculationMethodParameters.portugal(),
  CalculatedMethod.qatar => adhan.CalculationMethodParameters.qatar(),
  CalculatedMethod.russia => adhan.CalculationMethodParameters.russia(),
  CalculatedMethod.singapore => adhan.CalculationMethodParameters.singapore(),
  CalculatedMethod.tehran => adhan.CalculationMethodParameters.tehran(),
  CalculatedMethod.tunisia => adhan.CalculationMethodParameters.tunisia(),
  CalculatedMethod.turkiye => adhan.CalculationMethodParameters.turkiye(),
  CalculatedMethod.ummAlQura => adhan.CalculationMethodParameters.ummAlQura(),
  CalculatedMethod.custom => adhan.CalculationParameters(
    method: adhan.CalculationMethod.other,
    fajrAngle: custom.fajrAngle,
    ishaAngle: custom.ishaAngle,
    ishaInterval: custom.ishaMinutes,
    maghribAngle: custom.maghribAngle,
  ),
};

adhan.HighLatitudeRule _highLatitudeRule(
  HighLatitude choice,
  adhan.Coordinates coordinates,
) => switch (choice) {
  // The library only checks north, hence abs.
  HighLatitude.automatic => adhan.HighLatitudeRule.recommended(
    adhan.Coordinates(coordinates.latitude.abs(), coordinates.longitude),
  ),
  HighLatitude.middleOfTheNight => adhan.HighLatitudeRule.middleOfTheNight,
  HighLatitude.seventhOfTheNight => adhan.HighLatitudeRule.seventhOfTheNight,
  HighLatitude.twilightAngle => adhan.HighLatitudeRule.twilightAngle,
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
