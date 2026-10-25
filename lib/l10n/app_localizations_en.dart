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
      'Prayer times can\'t be calculated this close to the poles. Please choose a place.';

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
}
