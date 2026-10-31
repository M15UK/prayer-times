import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/adjusted_timetable.dart';
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

  test('names every method the user can choose, in both languages', () {
    expect(
      sourceLine(from('calculated-northAmerica'), english),
      'Source: Calculated on this phone (ISNA method)',
    );
    expect(
      sourceLine(from('calculated-custom'), english),
      'Source: Calculated on this phone (Custom method)',
    );
    expect(
      sourceLine(from('calculated-northAmerica'), arabic),
      'المصدر: محسوبة على هذا الجهاز (طريقة الجمعية الإسلامية لأمريكا '
      'الشمالية)',
    );
  });

  group('adjusted times', () {
    String signed(String change) => '$isolateStart$change$isolateEnd';

    test('say which times moved, and from which source', () {
      final adjusted = adjustTimetable(
        sampleTimetable(sourceName: 'East London Mosque'),
        const {Prayer.fajr: 2, Prayer.isha: -3},
      );

      expect(
        sourceLine(adjusted, english),
        'Adjusted: Fajr ${signed('+2')} min, Isha ${signed('−3')} min from '
        '${isolateStart}East London Mosque$isolateEnd',
      );
    });

    test('say so in Arabic too', () {
      final adjusted = adjustTimetable(sampleSaudiTimetable(), const {
        Prayer.fajr: 2,
      });

      expect(
        sourceLine(adjusted, arabic),
        'معدّلة: الفجر ${signed('+2')} د عن تقويم أم القرى',
      );
    });

    test('still say when they were calculated', () {
      final adjusted = adjustTimetable(
        Timetable(
          sourceId: 'calculated-muslimWorldLeague',
          sourceName: 'Calculated',
          timeZone: 'Europe/London',
          days: sampleTimetable().days,
        ),
        const {Prayer.asr: 1},
      );

      expect(
        sourceLine(adjusted, english),
        'Adjusted: Asr ${signed('+1')} min from Calculated on this phone '
        '(Muslim World League method)',
      );
    });
  });
}
