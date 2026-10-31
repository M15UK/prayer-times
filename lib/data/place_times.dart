/// Decides where today's times come from: a chosen place, or the nearest
/// official place to the phone, or a labelled calculation for its position.
library;

import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/timetable_repository.dart';

/// Thrown in automatic mode when the phone's position isn't available:
/// permission refused, location switched off, or no fix in time.
class LocationUnavailable implements Exception {
  const LocationUnavailable();

  @override
  String toString() => 'LocationUnavailable';
}

/// The times to show, and the place they are for (null: the user's own
/// position, calculated).
typedef ResolvedTimes = ({Timetable timetable, Place? place});

/// Times for [chosen], or, when it is null (automatic), for the official
/// place within 25 km of the phone, else calculated for its exact position.
/// With [Calculation.officialFirst] off, always calculated. Then the user's
/// minute changes are applied, labelled as adjusted.
///
/// [locate] and [timeZoneName] reach the phone; tests pass fakes. Throws
/// [LocationUnavailable] if automatic can't get a position,
/// [CalculationUnavailable] where calculation breaks down (near the poles),
/// and [TimesOutOfOrder] if the minute changes put the times out of order.
Future<ResolvedTimes> loadPlaceTimes({
  required Place? chosen,
  required DateTime now,
  required List<Place> places,
  required TimetableRepository repository,
  required Future<GeoPoint?> Function() locate,
  required Future<String> Function() timeZoneName,
  Calculation calculation = defaultCalculation,
}) async {
  final (:timetable, :place) = await _unadjusted(
    chosen: chosen,
    now: now,
    places: places,
    repository: repository,
    locate: locate,
    timeZoneName: timeZoneName,
    calculation: calculation,
  );
  return (
    timetable: adjustTimetable(timetable, calculation.minutes),
    place: place,
  );
}

Future<ResolvedTimes> _unadjusted({
  required Place? chosen,
  required DateTime now,
  required List<Place> places,
  required TimetableRepository repository,
  required Future<GeoPoint?> Function() locate,
  required Future<String> Function() timeZoneName,
  required Calculation calculation,
}) async {
  if (chosen != null) {
    return (
      timetable: calculation.officialFirst
          ? await _official(chosen, now, repository, calculation)
          : _calculate(chosen.point, chosen.timeZone, now, calculation),
      place: chosen,
    );
  }
  final position = await locate();
  if (position == null) throw const LocationUnavailable();
  final nearest = calculation.officialFirst
      ? nearestOfficialPlace(position, places)
      : null;
  if (nearest != null) {
    return (
      timetable: await _official(nearest, now, repository, calculation),
      place: nearest,
    );
  }
  final zone = await timeZoneName();
  // Local clock times need the zone's rules; without them, don't guess.
  if (!tz.timeZoneDatabase.locations.containsKey(zone)) {
    throw CalculationUnavailable('Unknown time zone "$zone"');
  }
  return (timetable: _calculate(position, zone, now, calculation), place: null);
}

/// [place]'s official timetable, or, if it can't be had (offline with
/// nothing saved, or not published yet), labelled calculated times for it.
Future<Timetable> _official(
  Place place,
  DateTime now,
  TimetableRepository repository,
  Calculation calculation,
) async =>
    await repository.load(
      place: place.timetablePath,
      year: _yearIn(place.timeZone, now),
    ) ??
    _calculate(place.point, place.timeZone, now, calculation);

/// A year of times for [at], worked out the way the user chose.
Timetable _calculate(
  GeoPoint at,
  String zone,
  DateTime now,
  Calculation calculation,
) => calculateTimetable(
  latitude: at.latitude,
  longitude: at.longitude,
  timeZone: zone,
  year: _yearIn(zone, now),
  method: calculation.method ?? _methodFor(zone),
  custom: calculation.custom,
  highLatitude: calculation.highLatitude,
);

/// The year it is in [zone]: New Year comes earlier in Riyadh than London.
int _yearIn(String zone, DateTime now) =>
    tz.TZDateTime.from(now, tz.getLocation(zone)).year;

/// "Automatic": Saudi Arabia's own method there, Muslim World League
/// elsewhere.
CalculatedMethod _methodFor(String zone) => zone == 'Asia/Riyadh'
    ? CalculatedMethod.ummAlQura
    : CalculatedMethod.muslimWorldLeague;
