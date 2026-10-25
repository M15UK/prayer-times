/// Decides where today's times come from: a chosen place, or the nearest
/// official place to the phone, or a labelled calculation for its position.
library;

import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/calculated_timetable.dart';
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
///
/// [locate] and [timeZoneName] reach the phone; tests pass fakes. Throws
/// [LocationUnavailable] if automatic can't get a position, and
/// [CalculationUnavailable] where calculation breaks down (near the poles).
Future<ResolvedTimes> loadPlaceTimes({
  required Place? chosen,
  required DateTime now,
  required List<Place> places,
  required TimetableRepository repository,
  required Future<GeoPoint?> Function() locate,
  required Future<String> Function() timeZoneName,
}) async {
  if (chosen != null) {
    return (timetable: await _official(chosen, now, repository), place: chosen);
  }
  final position = await locate();
  if (position == null) throw const LocationUnavailable();
  final nearest = nearestOfficialPlace(position, places);
  if (nearest != null) {
    return (
      timetable: await _official(nearest, now, repository),
      place: nearest,
    );
  }
  final zone = await timeZoneName();
  final calculated = calculateTimetable(
    latitude: position.latitude,
    longitude: position.longitude,
    timeZone: zone,
    year: _yearIn(zone, now),
    method: _methodFor(zone),
  );
  return (timetable: calculated, place: null);
}

/// [place]'s official timetable, or, if it can't be had (offline with
/// nothing saved, or not published yet), labelled calculated times for it.
Future<Timetable> _official(
  Place place,
  DateTime now,
  TimetableRepository repository,
) async {
  final year = _yearIn(place.timeZone, now);
  return await repository.load(place: place.timetablePath, year: year) ??
      calculateTimetable(
        latitude: place.latitude,
        longitude: place.longitude,
        timeZone: place.timeZone,
        year: year,
        method: _methodFor(place.timeZone),
      );
}

/// The year it is in [zone]: New Year comes earlier in Riyadh than London.
int _yearIn(String zone, DateTime now) =>
    tz.TZDateTime.from(now, tz.getLocation(zone)).year;

/// Saudi Arabia's own method there, Muslim World League elsewhere.
CalculatedMethod _methodFor(String zone) => zone == 'Asia/Riyadh'
    ? CalculatedMethod.ummAlQura
    : CalculatedMethod.muslimWorldLeague;
