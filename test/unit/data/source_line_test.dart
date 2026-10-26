import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/source_line.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

import 'sample_timetable.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final arabic = lookupAppLocalizations(const Locale('ar'));
  final isolateStart = String.fromCharCode(0x2068);
  final isolateEnd = String.fromCharCode(0x2069);

  /// A timetable that says only where it came from.
  Timetable from(String sourceId) => Timetable(
    sourceId: sourceId,
    sourceName: 'Some Mosque',
    timeZone: 'Europe/London',
    days: const {},
  );

  test('names an official timetable, kept in its own direction', () {
    expect(
      sourceLine(sampleTimetable(sourceName: 'East London Mosque'), english),
      'Source: ${isolateStart}East London Mosque$isolateEnd',
    );
  });

  test('credits the Umm al-Qura Calendar in each language', () {
    expect(
      sourceLine(sampleSaudiTimetable(), english),
      'Source: Umm al-Qura Calendar',
    );
    expect(
      sourceLine(sampleSaudiTimetable(), arabic),
      'المصدر: تقويم أم القرى',
    );
  });

  test('says calculated times are calculated, with the method', () {
    expect(
      sourceLine(from('calculated-muslimWorldLeague'), english),
      'Source: Calculated on this phone (Muslim World League method)',
    );
    expect(
      sourceLine(from('calculated-ummAlQura'), english),
      'Source: Calculated on this phone (Umm al-Qura method)',
    );
  });

  test('still says calculated for a method it does not know', () {
    expect(
      sourceLine(from('calculated-someNewMethod'), english),
      'Source: Calculated on this phone',
    );
  });
}
