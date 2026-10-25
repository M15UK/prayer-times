import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/home_screen.dart';

import '../unit/data/sample_timetable.dart';

/// 12:09 London time on 25 October 2026 (London is on GMT that day).
final lunchtime = DateTime.utc(2026, 10, 25, 12, 9);

/// Shows the home screen with [loadTimetable] standing in for the internet.
Future<void> pumpHome(
  WidgetTester tester, {
  Future<Timetable?> Function(DateTime now)? loadTimetable,
  AsrMethod asr = AsrMethod.standard,
  DateTime? now,
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HomeScreen(
        loadTimetable: loadTimetable ?? (_) async => sampleTimetable(),
        asrMethod: ValueNotifier(asr),
        language: ValueNotifier(AppLanguage.phone),
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

  testWidgets("shows today's times, dates, source and countdown", (
    tester,
  ) async {
    await pumpHome(tester);

    expect(find.text('05:04'), findsOneWidget); // Fajr start
    expect(find.text('19:30'), findsOneWidget); // Isha jama'ah
    expect(find.text('14:17'), findsOneWidget); // Standard Asr
    expect(find.text('14:57'), findsNothing); // Hanafi Asr only by choice
    expect(find.text('Asr in 2:08:00'), findsOneWidget);
    expect(find.text('Sunday 25 October 2026'), findsOneWidget);
    expect(find.textContaining('14 Jumada al-Ula 1448 AH'), findsOneWidget);
    expect(
      find.textContaining(
        'London Unified Prayer Timetable (East London Mosque)',
      ),
      findsOneWidget,
    );
  });

  testWidgets('shows the Hanafi Asr time when chosen', (tester) async {
    await pumpHome(tester, asr: AsrMethod.hanafi);

    expect(find.text('14:57'), findsOneWidget);
    expect(find.text('14:17'), findsNothing);
    expect(find.text('Asr in 2:48:00'), findsOneWidget);
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

    await pumpHome(tester, loadTimetable: (_) async => calculated);
    expect(
      find.textContaining(
        'Calculated on this phone (Muslim World League method)',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('Calculated (muslimWorldLeague)'), findsNothing);

    await pumpHome(
      tester,
      loadTimetable: (_) async => calculated,
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

    await pumpHome(tester, loadTimetable: (_) async => unknownMethod);

    expect(find.textContaining('Calculated on this phone'), findsOneWidget);
    expect(find.textContaining('Should not be shown'), findsNothing);
  });

  testWidgets('shows prayer names and labels in Arabic', (tester) async {
    await pumpHome(tester, locale: const Locale('ar'));

    expect(find.text('الفجر'), findsOneWidget);
    expect(find.text('العصر بعد 2:08:00'), findsOneWidget);
    expect(find.textContaining('جمادى الأولى'), findsOneWidget);
    expect(find.textContaining('المصدر:'), findsOneWidget);
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

  testWidgets('offers to try again when there are no times', (tester) async {
    var loads = 0;
    await pumpHome(
      tester,
      loadTimetable: (_) async {
        loads++;
        return null;
      },
    );

    expect(find.textContaining("Couldn't load prayer times"), findsOneWidget);

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
}
