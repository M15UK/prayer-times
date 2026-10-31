import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/app_colour.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/widget_payload.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

import 'sample_places.dart';
import 'sample_timetable.dart';

/// The payload both widget tests share: the Android widget's test reads
/// this same file, so the two sides can't drift apart.
const widgetPayloadFixture = 'test/unit/data/widget_payload_fixture.json';

/// The same payload with every display choice set (sunrise hidden, 12-hour
/// time, wallpaper colours), also read by the Android widget's test.
const widgetPayloadDisplayFixture =
    'test/unit/data/widget_payload_display_fixture.json';

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    // The app's screen loads these with its translations; tests load them here.
    await initializeDateFormatting();
  });

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

  test('marks hidden times, a chosen clock and wallpaper colours, as in the '
      'second shared fixture', () {
    final payload = widgetPayload(
      times: (timetable: sampleTimetable(), place: london),
      now: lunchtime,
      asr: AsrMethod.standard,
      text: english,
      hidden: {Prayer.sunrise},
      clock: ClockFormat.twelveHour,
      colour: AppColour.wallpaper,
    );

    expect(
      jsonDecode(jsonEncode(payload)),
      jsonDecode(File(widgetPayloadDisplayFixture).readAsStringSync()),
    );
  });

  test("gives a fixed colour's widget colours", () {
    final payload = widgetPayload(
      times: (timetable: sampleTimetable(), place: london),
      now: lunchtime,
      asr: AsrMethod.standard,
      text: english,
      colour: AppColour.blue,
    );
    final colours = AppColour.blue.widgetColours!;

    expect(payload['colours'], {
      'card': colours.card,
      'pill': colours.pill,
      'onPill': colours.onPill,
      'icon': colours.icon,
    });
    expect(payload.containsKey('wallpaper'), isFalse);
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

  test('marks adjusted times too', () {
    final payload = widgetPayload(
      times: (
        timetable: adjustTimetable(sampleTimetable(), const {Prayer.fajr: 2}),
        place: london,
      ),
      now: lunchtime,
      asr: AsrMethod.standard,
      text: english,
    );

    expect(payload['calculated'], 'Adjusted');
  });

  test('marks calculated times that are adjusted with both', () {
    final calculated = calculateTimetable(
      latitude: 53.4808,
      longitude: -2.2426,
      timeZone: 'Europe/London',
      year: 2026,
      method: CalculatedMethod.muslimWorldLeague,
    );

    final payload = widgetPayload(
      times: (
        timetable: adjustTimetable(calculated, const {Prayer.fajr: 2}),
        place: null,
      ),
      now: lunchtime,
      asr: AsrMethod.standard,
      text: english,
    );

    expect(payload['calculated'], 'Calculated · Adjusted');
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
    // The widgets show this mark whenever the times aren't official.
    expect(payload['calculated'], 'Calculated');
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

    final today = (payload['days']! as List).first as Map;
    expect(payload['rtl'], isTrue);
    expect(payload['lang'], 'ar');
    expect(payload['place'], 'الرياض');
    expect(payload['calculated'], '');
    expect(payload['openApp'], 'افتح التطبيق لتحديث المواقيت');
    expect(today['date'], contains('أكتوبر'));
    expect(today['hijri'], '14 جمادى الأولى');
    expect(firstRows(payload).first['name'], 'الفجر');
  });
}
