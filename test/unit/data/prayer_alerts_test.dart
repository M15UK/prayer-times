import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

import 'sample_places.dart';
import 'sample_timetable.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final english = lookupAppLocalizations(const Locale('en'));
  final arabic = lookupAppLocalizations(const Locale('ar'));
  final lunchtime = DateTime.utc(2026, 10, 25, 12, 9);

  test('alertId is different for every prayer and fits in 32 bits', () {
    final upcoming = upcomingPrayers(sampleTimetable(), lunchtime, days: 2);
    final ids = upcoming.map(alertId).toSet();

    expect(ids, hasLength(upcoming.length));
    expect(alertId(upcoming.first), 202610253);
    // The last day of 2099 still fits in the 32 bits Android allows.
    expect(
      alertId((
        prayer: Prayer.isha,
        date: '2099-12-31',
        time: '18:00',
        at: upcoming.first.at,
      )),
      lessThan(1 << 31),
    );
  });

  group('planAlerts', () {
    test("names the prayer, its time and the place, without sunrise", () {
      final alerts = planAlerts(
        times: (timetable: sampleTimetable(), place: london),
        now: lunchtime,
        asr: AsrMethod.standard,
        text: english,
        is24Hour: true,
      );

      expect(alerts, hasLength(8));
      expect(alerts.first.title, 'Asr');
      expect(alerts.first.body, '14:17 · London');
      expect(alerts.first.at.toUtc(), DateTime.utc(2026, 10, 25, 14, 17));
      expect(alerts.map((alert) => alert.title), isNot(contains('Sunrise')));
    });

    test('uses the Hanafi Asr time when chosen', () {
      final alerts = planAlerts(
        times: (timetable: sampleTimetable(), place: eastLondonMosque),
        now: lunchtime,
        asr: AsrMethod.hanafi,
        text: english,
        is24Hour: true,
      );

      expect(alerts.first.body, '14:57 · East London Mosque');
    });

    test('says when the times are calculated, for your own location', () {
      final calculated = calculateTimetable(
        latitude: 53.4808,
        longitude: -2.2426,
        timeZone: 'Europe/London',
        year: 2026,
        method: CalculatedMethod.muslimWorldLeague,
      );

      final alerts = planAlerts(
        times: (timetable: calculated, place: null),
        now: lunchtime,
        asr: AsrMethod.standard,
        text: english,
        is24Hour: true,
      );

      // Ten days ahead: today's last three prayers and nine full days. Well
      // under the 64 alerts iOS keeps waiting at once.
      expect(alerts, hasLength(3 + 9 * 5));
      expect(
        alerts.first.body,
        endsWith(' · Your location · Calculated on this phone'),
      );
    });

    test('says when the times are adjusted', () {
      final adjusted = adjustTimetable(sampleTimetable(), const {
        Prayer.asr: 2,
      });

      final alerts = planAlerts(
        times: (timetable: adjusted, place: london),
        now: lunchtime,
        asr: AsrMethod.standard,
        text: english,
        is24Hour: true,
      );

      expect(alerts.first.body, startsWith('14:19 · ')); // published 14:17
      expect(alerts.first.body, endsWith(' · Adjusted'));
    });

    test('says when calculated times are adjusted too', () {
      final calculated = calculateTimetable(
        latitude: 53.4808,
        longitude: -2.2426,
        timeZone: 'Europe/London',
        year: 2026,
        method: CalculatedMethod.muslimWorldLeague,
      );

      final alerts = planAlerts(
        times: (
          timetable: adjustTimetable(calculated, const {Prayer.asr: 2}),
          place: null,
        ),
        now: lunchtime,
        asr: AsrMethod.standard,
        text: english,
        is24Hour: true,
      );

      expect(
        alerts.first.body,
        endsWith(' · Calculated on this phone · Adjusted'),
      );
    });

    test('speaks Arabic, with the Arabic place name', () {
      // 12:00 in Riyadh, before Asr at 14:53.
      final alerts = planAlerts(
        times: (timetable: sampleSaudiTimetable(), place: riyadh),
        now: DateTime.utc(2026, 10, 25, 9),
        asr: AsrMethod.standard,
        text: arabic,
        is24Hour: true,
      );

      expect(alerts.first.title, 'العصر');
      expect(alerts.first.body, '14:53 · الرياض');
    });

    test('writes the time in 12-hour time when chosen', () {
      final alerts = planAlerts(
        times: (timetable: sampleTimetable(), place: london),
        now: lunchtime,
        asr: AsrMethod.standard,
        text: english,
        is24Hour: false,
      );

      expect(alerts.first.body, '2:17 PM · London');
    });
  });
}
