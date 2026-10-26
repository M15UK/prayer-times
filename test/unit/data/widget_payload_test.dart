import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/widget_payload.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

import 'sample_places.dart';
import 'sample_timetable.dart';

/// The payload both widget tests share: the Android widget's test reads
/// this same file, so the two sides can't drift apart.
const widgetPayloadFixture = 'test/unit/data/widget_payload_fixture.json';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final english = lookupAppLocalizations(const Locale('en'));
  final arabic = lookupAppLocalizations(const Locale('ar'));
  final lunchtime = DateTime.utc(2026, 10, 25, 12, 9);

  /// The rows of the first day in [payload].
  List<Map<String, Object?>> firstRows(Map<String, Object> payload) =>
      ((payload['days']! as List).first as Map)['rows']
          as List<Map<String, Object?>>;

  test('matches the shared fixture: every row of each day the timetable '
      'has, including prayers already past', () {
    final payload = widgetPayload(
      times: (timetable: sampleTimetable(), place: london),
      now: lunchtime,
      asr: AsrMethod.standard,
      text: english,
    );

    expect(
      jsonDecode(jsonEncode(payload)),
      jsonDecode(File(widgetPayloadFixture).readAsStringSync()),
    );
  });

  test('uses the Hanafi Asr time when chosen', () {
    final payload = widgetPayload(
      times: (timetable: sampleTimetable(), place: london),
      now: lunchtime,
      asr: AsrMethod.hanafi,
      text: english,
    );

    expect(firstRows(payload)[3], {
      'name': 'Asr',
      'time': '14:57',
      'at': DateTime.utc(2026, 10, 25, 14, 57).millisecondsSinceEpoch,
      'counts': true,
    });
  });

  test('says when the times are calculated, for your own location, and '
      'covers $widgetDays days', () {
    final calculated = calculateTimetable(
      latitude: 53.4808,
      longitude: -2.2426,
      timeZone: 'Europe/London',
      year: 2026,
      method: CalculatedMethod.muslimWorldLeague,
    );

    final payload = widgetPayload(
      times: (timetable: calculated, place: null),
      now: lunchtime,
      asr: AsrMethod.standard,
      text: english,
    );

    expect(payload['place'], 'Your location');
    // "Calculated" first: on a narrow widget, only the place name is cut.
    expect(payload['placeLine'], 'Calculated on this phone · Your location');
    expect(
      payload['source'],
      'Source: Calculated on this phone (Muslim World League method)',
    );
    expect(payload['days'], hasLength(widgetDays));
  });

  group('day boundaries', () {
    // A full calculated year for London. Late: built inside a test, once the
    // time zones are loaded.
    late final calculatedLondon = calculateTimetable(
      latitude: 51.5072,
      longitude: -0.1276,
      timeZone: 'Europe/London',
      year: 2026,
      method: CalculatedMethod.muslimWorldLeague,
    );

    List<Map<String, Object?>> daysFrom(DateTime now) =>
        widgetPayload(
              times: (timetable: calculatedLondon, place: null),
              now: now,
              asr: AsrMethod.standard,
              text: english,
            )['days']!
            as List<Map<String, Object?>>;

    test('the day the clocks go forward is 23 hours long', () {
      final springDay = daysFrom(DateTime.utc(2026, 3, 29, 12)).first;

      expect(
        (springDay['end']! as int) - (springDay['start']! as int),
        const Duration(hours: 23).inMilliseconds,
      );
    });

    test("stops at the end of the timetable's year, ending at midnight on "
        'New Year', () {
      final days = daysFrom(DateTime.utc(2026, 12, 28, 12));

      expect(days, hasLength(4));
      expect(days.last['end'], DateTime.utc(2027, 1, 1).millisecondsSinceEpoch);
    });
  });

  test('speaks Arabic, right to left, with the Arabic place name', () {
    final payload = widgetPayload(
      times: (timetable: sampleSaudiTimetable(), place: riyadh),
      now: DateTime.utc(2026, 10, 25, 9),
      asr: AsrMethod.standard,
      text: arabic,
    );

    expect(payload['rtl'], isTrue);
    expect(payload['place'], 'الرياض');
    expect(payload['source'], 'المصدر: تقويم أم القرى');
    expect(payload['openApp'], 'افتح التطبيق لتحديث المواقيت');
    expect(firstRows(payload).first['name'], 'الفجر');
  });
}
