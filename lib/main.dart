import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/saved_setting.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/timetable_repository.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/home_screen.dart';

Future<void> main() async {
  // Plugins (like the storage folder lookup) need Flutter started first.
  WidgetsFlutterBinding.ensureInitialized();
  // Time zone rules (clock changes) for every place, past and future.
  tzdata.initializeTimeZones();
  // The app's private folder, kept until the app is uninstalled.
  final supportDir = await getApplicationSupportDirectory();
  final repository = TimetableRepository(
    cacheDir: Directory('${supportDir.path}/timetables'),
  );
  // shortcut: London only until Step 6 adds choosing a location.
  final london = tz.getLocation('Europe/London');
  final storage = await SharedPreferences.getInstance();
  runApp(
    PrayerTimesApp(
      // London's year, not the phone's: at 20:00 on 31 December in New York
      // it is already the new year in London.
      loadTimetable: (now) => repository.load(
        place: 'london',
        year: tz.TZDateTime.from(now, london).year,
      ),
      asrMethod: SavedSetting(
        storage,
        key: 'asrMethod',
        values: AsrMethod.values,
        fallback: AsrMethod.standard,
      ),
      language: SavedSetting(
        storage,
        key: 'language',
        values: AppLanguage.values,
        fallback: AppLanguage.phone,
      ),
    ),
  );
}

class PrayerTimesApp extends StatelessWidget {
  const PrayerTimesApp({
    super.key,
    required this.loadTimetable,
    required this.asrMethod,
    required this.language,
  });

  /// Loads the timetable covering a moment, or null if none is available.
  final Future<Timetable?> Function(DateTime now) loadTimetable;

  /// The user's choices, shared by the main and settings screens.
  final ValueNotifier<AsrMethod> asrMethod;
  final ValueNotifier<AppLanguage> language;

  @override
  Widget build(BuildContext context) {
    // Rebuilds the whole app in the new language the moment it is chosen.
    return ValueListenableBuilder(
      valueListenable: language,
      builder: (context, chosen, _) => MaterialApp(
        // The title is translated, so it is built once the language is known.
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        // null follows the phone's language. Arabic also flips the layout to
        // right-to-left automatically.
        locale: chosen.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Light and dark themes; the phone's own setting picks between them.
        theme: ThemeData(colorSchemeSeed: Colors.teal),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.teal,
          brightness: Brightness.dark,
        ),
        home: HomeScreen(
          loadTimetable: loadTimetable,
          asrMethod: asrMethod,
          language: language,
        ),
      ),
    );
  }
}
