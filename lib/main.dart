import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/device_location.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/saved_place.dart';
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
  // The Saudi city list is built into the app, so choosing works offline.
  final places = parsePlaces(
    jsonDecode(await rootBundle.loadString('api/v1/saudi/cities.json')),
  );
  final storage = await SharedPreferences.getInstance();
  final place = SavedPlace(storage, places: places);
  runApp(
    PrayerTimesApp(
      loadTimes: (chosen, now) => loadPlaceTimes(
        chosen: chosen,
        now: now,
        places: places,
        repository: repository,
        locate: approximatePosition,
        timeZoneName: phoneTimeZoneName,
      ),
      place: place,
      places: places,
      isFirstLaunch: place.isFirstLaunch,
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
    required this.loadTimes,
    required this.place,
    required this.places,
    required this.asrMethod,
    required this.language,
    this.isFirstLaunch = false,
  });

  /// Loads the times for a chosen place (null: automatic) at a moment.
  final Future<ResolvedTimes> Function(Place? chosen, DateTime now) loadTimes;

  /// The saved choice of place, and every place offered.
  final ValueNotifier<Place?> place;
  final List<Place> places;

  /// The user's choices, shared by the main and settings screens.
  final ValueNotifier<AsrMethod> asrMethod;
  final ValueNotifier<AppLanguage> language;

  /// True on the app's very first run.
  final bool isFirstLaunch;

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
          loadTimes: loadTimes,
          place: place,
          places: places,
          isFirstLaunch: isFirstLaunch,
          asrMethod: asrMethod,
          language: language,
        ),
      ),
    );
  }
}
