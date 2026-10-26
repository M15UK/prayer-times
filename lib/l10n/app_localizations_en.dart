// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Prayer Times';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get startHeader => 'Start';

  @override
  String get jamaahHeader => 'Jama\'ah';

  @override
  String get settings => 'Settings';

  @override
  String get location => 'Location';

  @override
  String get yourLocation => 'Your location';

  @override
  String get useMyLocation => 'Use my location';

  @override
  String get useMyLocationHint =>
      'The nearest official timetable, or times calculated for where you are';

  @override
  String get searchPlaces => 'Search for a city or mosque';

  @override
  String get noPlacesFound => 'No places match';

  @override
  String get choosePlace => 'Choose a place';

  @override
  String get locationUnavailable =>
      'Couldn\'t find your location. Allow location access, or choose a place.';

  @override
  String get calculationUnavailable =>
      'Prayer times can\'t be calculated for where you are (for example, very near the poles). Please choose a place.';

  @override
  String get loadingTimes => 'Loading prayer times';

  @override
  String get hanafiNotPublished =>
      'This timetable only publishes the standard Asr time.';

  @override
  String get sourceUmmAlQura => 'Umm al-Qura Calendar';

  @override
  String get language => 'Language';

  @override
  String get languagePhone => 'Phone\'s language';

  @override
  String get asrTime => 'Asr time';

  @override
  String get asrStandard => 'Standard (Shafi\'i, Maliki, Hanbali)';

  @override
  String get asrStandardHint => 'The earlier Asr time';

  @override
  String get asrHanafiOption => 'Hanafi';

  @override
  String get asrHanafiHint => 'The later Asr time';

  @override
  String nextPrayerIn(String prayer, String countdown) {
    return '$prayer in $countdown';
  }

  @override
  String source(String name) {
    return 'Source: $name';
  }

  @override
  String get calculatedUmmAlQura =>
      'Calculated on this phone (Umm al-Qura method)';

  @override
  String get calculatedMuslimWorldLeague =>
      'Calculated on this phone (Muslim World League method)';

  @override
  String get calculated => 'Calculated on this phone';

  @override
  String hijriDate(int day, String month, int year) {
    return '$day $month $year AH';
  }

  @override
  String hijriMonth(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'Muharram',
      'm2': 'Safar',
      'm3': 'Rabi al-Awwal',
      'm4': 'Rabi al-Thani',
      'm5': 'Jumada al-Ula',
      'm6': 'Jumada al-Akhirah',
      'm7': 'Rajab',
      'm8': 'Sha\'ban',
      'm9': 'Ramadan',
      'm10': 'Shawwal',
      'm11': 'Dhu al-Qa\'dah',
      'm12': 'Dhu al-Hijjah',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get ummAlQuraCalendar => 'Umm al-Qura calendar';

  @override
  String get loadFailed =>
      'Couldn\'t load prayer times. Check your internet connection and try again.';

  @override
  String get retry => 'Try again';

  @override
  String get prayerAlerts => 'Prayer alerts';

  @override
  String get prayerAlertsHint =>
      'A notification when each of the five prayers starts';

  @override
  String get exactAlarmExplain =>
      'To alert you exactly when each prayer starts, Android asks you to allow \"Alarms and reminders\" for this app. Without it, alerts may come late.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get notNow => 'Not now';

  @override
  String get alertsMayBeLate =>
      'Prayer alerts may come late. You can allow exact timing in the phone\'s settings.';

  @override
  String get notificationsBlocked =>
      'Notifications aren\'t allowed for this app, so prayer alerts are off. You can allow them in the phone\'s settings.';

  @override
  String get widgetOpenApp => 'Open the app to update the times';

  @override
  String get calculatedMark => 'Calculated';

  @override
  String hijriMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      'm1': 'Muh',
      'm2': 'Saf',
      'm3': 'Rabi I',
      'm4': 'Rabi II',
      'm5': 'Jum I',
      'm6': 'Jum II',
      'm7': 'Raj',
      'm8': 'Sha',
      'm9': 'Ram',
      'm10': 'Shaw',
      'm11': 'Dhul Q',
      'm12': 'Dhul H',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get am => 'AM';

  @override
  String get pm => 'PM';

  @override
  String get display => 'Display';

  @override
  String get displayHint => 'Theme, colour, time format and times shown';

  @override
  String get theme => 'Theme';

  @override
  String get asPhone => 'As the phone';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get colour => 'Colour';

  @override
  String get colourTeal => 'Teal';

  @override
  String get colourBlue => 'Blue';

  @override
  String get colourGreen => 'Green';

  @override
  String get colourPurple => 'Purple';

  @override
  String get colourAmber => 'Amber';

  @override
  String get colourWallpaper => 'Wallpaper colours';

  @override
  String get colourWallpaperHint =>
      'Android 12 and newer; other phones show teal';

  @override
  String get colourHint => 'Widgets change colour on Android 12 and newer';

  @override
  String get asPhoneClockHint =>
      'A change on the phone shows when the app next starts';

  @override
  String get timeFormat => 'Time format';

  @override
  String get timeFormat12 => '12-hour (5:53 PM)';

  @override
  String get timeFormat24 => '24-hour (17:53)';

  @override
  String get timesShown => 'Times shown';

  @override
  String get timesShownHint =>
      'Hidden times are still counted down to, and their alerts still come.';
}
