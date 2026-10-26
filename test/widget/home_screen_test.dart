import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/saved_place.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/widget_publisher.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/home_screen.dart';

import '../unit/data/sample_places.dart';
import '../unit/data/sample_timetable.dart';
import 'fake_notifications.dart';

/// 12:09 London time on 25 October 2026 (London is on GMT that day).
final lunchtime = DateTime.utc(2026, 10, 25, 12, 9);

/// A loader that shows [timetable] for whichever place is chosen, or for
/// [place] in automatic mode (null: the user's own spot).
Future<ResolvedTimes> Function(Place?, DateTime) showing(
  Timetable timetable, {
  Place? place = london,
}) =>
    (chosen, _) async => (timetable: timetable, place: chosen ?? place);

/// Shows the home screen. [loadTimes] stands in for the internet and the
/// phone's location; by default it shows London's sample timetable.
Future<void> pumpHome(
  WidgetTester tester, {
  Future<ResolvedTimes> Function(Place? chosen, DateTime now)? loadTimes,
  ValueNotifier<Place?>? place,
  bool isFirstLaunch = false,
  AsrMethod asr = AsrMethod.standard,
  PrayerAlerts alerts = PrayerAlerts.on,
  FakeNotifications? notifications,
  Future<void> Function(String json) publishWidgets = noWidgets,
  DateTime? now,
  Locale locale = const Locale('en'),
}) async {
  // A tall, phone-like screen, so the whole page is built without scrolling.
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        loadTimes: loadTimes ?? showing(sampleTimetable()),
        place: place ?? ValueNotifier(london),
        places: samplePlaces,
        isFirstLaunch: isFirstLaunch,
        asrMethod: ValueNotifier(asr),
        language: ValueNotifier(AppLanguage.phone),
        alerts: ValueNotifier(alerts),
        notifications: notifications ?? FakeNotifications(),
        publishWidgets: publishWidgets,
        now: () => now ?? lunchtime,
      ),
    ),
  );
  // One frame to start loading, one to show the result.
  await tester.pump();
  await tester.pump();
}

