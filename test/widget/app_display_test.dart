import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/app_colour.dart';
import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/screens/home_screen.dart';

import 'app_language_test.dart' show pumpApp;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  /// The look of the home screen once the app has started.
  ThemeData homeTheme(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(HomeScreen)));

  testWidgets('uses dark when chosen, whatever the phone', (tester) async {
    final display = DisplaySettings()..themeMode.value = ThemeMode.dark;

    await pumpApp(tester, phoneLanguage: 'en', display: display);

    expect(homeTheme(tester).brightness, Brightness.dark);
  });

  testWidgets('grows the whole app from the chosen colour', (tester) async {
    final display = DisplaySettings()..colour.value = AppColour.blue;

    await pumpApp(tester, phoneLanguage: 'en', display: display);

    expect(
      homeTheme(tester).colorScheme.primary,
      ColorScheme.fromSeed(seedColor: Colors.blue).primary,
    );
  });

  testWidgets('is teal for wallpaper colours where the phone gives none', (
    tester,
  ) async {
    final display = DisplaySettings()..colour.value = AppColour.wallpaper;

    await pumpApp(tester, phoneLanguage: 'en', display: display);

    expect(
      homeTheme(tester).colorScheme.primary,
      ColorScheme.fromSeed(seedColor: Colors.teal).primary,
    );
  });
}
