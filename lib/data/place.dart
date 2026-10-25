/// The places the app has official timetables for, and how to find the
/// nearest one.
library;

import 'dart:math';

/// A position on Earth, in degrees.
typedef GeoPoint = ({double latitude, double longitude});

/// A place with an official timetable.
class Place {
  const Place({
    required this.id,
    required this.timetablePath,
    required this.nameEn,
    required this.nameAr,
    required this.latitude,
    required this.longitude,
    required this.timeZone,
    this.isMosque = false,
  });

  /// Saved on the phone to remember the user's choice. Never change one,
  /// or people's saved choice is lost.
  final String id;

  /// Where its timetable lives in our API, e.g. "london" or "saudi/1001".
  final String timetablePath;

  final String nameEn;
  final String nameAr;
  final double latitude;
  final double longitude;

  /// IANA time zone, e.g. "Europe/London".
  final String timeZone;

  /// A mosque rather than a city (shown first, never picked automatically).
  final bool isMosque;

  GeoPoint get point => (latitude: latitude, longitude: longitude);

  /// The name in the app's language ("ar" or "en").
  String nameFor(String languageCode) => languageCode == 'ar' ? nameAr : nameEn;
}

/// The London Unified Prayer Timetable.
const london = Place(
  id: 'london',
  timetablePath: 'london',
  nameEn: 'London',
  nameAr: 'لندن',
  latitude: 51.5072,
  longitude: -0.1276,
  timeZone: 'Europe/London',
);

/// Shares London's timetable, whose jama'ah times are this mosque's.
const eastLondonMosque = Place(
  id: 'east-london-mosque',
  timetablePath: 'london',
  nameEn: 'East London Mosque',
  nameAr: 'مسجد شرق لندن',
  latitude: 51.5176, // 82–92 Whitechapel Road (Wikipedia)
  longitude: -0.0656,
  timeZone: 'Europe/London',
  isMosque: true,
);

/// How close the user must be to use a place's official timetable.
const officialRadiusKm = 25.0;

/// Every place: the mosque, London, then the Saudi cities from our
/// published list (api/v1/saudi/cities.json), sorted by English name.
/// Throws [FormatException] if a city lacks an id, names or coordinates.
List<Place> parsePlaces(Object? saudiCities) {
  if (saudiCities is! List) {
    throw const FormatException('Expected a list of Saudi cities');
  }
  final cities = [for (final city in saudiCities) _saudiCity(city)]
    ..sort((a, b) => a.nameEn.compareTo(b.nameEn));
  return List.unmodifiable([eastLondonMosque, london, ...cities]);
}

Place _saudiCity(Object? json) => switch (json) {
  {
    'id': final int id,
    'nameEn': final String nameEn,
    'nameAr': final String nameAr,
    'latitude': final num latitude,
    'longitude': final num longitude,
  } =>
    Place(
      id: 'saudi-$id',
      timetablePath: 'saudi/$id',
      nameEn: nameEn,
      nameAr: nameAr,
      latitude: latitude.toDouble(),
      longitude: longitude.toDouble(),
      timeZone: 'Asia/Riyadh',
    ),
  _ => throw FormatException('City without id, names or coordinates: $json'),
};

/// Distance between two points along the Earth's surface (haversine).
double distanceKm(GeoPoint a, GeoPoint b) {
  const earthRadiusKm = 6371.0;
  double radians(double degrees) => degrees * pi / 180;
  final halfChord =
      pow(sin(radians(b.latitude - a.latitude) / 2), 2) +
      cos(radians(a.latitude)) *
          cos(radians(b.latitude)) *
          pow(sin(radians(b.longitude - a.longitude) / 2), 2);
  return 2 * earthRadiusKm * asin(sqrt(halfChord));
}

/// The nearest city with an official timetable, if one is within
/// [officialRadiusKm] of [at]. Mosques are only ever chosen by hand.
Place? nearestOfficialPlace(GeoPoint at, List<Place> places) {
  final cities = places.where((place) => !place.isMosque);
  if (cities.isEmpty) return null;
  final nearest = cities.reduce(
    (a, b) => distanceKm(at, a.point) <= distanceKm(at, b.point) ? a : b,
  );
  return distanceKm(at, nearest.point) <= officialRadiusKm ? nearest : null;
}

/// The places whose English or Arabic name contains [query], in their
/// usual order. Arabic is matched with or without a hamza on the alif.
List<Place> searchPlaces(List<Place> places, String query) {
  final wanted = _searchForm(query);
  if (wanted.isEmpty) return places;
  return [
    for (final place in places)
      if (_searchForm(place.nameEn).contains(wanted) ||
          _searchForm(place.nameAr).contains(wanted))
        place,
  ];
}

/// Lower case, trimmed, with أ إ آ written as plain ا, as people often type.
String _searchForm(String text) =>
    text.trim().toLowerCase().replaceAll(RegExp('[أإآ]'), 'ا');
