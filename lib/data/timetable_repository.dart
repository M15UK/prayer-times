import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';

import 'package:prayer_times/data/http_get.dart';
import 'package:prayer_times/data/timetable.dart';

/// Where tool/build_api.dart publishes our timetables.
const apiBaseUrl = 'https://m15uk.github.io/prayer-times/v1';

/// How long a saved timetable counts as up to date. Our API rebuilds daily.
const _maxSavedAge = Duration(hours: 24);

/// Gets timetables from our API and keeps a copy on the phone, so the app
/// still works offline.
class TimetableRepository {
  const TimetableRepository({required this.cacheDir, this.fetch = httpGet});

  /// Folder where downloaded timetables are saved.
  final Directory cacheDir;

  /// Downloads a URL. Tests pass a fake instead of using the internet.
  final Future<HttpResult> Function(Uri url) fetch;

  /// Returns [place]'s timetable for [year], or null if there is none to
  /// show: not published yet, or offline with nothing saved.
  ///
  /// A saved copy under a day old is used without going online. Otherwise
  /// the app downloads a fresh copy and, if that fails, falls back to the
  /// saved one, however old.
  Future<Timetable?> load({required String place, required int year}) async {
    final file = File('${cacheDir.path}/$place-$year.json');
    final saved = await _readSaved(file);
    if (saved != null && await _isRecent(file)) return saved;

    try {
      final response = await fetch(Uri.parse('$apiBaseUrl/$place/$year.json'));
      if (response.status == HttpStatus.notFound) return saved;
      if (response.status != HttpStatus.ok) {
        throw HttpException('HTTP ${response.status}');
      }
      // Check the download before saving it, so a bad one never replaces a
      // good saved copy.
      final timetable = Timetable.fromJson(jsonDecode(response.body));
      await _save(file, response.body);
      return timetable;
    } on IOException catch (error) {
      return _fallBack(saved, error);
    } on TimeoutException catch (error) {
      return _fallBack(saved, error);
    } on FormatException catch (error) {
      return _fallBack(saved, error);
    }
  }

  Timetable? _fallBack(Timetable? saved, Object error) {
    log('Download failed ($error); using saved copy: ${saved != null}');
    return saved;
  }

  Future<Timetable?> _readSaved(File file) async {
    try {
      return Timetable.fromJson(jsonDecode(await file.readAsString()));
    } on FileSystemException {
      return null; // Nothing saved yet.
    } on FormatException catch (error) {
      log('Ignoring damaged saved timetable ${file.path}: $error');
      return null;
    }
  }

  Future<bool> _isRecent(File file) async {
    try {
      final age = DateTime.now().difference(await file.lastModified());
      // A negative age means the phone's clock was wrong when it saved.
      return age >= Duration.zero && age < _maxSavedAge;
    } on FileSystemException {
      return false;
    }
  }

  /// Writes to a temporary file first, then renames it into place, so the
  /// saved copy is never half-written if the app is closed mid-save.
  /// A failed save is only logged: the fresh download is still shown.
  Future<void> _save(File file, String body) async {
    // A unique name, so two saves at the same moment never collide.
    final temporary = File(
      '${file.path}.$pid-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    try {
      await cacheDir.create(recursive: true);
      await temporary.writeAsString(body, flush: true);
      await temporary.rename(file.path);
    } on FileSystemException catch (error) {
      // shortcut: a failed rename leaves the .tmp file behind; add a cleanup
      // if storage ever matters.
      log('Could not save ${file.path}: $error');
    }
  }
}
