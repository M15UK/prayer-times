import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/timetable.dart';
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
    Calculation calculation = defaultCalculation,
  }) => loadPlaceTimes(
    chosen: chosen,
    calculation: calculation,
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

  group('the Prayer calculation choices', () {
    /// The default choices with some changed.
    Calculation choosing({
      bool officialFirst = true,
      CalculatedMethod? method,
      Map<Prayer, int> minutes = const {},
    }) => (
      officialFirst: officialFirst,
      method: method,
      custom: defaultCustomAngles,
      highLatitude: HighLatitude.automatic,
      minutes: minutes,
    );

    test('official first: London stays official whatever the method', () async {
      final times = await load(
        chosen: london,
        calculation: choosing(method: CalculatedMethod.northAmerica),
      );

      expect(isCalculated(times.timetable), isFalse);
    });

    test('official first: the chosen method fills in where there is no '
        'official timetable', () async {
      final manchester = await load(
        chosen: null,
        position: (latitude: 53.4808, longitude: -2.2426),
        calculation: choosing(method: CalculatedMethod.northAmerica),
      );
      final offline = await load(
        chosen: riyadh,
        status: 404,
        calculation: choosing(method: CalculatedMethod.karachi),
      );

      expect(
        calculatedMethodOf(manchester.timetable),
        CalculatedMethod.northAmerica,
      );
      expect(calculatedMethodOf(offline.timetable), CalculatedMethod.karachi);
    });

    test('not official first: a chosen place is calculated with the method, '
        'with no download', () async {
      final requested = <Uri>[];
      final times = await load(
        chosen: london,
        requested: requested,
        calculation: choosing(
          officialFirst: false,
          method: CalculatedMethod.northAmerica,
        ),
      );

      expect(
        calculatedMethodOf(times.timetable),
        CalculatedMethod.northAmerica,
      );
      expect(times.place, london);
      expect(requested, isEmpty);
    });

    test('not official first: automatic calculates even near Riyadh, with '
        "Saudi Arabia's own method", () async {
      final requested = <Uri>[];
      final times = await load(
        chosen: null,
        position: (latitude: 24.70, longitude: 46.72),
        zone: 'Asia/Riyadh',
        requested: requested,
        calculation: choosing(officialFirst: false),
      );

      expect(calculatedMethodOf(times.timetable), CalculatedMethod.ummAlQura);
      expect(times.place, isNull);
      expect(requested, isEmpty);
    });

    test('minute changes move the official times too, and say so', () async {
      final times = await load(
        chosen: london,
        calculation: choosing(minutes: const {Prayer.fajr: 2}),
      );

      expect(isCalculated(times.timetable), isFalse);
      expect(times.timetable.adjustments, {Prayer.fajr: 2});
      expect(
        times.timetable.days['2026-10-25']?.start[Prayer.fajr],
        '05:06', // published as 05:04
      );
    });

    test('minute changes that put the times out of order are refused', () {
      expect(
        load(
          chosen: london,
          calculation: choosing(minutes: const {Prayer.asr: 160}),
        ),
        throwsA(isA<TimesOutOfOrder>()),
      );
    });
  });
}
