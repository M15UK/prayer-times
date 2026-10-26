import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/widget_publisher.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

import 'sample_timetable.dart';

void main() {
  setUpAll(() async {
    tzdata.initializeTimeZones();
    // The app's screen loads these with its translations; tests load them here.
    await initializeDateFormatting();
  });

  final english = lookupAppLocalizations(const Locale('en'));
  final londonTimes = (timetable: sampleTimetable(), place: london);

  late ValueNotifier<AsrMethod> asr;
  // Every payload handed to the widgets, oldest first.
  late List<Map<String, dynamic>> published;
  late DateTime now;

  setUp(() {
    asr = ValueNotifier(AsrMethod.standard);
    published = [];
    now = DateTime.utc(2026, 10, 25, 12, 9);
  });

  /// A publisher whose widgets record each payload, unless [publish] says
  /// otherwise.
  WidgetPublisher start({Future<void> Function(String json)? publish}) {
    final publisher = WidgetPublisher(
      asr: asr,
      publish:
          publish ??
          (json) async =>
              published.add(jsonDecode(json) as Map<String, dynamic>),
      now: () => now,
    );
    addTearDown(publisher.dispose);
    return publisher;
  }

  /// The Asr row of the first day in [payload].
  Map<String, dynamic> firstAsr(Map<String, dynamic> payload) =>
      (payload['days'] as List).first['rows'][3] as Map<String, dynamic>;

  test('publishes once the times and the language are both known', () async {
    final publisher = start()..timesLoaded(londonTimes);
    await pumpEventQueue();
    expect(published, isEmpty);

    publisher.textChanged(english);
    await pumpEventQueue();

    expect(published.single['place'], 'London');
    expect(firstAsr(published.single)['time'], '14:17');
  });

  test('publishes again when the Asr method changes', () async {
    start()
      ..timesLoaded(londonTimes)
      ..textChanged(english);

    asr.value = AsrMethod.hanafi;
    await pumpEventQueue();

    expect(firstAsr(published.last)['time'], '14:57');
  });

  test('publishes again in a new language, but not for the same one', () async {
    final publisher = start()
      ..timesLoaded(londonTimes)
      ..textChanged(english);

    publisher.textChanged(lookupAppLocalizations(const Locale('en')));
    await pumpEventQueue();
    expect(published, hasLength(1));

    publisher.textChanged(lookupAppLocalizations(const Locale('ar')));
    await pumpEventQueue();
    expect(published.last['place'], 'لندن');
  });

  test('republish starts from the current day', () async {
    final publisher = start()
      ..timesLoaded(londonTimes)
      ..textChanged(english);

    now = DateTime.utc(2026, 10, 26, 12);
    publisher.republish();
    await pumpEventQueue();

    // Only the 26th is left of the sample's two days.
    expect(published.last['days'], hasLength(1));
  });

  test('keeps going after the widgets refuse once', () async {
    var calls = 0;
    start(
        publish: (json) async {
          if (++calls == 1) throw Exception('refused');
          published.add(jsonDecode(json) as Map<String, dynamic>);
        },
      )
      ..timesLoaded(londonTimes)
      ..textChanged(english);
    await pumpEventQueue();

    asr.value = AsrMethod.hanafi;
    await pumpEventQueue();

    expect(firstAsr(published.single)['time'], '14:57');
  });

  test('stops listening once disposed', () async {
    final publisher = start()
      ..timesLoaded(londonTimes)
      ..textChanged(english);
    await pumpEventQueue();

    publisher.dispose();
    asr.value = AsrMethod.hanafi;
    await pumpEventQueue();

    expect(published, hasLength(1));
  });
}
