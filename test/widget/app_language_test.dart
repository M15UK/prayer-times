import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/main.dart';

import '../unit/data/sample_timetable.dart';

/// Starts the whole app with the phone set to [phoneLanguage] and the app's
/// own Language setting at [chosen].
Future<void> pumpApp(
  WidgetTester tester, {
  required String phoneLanguage,
  AppLanguage chosen = AppLanguage.phone,
}) async {
  tester.platformDispatcher.localesTestValue = [Locale(phoneLanguage)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  await tester.pumpWidget(
    PrayerTimesApp(
      loadTimetable: (_) async => sampleTimetable(),
      asrMethod: ValueNotifier(AsrMethod.standard),
      language: ValueNotifier(chosen),
    ),
  );
  // Two frames, not pumpAndSettle: the countdown ticks every second, so the
  // screen never "settles".
  await tester.pump();
  await tester.pump();
}

/// Checks the app title is [title] and the layout reads in [direction].
void expectTitle(String title, TextDirection direction, WidgetTester tester) {
  final titleFinder = find.text(title);
  expect(titleFinder, findsOneWidget);
  expect(Directionality.of(tester.element(titleFinder)), direction);
}

void main() {
  setUpAll(tzdata.initializeTimeZones);

  testWidgets('follows an English phone by default', (tester) async {
    await pumpApp(tester, phoneLanguage: 'en');

    expectTitle('Prayer Times', TextDirection.ltr, tester);
  });

  testWidgets('follows an Arabic phone by default', (tester) async {
    await pumpApp(tester, phoneLanguage: 'ar');

    expectTitle('مواقيت الصلاة', TextDirection.rtl, tester);
  });

  testWidgets('uses Arabic when chosen, even on an English phone', (
    tester,
  ) async {
    await pumpApp(tester, phoneLanguage: 'en', chosen: AppLanguage.arabic);

    expectTitle('مواقيت الصلاة', TextDirection.rtl, tester);
  });

  testWidgets('uses English when chosen, even on an Arabic phone', (
    tester,
  ) async {
    await pumpApp(tester, phoneLanguage: 'ar', chosen: AppLanguage.english);

    expectTitle('Prayer Times', TextDirection.ltr, tester);
  });

  testWidgets('switches to Arabic from the settings screen', (tester) async {
    await pumpApp(tester, phoneLanguage: 'en');

    await tester.tap(find.byTooltip('Settings'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('العربية'));
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expectTitle('مواقيت الصلاة', TextDirection.rtl, tester);
  });
}
