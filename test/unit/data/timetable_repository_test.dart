import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/http_get.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/timetable_repository.dart';

import 'sample_timetable.dart';

void main() {
  // A fresh, empty folder for every test, standing in for the phone's storage.
  late Directory cacheDir;
  setUp(() async {
    cacheDir = await Directory.systemTemp.createTemp('timetables_test');
  });
  tearDown(() => cacheDir.delete(recursive: true));

  final validBody = jsonEncode(sampleTimetable().toJson());
  File savedFile() => File('${cacheDir.path}/london-2026.json');

  Future<void> saveCopy({required Duration age}) async {
    await savedFile().writeAsString(validBody);
    await savedFile().setLastModified(DateTime.now().subtract(age));
  }

  /// Loads London 2026, using [fetch] in place of the internet.
  Future<Timetable?> load(Future<HttpResult> Function(Uri url) fetch) =>
      TimetableRepository(
        cacheDir: cacheDir,
        fetch: fetch,
      ).load(place: 'london', year: 2026);

  test('downloads and saves the timetable when nothing is saved', () async {
    // Act
    Uri? requested;
    final timetable = await load((url) async {
      requested = url;
      return (status: 200, body: validBody);
    });

    // Assert
    expect(
      '$requested',
      'https://m15uk.github.io/prayer-times/v1/london/2026.json',
    );
    expect(timetable?.days['2026-10-25']?.start[Prayer.fajr], '05:04');
    expect(savedFile().existsSync(), isTrue);
  });

  test('uses a saved copy under a day old without going online', () async {
    await saveCopy(age: const Duration(hours: 2));

    final timetable = await load((_) => fail('should not download'));

    expect(timetable?.sourceName, sampleTimetable().sourceName);
  });

  test('downloads again when the saved copy is over a day old', () async {
    await saveCopy(age: const Duration(hours: 25));
    final newer = jsonEncode(sampleTimetable(sourceName: 'Newer').toJson());

    final timetable = await load((_) async => (status: 200, body: newer));

    expect(timetable?.sourceName, 'Newer');
    expect(await savedFile().readAsString(), newer);
  });

  test('uses the old saved copy when offline', () async {
    await saveCopy(age: const Duration(days: 3));

    final timetable = await load(
      (_) => throw const SocketException('No internet'),
    );

    expect(timetable?.sourceName, sampleTimetable().sourceName);
  });

  test('keeps the saved copy when a download is not a timetable', () async {
    await saveCopy(age: const Duration(days: 3));

    final timetable = await load(
      (_) async => (status: 200, body: '<html>Oops</html>'),
    );

    expect(timetable?.sourceName, sampleTimetable().sourceName);
    expect(await savedFile().readAsString(), validBody);
  });

  test('uses the old saved copy when the server has an error', () async {
    await saveCopy(age: const Duration(days: 3));

    final timetable = await load(
      (_) async => (status: 500, body: 'Internal error'),
    );

    expect(timetable?.sourceName, sampleTimetable().sourceName);
  });

  test('replaces a damaged saved copy with a fresh download', () async {
    await savedFile().writeAsString('{"half a file');

    final timetable = await load((_) async => (status: 200, body: validBody));

    expect(timetable?.sourceName, sampleTimetable().sourceName);
    expect(await savedFile().readAsString(), validBody);
  });

  test('downloads again when the saved copy is dated in the future', () async {
    // The phone's clock was wrong when it saved, then got corrected.
    await saveCopy(age: const Duration(days: -2));
    final newer = jsonEncode(sampleTimetable(sourceName: 'Newer').toJson());

    final timetable = await load((_) async => (status: 200, body: newer));

    expect(timetable?.sourceName, 'Newer');
  });

  test('still returns a good download when it cannot be saved', () async {
    // A file where the folder should be makes every save fail.
    final notAFolder = File('${cacheDir.path}/not-a-folder');
    await notAFolder.writeAsString('');

    final timetable = await TimetableRepository(
      cacheDir: Directory(notAFolder.path),
      fetch: (_) async => (status: 200, body: validBody),
    ).load(place: 'london', year: 2026);

    expect(timetable?.sourceName, sampleTimetable().sourceName);
  });

  test(
    'saves and reuses a timetable kept in a sub-folder (a Saudi city)',
    () async {
      // Arrange: Riyadh lives at saudi/1001 in our API.
      Future<Timetable?> loadRiyadh(
        Future<HttpResult> Function(Uri url) fetch,
      ) => TimetableRepository(
        cacheDir: cacheDir,
        fetch: fetch,
      ).load(place: 'saudi/1001', year: 2026);
      Uri? requested;

      // Act: once online, then offline.
      await loadRiyadh((url) async {
        requested = url;
        return (status: 200, body: validBody);
      });
      final saved = File('${cacheDir.path}/saudi/1001-2026.json');
      await saved.setLastModified(
        DateTime.now().subtract(const Duration(days: 3)),
      );
      final offline = await loadRiyadh(
        (_) => throw const SocketException('No internet'),
      );

      // Assert
      expect(
        '$requested',
        'https://m15uk.github.io/prayer-times/v1/saudi/1001/2026.json',
      );
      expect(saved.existsSync(), isTrue);
      expect(offline, isNotNull);
    },
  );

  test('returns null when the year is not published yet', () async {
    final timetable = await load((_) async => (status: 404, body: ''));

    expect(timetable, isNull);
  });

  test('returns null when offline or too slow, with nothing saved', () async {
    expect(
      await load((_) => throw const SocketException('No internet')),
      isNull,
    );
    expect(await load((_) => throw TimeoutException('Too slow')), isNull);
  });
}
