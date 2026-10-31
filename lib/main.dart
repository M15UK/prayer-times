import 'dart:convert';
import 'dart:developer' show log;
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/device_location.dart';
import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/data/phone_notifications.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/saved_place.dart';
import 'package:prayer_times/data/saved_setting.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/timetable_repository.dart';
import 'package:prayer_times/data/widget_channel.dart';
import 'package:prayer_times/data/widget_publisher.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/app_theme.dart';
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
  final calculation = CalculationSettings.saved(storage);
  final notifications = PhoneNotifications();
  try {
    await notifications.start();
  } on PlatformException catch (error, stack) {
    // The prayer times matter more than the alerts: open the app anyway.
    log('Starting notifications failed', error: error, stackTrace: stack);
  }
  runApp(
    PrayerTimesApp(
      loadTimes: (chosen, now) => loadPlaceTimes(
        chosen: chosen,
        now: now,
        places: places,
        repository: repository,
        locate: approximatePosition,
        timeZoneName: phoneTimeZoneName,
        calculation: calculation.current, // as chosen at this moment
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
      alerts: SavedSetting(
        storage,
        key: 'prayerAlerts',
        values: PrayerAlerts.values,
        fallback: PrayerAlerts.askFirst,
      ),
      notifications: notifications,
      publishWidgets: publishToAndroidWidgets,
      display: DisplaySettings.saved(storage),
      calculation: calculation,
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
    required this.alerts,
    required this.notifications,
    required this.display,
    required this.calculation,
    this.publishWidgets = noWidgets,
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
  final ValueNotifier<PrayerAlerts> alerts;

  /// The phone's notifications, for the prayer alerts.
  final PhoneNotifications notifications;

  /// Hands the home-screen widgets their payload (JSON).
  final Future<void> Function(String json) publishWidgets;

  /// True on the app's very first run.
  final bool isFirstLaunch;

  /// Theme, colour, time format and times shown (the Display page).
  final DisplaySettings display;

  /// How the times are worked out (the Prayer calculation page).
  final CalculationSettings calculation;

  @override
  Widget build(BuildContext context) {
    // Always inside the wallpaper-colour builder, so choosing wallpaper
    // colours never rebuilds the screens (which would close Settings).
    return DynamicColorBuilder(
      builder: (lightWallpaper, darkWallpaper) => ListenableBuilder(
        // The whole app redraws the moment the language, theme or colour
        // is chosen.
        listenable: Listenable.merge([
          language,
          display.themeMode,
          display.colour,
        ]),
        builder: (context, _) => MaterialApp(
          // The title is translated, so it is built once the language is
          // known.
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          // null follows the phone's language. Arabic also flips the layout
          // to right-to-left automatically.
          locale: language.value.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: appTheme(
            display.colour.value,
            Brightness.light,
            lightWallpaper,
          ),
          darkTheme: appTheme(
            display.colour.value,
            Brightness.dark,
            darkWallpaper,
          ),
          // System: the phone's own light/dark setting picks between them.
          themeMode: display.themeMode.value,
          home: _home(),
        ),
      ),
    );
  }

  Widget _home() => HomeScreen(
    loadTimes: loadTimes,
    place: place,
    places: places,
    isFirstLaunch: isFirstLaunch,
    asrMethod: asrMethod,
    language: language,
    alerts: alerts,
    notifications: notifications,
    publishWidgets: publishWidgets,
    display: display,
    calculation: calculation,
  );
}
