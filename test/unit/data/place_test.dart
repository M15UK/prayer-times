import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/place.dart';

import 'real_places.dart';

void main() {
  final places = realPlaces();
  Place byId(String id) => places.firstWhere((place) => place.id == id);

  group('parsePlaces', () {
    test('lists the mosque, London, then all 173 Saudi cities by name', () {
      expect(places.length, 175);
      expect(places[0], eastLondonMosque);
      expect(places[1], london);
      final cityNames = [for (final place in places.skip(2)) place.nameEn];
      expect(cityNames, [...cityNames]..sort());
    });

    test('points each Saudi city at its official timetable', () {
      final riyadh = byId('saudi-1001');

      expect(riyadh.timetablePath, 'saudi/1001');
      expect(riyadh.nameAr, 'الرياض');
      expect(riyadh.timeZone, 'Asia/Riyadh');
      expect(riyadh.isMosque, isFalse);
    });

    test('rejects a city list with missing fields', () {
      expect(
        () => parsePlaces(jsonDecode('[{"id": 1, "nameEn": "X"}]')),
        throwsFormatException,
      );
    });
  });

  test('nameFor gives the Arabic or English name', () {
    expect(byId('saudi-1001').nameFor('ar'), 'الرياض');
    expect(byId('saudi-1001').nameFor('en'), 'Riyadh');
  });

  test('distanceKm: London to Cambridge is about 80 km', () {
    const cambridge = (latitude: 52.2053, longitude: 0.1218);

    expect(distanceKm(london.point, cambridge), closeTo(80, 3));
  });

  group('nearestOfficialPlace (within 25 km)', () {
    test('is London from Wembley, about 13 km out', () {
      const wembley = (latitude: 51.556, longitude: -0.2796);

      expect(nearestOfficialPlace(wembley, places), london);
    });

    test('is nothing 30 km north of London', () {
      const farNorth = (latitude: 51.78, longitude: -0.1276);

      expect(nearestOfficialPlace(farNorth, places), isNull);
    });

    test('is the nearest Saudi city', () {
      const centralRiyadh = (latitude: 24.70, longitude: 46.72);

      expect(nearestOfficialPlace(centralRiyadh, places)?.id, 'saudi-1001');
    });

    test('never picks the mosque, which shares London’s timetable', () {
      expect(nearestOfficialPlace(eastLondonMosque.point, places), london);
    });
  });

  group('searchPlaces', () {
    List<String> idsFor(String query) => [
      for (final place in searchPlaces(places, query)) place.id,
    ];

    test('finds English names, whatever the case', () {
      expect(idsFor('RIYADH'), contains('saudi-1001'));
    });

    test('finds Arabic names, even typed without the hamza', () {
      expect(idsFor('الرياض'), contains('saudi-1001'));
      expect(idsFor('الافلاج'), contains('saudi-9')); // الأفلاج
    });

    test('keeps the mosque first', () {
      expect(searchPlaces(places, '').first, eastLondonMosque);
      expect(idsFor('london'), ['east-london-mosque', 'london']);
    });

    test('finds nothing for a name that is not there', () {
      expect(idsFor('Atlantis'), isEmpty);
    });
  });
}
