import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/timetable_repository.dart';

import 'real_places.dart';
import 'sample_timetable.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  // A fresh, empty folder for every test, standing in for the phone's storage.
  late Directory cacheDir;
  setUp(() async {
    cacheDir = await Directory.systemTemp.createTemp('place_times_test');
  });
  tearDown(() => cacheDir.delete(recursive: true));

  final places = realPlaces();
  final riyadh = places.firstWhere((place) => place.id == 'saudi-1001');
  final validBody = jsonEncode(sampleTimetable().toJson());

  /// Loads times with fakes for the internet (answering [status]), the
  /// phone's [position] and its time [zone]. Downloads go into [requested].
  Future<ResolvedTimes> load({
    required Place? chosen,
    DateTime? now,
    GeoPoint? position,
    String zone = 'Europe/London',
    int status = 200,
    List<Uri>? requested,
  }) => loadPlaceTimes(
    chosen: chosen,
    now: now ?? DateTime.utc(2026, 10, 25, 12, 9),
    places: places,
    repository: TimetableRepository(
      cacheDir: cacheDir,
      fetch: (url) async {
        requested?.add(url);
        return (status: status, body: status == 200 ? validBody : '');
      },
    ),
    locate: () async => position,
    timeZoneName: () async => zone,
  );

  group('a chosen place', () {
    test('London uses the London timetable', () async {
      final requested = <Uri>[];
      final times = await load(chosen: london, requested: requested);

      expect('${requested.single}', '$apiBaseUrl/london/2026.json');
      expect(times.place, london);
    });

    test('East London Mosque uses the London timetable too', () async {
      final requested = <Uri>[];
      final times = await load(chosen: eastLondonMosque, requested: requested);

      expect('${requested.single}', '$apiBaseUrl/london/2026.json');
      expect(times.place, eastLondonMosque);
    });

    test('a Saudi city uses its official timetable', () async {
      final requested = <Uri>[];
      final times = await load(chosen: riyadh, requested: requested);

      expect('${requested.single}', '$apiBaseUrl/saudi/1001/2026.json');
      expect(times.place, riyadh);
    });

    test("uses the place's own year: New Year comes first in Riyadh", () async {
      // 21:30 UTC on 31 December is already 00:30 on 1 January in Riyadh.
      final requested = <Uri>[];
      await load(
        chosen: riyadh,
        now: DateTime.utc(2026, 12, 31, 21, 30),
        requested: requested,
      );

      expect('${requested.single}', '$apiBaseUrl/saudi/1001/2027.json');
    });

    test(
      'falls back to labelled calculated times, keeping the place',
      () async {
        final saudi = await load(chosen: riyadh, status: 404);
        final uk = await load(chosen: london, status: 404);

        expect(calculatedMethodOf(saudi.timetable), CalculatedMethod.ummAlQura);
        expect(saudi.place, riyadh);
        expect(
          calculatedMethodOf(uk.timetable),
          CalculatedMethod.muslimWorldLeague,
        );
      },
    );
  });

  group('automatic', () {
    test('without a position, says the location is unavailable', () {
      expect(load(chosen: null), throwsA(isA<LocationUnavailable>()));
    });

    test("near Riyadh, uses Riyadh's official timetable", () async {
      final requested = <Uri>[];
      final times = await load(
        chosen: null,
        position: (latitude: 24.70, longitude: 46.72),
        zone: 'Asia/Riyadh',
        requested: requested,
      );

      expect(times.place, riyadh);
      expect('${requested.single}', '$apiBaseUrl/saudi/1001/2026.json');
    });

    test('in Manchester, calculates for that spot, with no download', () async {
      final requested = <Uri>[];
      final times = await load(
        chosen: null,
        position: (latitude: 53.4808, longitude: -2.2426),
        requested: requested,
      );

      expect(times.place, isNull);
      expect(
        calculatedMethodOf(times.timetable),
        CalculatedMethod.muslimWorldLeague,
      );
      expect(times.timetable.timeZone, 'Europe/London');
      expect(requested, isEmpty);
    });

    test('in the Saudi desert, calculates with Umm al-Qura', () async {
      // 154 km from the nearest listed city.
      final times = await load(
        chosen: null,
        position: (latitude: 20.0, longitude: 51.0),
        zone: 'Asia/Riyadh',
      );

      expect(times.place, isNull);
      expect(calculatedMethodOf(times.timetable), CalculatedMethod.ummAlQura);
    });

    test('with a time zone the app does not know, says calculation is '
        'unavailable', () {
      expect(
        load(
          chosen: null,
          position: (latitude: 53.4808, longitude: -2.2426),
          zone: 'Not/AZone',
        ),
        throwsA(isA<CalculationUnavailable>()),
      );
    });

    test('in the Arctic, says calculation is unavailable', () {
      expect(
        load(
          chosen: null,
          position: (latitude: 80.0, longitude: 20.0),
          zone: 'Arctic/Longyearbyen',
        ),
        throwsA(isA<CalculationUnavailable>()),
      );
    });
  });
}