/// Lets a page transition finish. (pumpAndSettle would wait forever: the
/// countdown ticks every second, so the screen never settles.)
Future<void> finishTransition(WidgetTester tester) async {
  await tester.pump(); // starts the transition
  await tester.pump(const Duration(seconds: 1)); // jumps to its end
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets("shows today's times, dates and countdown, but not the source "
      'of official times', (tester) async {
    await pumpHome(tester);

    expect(find.text('London'), findsOneWidget); // the place button
    expect(find.text('05:04'), findsOneWidget); // Fajr start
    expect(find.text("Jama'ah"), findsOneWidget);
    expect(find.text('19:30'), findsOneWidget); // Isha jama'ah
    expect(find.text('14:17'), findsOneWidget); // Standard Asr
    expect(find.text('14:57'), findsNothing); // Hanafi Asr only by choice
    expect(find.text('Asr in 2:08:00'), findsOneWidget);
    expect(find.text('Sunday 25 October 2026'), findsOneWidget);
    expect(find.textContaining('14 Jumada al-Ula 1448 AH'), findsOneWidget);
    expect(
      find.textContaining('London Unified Prayer Timetable'),
      findsNothing,
    );
  });

  testWidgets('shows the source of the times on screen in Settings', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Settings'));
    await finishTransition(tester);

    expect(
      find.textContaining(
        'Source: ${String.fromCharCode(0x2068)}London Unified Prayer '
        'Timetable (East London Mosque)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the Hanafi Asr time when chosen', (tester) async {
    await pumpHome(tester, asr: AsrMethod.hanafi);

    expect(find.text('14:57'), findsOneWidget);
    expect(find.text('14:17'), findsNothing);
    expect(find.text('Asr in 2:48:00'), findsOneWidget);
    expect(find.textContaining('only publishes the standard'), findsNothing);
  });

  testWidgets('switches to Hanafi from the settings screen', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byTooltip('Settings'));
    await finishTransition(tester);
    await tester.tap(find.text('Hanafi'));
    await tester.pageBack();
    await finishTransition(tester);

    expect(find.text('14:57'), findsOneWidget);
  });

  testWidgets('shows the place, and reloads after choosing another', (
    tester,
  ) async {
    final asked = <Place?>[];
    await pumpHome(
      tester,
      loadTimes: (chosen, now) {
        asked.add(chosen);
        return showing(sampleTimetable())(chosen, now);
      },
    );

    await tester.tap(find.text('London'));
    await finishTransition(tester);
    await tester.tap(find.text('Riyadh'));
    await finishTransition(tester);

    expect(asked, [london, riyadh]);
    expect(find.text('Riyadh'), findsOneWidget);
  });

  group('prayer alerts', () {
    testWidgets('asks permission once the first times load, then hands the '
        'phone alerts for them', (tester) async {
      final phone = FakeNotifications();

      await pumpHome(
        tester,
        alerts: PrayerAlerts.askFirst,
        notifications: phone,
      );

      expect(phone.asked, ['notify']);
      expect(phone.replaced.single.first.title, 'Asr');
      expect(phone.replaced.single.first.body, '14:17 · London');
    });

    testWidgets('follow a newly chosen place', (tester) async {
      final phone = FakeNotifications();
      await pumpHome(tester, notifications: phone);

      await tester.tap(find.text('London'));
      await finishTransition(tester);
      await tester.tap(find.text('Riyadh'));
      await finishTransition(tester);

      expect(phone.replaced.last.first.body, endsWith(' · Riyadh'));
      // Already answered (alerts on), so never asked again.
      expect(phone.asked, isEmpty);
    });

    testWidgets('are planned again when the app comes back to the front', (
      tester,
    ) async {
      final phone = FakeNotifications();
      await pumpHome(tester, notifications: phone);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();

      expect(phone.replaced, hasLength(2));
    });
  });

  testWidgets('hands the home-screen widgets the times on screen, and again '
      'when the app comes back to the front', (tester) async {
    final published = <Map<String, dynamic>>[];
    await pumpHome(
      tester,
      publishWidgets: (json) async =>
          published.add(jsonDecode(json) as Map<String, dynamic>),
    );

    expect(published.single['place'], 'London');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(published, hasLength(2));
  });

  testWidgets('says "Your location" for times calculated for my spot', (
    tester,
  ) async {
    final calculated = calculateTimetable(
      latitude: 53.4808,
      longitude: -2.2426,
      timeZone: 'Europe/London',
      year: 2026,
      method: CalculatedMethod.muslimWorldLeague,
    );

    await pumpHome(
      tester,
      place: ValueNotifier(null),
      loadTimes: showing(calculated, place: null),
    );

    expect(find.text('Your location'), findsOneWidget);
  });

  group('an official Saudi timetable', () {
    final saudi = showing(sampleSaudiTimetable(), place: riyadh);

    testWidgets('hides the Jama\'ah column, which it does not have', (
      tester,
    ) async {
      await pumpHome(tester, place: ValueNotifier(riyadh), loadTimes: saudi);

      expect(find.text('04:38'), findsOneWidget); // Fajr start
      expect(find.text("Jama'ah"), findsNothing);
    });

    testWidgets('notes it only publishes the standard Asr', (tester) async {
      await pumpHome(
        tester,
        place: ValueNotifier(riyadh),
        loadTimes: saudi,
        asr: AsrMethod.hanafi,
      );

      expect(find.text('14:53'), findsOneWidget); // the official Asr
      expect(
        find.text('This timetable only publishes the standard Asr time.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('labels calculated times clearly, in both languages', (
    tester,
  ) async {
    final calculated = calculateTimetable(
      latitude: 51.5072,
      longitude: -0.1276,
      timeZone: 'Europe/London',
      year: 2026,
      method: CalculatedMethod.muslimWorldLeague,
    );

    await pumpHome(tester, loadTimes: showing(calculated));
    expect(
      find.textContaining(
        'Calculated on this phone (Muslim World League method)',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Calculated (muslimWorldLeague)'), findsNothing);

    await pumpHome(
      tester,
      loadTimes: showing(calculated),
      locale: const Locale('ar'),
    );
    expect(find.textContaining('محسوبة على هذا الجهاز'), findsOneWidget);
  });

  testWidgets('labels as calculated even a method it does not know', (
    tester,
  ) async {
    final sample = sampleTimetable();
    final unknownMethod = Timetable(
      sourceId: 'calculated-someNewMethod',
      sourceName: 'Should not be shown as a source name',
      timeZone: sample.timeZone,
      days: sample.days,
    );

    await pumpHome(tester, loadTimes: showing(unknownMethod));

    expect(find.textContaining('Calculated on this phone'), findsOneWidget);
    expect(find.textContaining('Should not be shown'), findsNothing);
  });

  testWidgets('shows prayer names and labels in Arabic', (tester) async {
    await pumpHome(tester, locale: const Locale('ar'));

    expect(find.text('لندن'), findsOneWidget); // the place button
    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('العصر بعد 2:08:00'), findsOneWidget);
    expect(find.textContaining('جمادى الأولى'), findsOneWidget);
    expect(find.textContaining('المصدر:'), findsNothing); // it's in Settings
  });

  testWidgets('tells screen readers which column each time is in', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pumpHome(tester);

    expect(find.bySemanticsLabel('Start 05:04'), findsOneWidget);
    expect(find.bySemanticsLabel("Jama'ah 05:24"), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tells screen readers it is loading', (tester) async {
    final semantics = tester.ensureSemantics();
    final loading = Completer<ResolvedTimes>();

    await pumpHome(tester, loadTimes: (_, _) => loading.future);

    expect(find.bySemanticsLabel('Loading prayer times'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('tells screen readers when the place is automatic', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await pumpHome(
      tester,
      place: ValueNotifier(null),
      loadTimes: showing(sampleTimetable()),
    );
    expect(find.bySemanticsLabel(RegExp('Use my location')), findsOneWidget);
    semantics.dispose();
  });

  group('when there are no times', () {
    testWidgets('explains a missing location and offers the place list', (
      tester,
    ) async {
      await pumpHome(
        tester,
        place: ValueNotifier(null),
        loadTimes: (_, _) async => throw const LocationUnavailable(),
      );

      expect(find.textContaining("Couldn't find your location"), findsOne);
      await tester.tap(find.text('Choose a place'));
      await finishTransition(tester);
      expect(find.text('Use my location'), findsOneWidget);
    });

    testWidgets('explains when times cannot be calculated near the poles', (
      tester,
    ) async {
      await pumpHome(
        tester,
        place: ValueNotifier(null),
        loadTimes: (_, _) async =>
            throw const CalculationUnavailable('80° is inside a polar circle'),
      );

      expect(find.textContaining("can't be calculated"), findsOneWidget);
      expect(find.text('Choose a place'), findsOneWidget);
    });

    testWidgets('opens the place list by itself on a first launch', (
      tester,
    ) async {
      await pumpHome(
        tester,
        place: ValueNotifier(null),
        isFirstLaunch: true,
        loadTimes: (_, _) async => throw const LocationUnavailable(),
      );
      await finishTransition(tester);

      expect(find.text('Use my location'), findsOneWidget);
    });

    testWidgets('a first launch that works is remembered as automatic', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      final saved = SavedPlace(storage, places: samplePlaces);

      await pumpHome(tester, place: saved, isFirstLaunch: saved.isFirstLaunch);

      // So the next launch is not a "first launch" again.
      expect(storage.getString('place'), 'automatic');
    });

    testWidgets('but not on later launches', (tester) async {
      await pumpHome(
        tester,
        place: ValueNotifier(null),
        loadTimes: (_, _) async => throw const LocationUnavailable(),
      );
      await finishTransition(tester);

      expect(find.text('Use my location'), findsNothing);
    });

    testWidgets('offers to try again when loading fails', (tester) async {
      var loads = 0;
      await pumpHome(
        tester,
        loadTimes: (_, _) async {
          loads++;
          throw const FileSystemException('Storage unavailable');
        },
      );

      expect(find.textContaining("Couldn't load prayer times"), findsOne);

      await tester.tap(find.text('Try again'));
      await tester.pump();

      expect(loads, 2);
    });

    testWidgets('offers to try again when today is not in the timetable', (
      tester,
    ) async {
      // The sample only has 25 and 26 October 2026.
      await pumpHome(tester, now: DateTime.utc(2027, 1, 1, 12));

      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
