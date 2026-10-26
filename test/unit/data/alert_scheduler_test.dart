import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/alert_scheduler.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

import 'sample_timetable.dart';

void main() {
  setUpAll(tzdata.initializeTimeZones);

  final english = lookupAppLocalizations(const Locale('en'));
  final londonTimes = (timetable: sampleTimetable(), place: london);

  late ValueNotifier<AsrMethod> asr;
  late ValueNotifier<PrayerAlerts> alerts;
  // Every list of alerts handed to the phone, oldest first.
  late List<List<PrayerAlert>> replaced;

  setUp(() {
    asr = ValueNotifier(AsrMethod.standard);
    alerts = ValueNotifier(PrayerAlerts.askFirst);
    replaced = [];
  });

  /// A scheduler at lunchtime on 25 October, with a fake phone that records
  /// each replacement unless [replaceAll] says otherwise.
  AlertScheduler start({Future<void> Function(List<PrayerAlert>)? replaceAll}) {
    final scheduler = AlertScheduler(
      asr: asr,
      alerts: alerts,
      replaceAll: replaceAll ?? (planned) async => replaced.add(planned),
      now: () => DateTime.utc(2026, 10, 25, 12, 9),
    );
    addTearDown(scheduler.dispose);
    return scheduler;
  }

  /// A scheduler that has already planned London's alerts in English.
  Future<AlertScheduler> planned() async {
    final scheduler = start()
      ..timesLoaded(londonTimes)
      ..textChanged(english);
    await pumpEventQueue();
    return scheduler;
  }

  test('plans once the times and the language are both known '
      '(asking first counts as on)', () async {
    final scheduler = start()..timesLoaded(londonTimes);
    await pumpEventQueue();
    expect(replaced, isEmpty);

    scheduler.textChanged(english);
    await pumpEventQueue();

    expect(replaced.single, hasLength(8));
    expect(replaced.single.first.body, '14:17 · London');
  });

  test('plans again when the Asr method changes', () async {
    await planned();

    asr.value = AsrMethod.hanafi;
    await pumpEventQueue();

    expect(replaced.last.first.body, '14:57 · London');
  });

  test('plans again in a new language, but not for the same one', () async {
    final scheduler = await planned();

    scheduler.textChanged(lookupAppLocalizations(const Locale('en')));
    await pumpEventQueue();
    expect(replaced, hasLength(1));

    scheduler.textChanged(lookupAppLocalizations(const Locale('ar')));
    await pumpEventQueue();
    expect(replaced.last.first.title, 'العصر');
  });

  test(
    'clears every alert when switched off, and plans again when on',
    () async {
      await planned();

      alerts.value = PrayerAlerts.off;
      await pumpEventQueue();
      expect(replaced.last, isEmpty);

      alerts.value = PrayerAlerts.on;
      await pumpEventQueue();
      expect(replaced.last, hasLength(8));
    },
  );

  test('keeps going after the phone refuses once', () async {
    var calls = 0;
    start(
        replaceAll: (planned) async {
          if (++calls == 1) throw Exception('refused');
          replaced.add(planned);
        },
      )
      ..timesLoaded(londonTimes)
      ..textChanged(english);
    await pumpEventQueue();

    asr.value = AsrMethod.hanafi;
    await pumpEventQueue();

    expect(replaced.single.first.body, '14:57 · London');
  });

  test('hands the phone one list at a time, in order', () async {
    final firstDone = Completer<void>();
    final started = <int>[];
    start(
        replaceAll: (planned) async {
          started.add(planned.length);
          if (started.length == 1) await firstDone.future;
        },
      )
      ..timesLoaded(londonTimes)
      ..textChanged(english);
    await pumpEventQueue();

    alerts.value = PrayerAlerts.off;
    await pumpEventQueue();
    expect(started, [8]);

    firstDone.complete();
    await pumpEventQueue();
    expect(started, [8, 0]);
  });

  test('replan plans again from the current moment', () async {
    var now = DateTime.utc(2026, 10, 25, 12, 9);
    final scheduler =
        AlertScheduler(
            asr: asr,
            alerts: alerts,
            replaceAll: (planned) async => replaced.add(planned),
            now: () => now,
          )
          ..timesLoaded(londonTimes)
          ..textChanged(english);
    addTearDown(scheduler.dispose);
    await pumpEventQueue();

    now = DateTime.utc(2026, 10, 25, 20); // after Isha
    scheduler.replan();
    await pumpEventQueue();

    expect(replaced.last.map((alert) => alert.title), [
      'Fajr',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
    ]);
  });

  test('stops listening once disposed', () async {
    final scheduler = await planned();

    scheduler.dispose();
    asr.value = AsrMethod.hanafi;
    await pumpEventQueue();

    expect(replaced, hasLength(1));
  });
}
