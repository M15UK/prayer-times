import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/app_colour.dart';
import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/display_screen.dart';

void main() {
  /// The Display page in English, with fresh (unsaved) choices.
  Future<DisplaySettings> pumpDisplay(WidgetTester tester) async {
    // A tall screen, so the whole list is built without scrolling.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final display = DisplaySettings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DisplayScreen(display: display),
      ),
    );
    return display;
  }

  testWidgets('chooses light or dark', (tester) async {
    final display = await pumpDisplay(tester);

    await tester.tap(find.text('Dark'));
    await tester.pump();

    expect(display.themeMode.value, ThemeMode.dark);
  });

  testWidgets('chooses a colour, noting where wallpaper colours work', (
    tester,
  ) async {
    final display = await pumpDisplay(tester);

    expect(
      find.text('Widgets change colour on Android 12 and newer'),
      findsOneWidget,
    );
    expect(
      find.text('Android 12 and newer; other phones show teal'),
      findsOneWidget,
    );
    await tester.tap(find.text('Blue'));
    await tester.pump();

    expect(display.colour.value, AppColour.blue);
  });

  testWidgets('chooses 12- or 24-hour time', (tester) async {
    final display = await pumpDisplay(tester);
    expect(
      find.text('A change on the phone shows when the app next starts'),
      findsOneWidget,
    );

    await tester.tap(find.text('12-hour (5:53 PM)'));
    await tester.pump();

    expect(display.clock.value, ClockFormat.twelveHour);
  });

  testWidgets('hides a time and shows it again', (tester) async {
    final display = await pumpDisplay(tester);
    final sunrise = find.widgetWithText(CheckboxListTile, 'Sunrise');

    await tester.tap(sunrise);
    await tester.pump();
    expect(display.hiddenTimes.value, {Prayer.sunrise});
    expect(tester.widget<CheckboxListTile>(sunrise).value, isFalse);

    await tester.tap(sunrise);
    await tester.pump();
    expect(display.hiddenTimes.value, isEmpty);
  });
}
