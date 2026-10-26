import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/app_colour.dart';
import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/screens/app_theme.dart';

import 'saved_setting_test.dart' show storageWith;

void main() {
  group('AppColour.widgetColours', () {
    test("teal keeps the widgets' own colours; wallpaper is read by the "
        'widget itself', () {
      expect(AppColour.teal.widgetColours, isNull);
      expect(AppColour.wallpaper.widgetColours, isNull);
    });

    test('any other colour gives a dark card and a light pill', () {
      for (final colour in [
        AppColour.blue,
        AppColour.green,
        AppColour.purple,
        AppColour.amber,
      ]) {
        final colours = colour.widgetColours!;
        expect(Color(colours.card).computeLuminance(), lessThan(0.1));
        expect(Color(colours.pill).computeLuminance(), greaterThan(0.6));
        expect(Color(colours.onPill).computeLuminance(), lessThan(0.1));
      }
    });

    test('each colour looks different', () {
      final cards = {
        for (final colour in AppColour.values) colour.widgetColours?.card,
      }..remove(null);
      expect(cards, hasLength(4));
    });
  });

  group('appTheme', () {
    final wallpaper = ColorScheme.fromSeed(seedColor: Colors.pink);

    test("uses the phone's wallpaper colours when it gives them", () {
      final theme = appTheme(AppColour.wallpaper, Brightness.light, wallpaper);

      expect(theme.colorScheme.primary, wallpaper.primary);
    });

    test('is teal where the phone gives no wallpaper colours', () {
      expect(
        appTheme(AppColour.wallpaper, Brightness.light, null).colorScheme,
        appTheme(AppColour.teal, Brightness.light, null).colorScheme,
      );
    });

    test('grows from the chosen colour, light or dark', () {
      final theme = appTheme(AppColour.blue, Brightness.dark, wallpaper);

      expect(theme.brightness, Brightness.dark);
      expect(
        theme.colorScheme.primary,
        ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ).primary,
      );
    });
  });

  group('DisplaySettings', () {
    test('starts as the app looks today: following the phone, in teal, '
        'with every time shown', () {
      final display = DisplaySettings();

      expect(display.themeMode.value, ThemeMode.system);
      expect(display.colour.value, AppColour.teal);
      expect(display.clock.value, ClockFormat.phone);
      expect(display.hiddenTimes.value, isEmpty);
    });

    test('remembers every choice the next time the app starts', () async {
      final storage = await storageWith({});
      DisplaySettings.saved(storage)
        ..themeMode.value = ThemeMode.dark
        ..colour.value = AppColour.green
        ..clock.value = ClockFormat.twelveHour
        ..hiddenTimes.value = {Prayer.sunrise};

      final again = DisplaySettings.saved(storage);

      expect(again.themeMode.value, ThemeMode.dark);
      expect(again.colour.value, AppColour.green);
      expect(again.clock.value, ClockFormat.twelveHour);
      expect(again.hiddenTimes.value, {Prayer.sunrise});
    });
  });
}
