import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
  ];

  /// App name, shown in the top bar and the phone's app switcher.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get appTitle;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// Column heading: when the prayer time begins (adhan).
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startHeader;

  /// Column heading: when the congregation prays (iqamah).
  ///
  /// In en, this message translates to:
  /// **'Jama\'ah'**
  String get jamaahHeader;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @yourLocation.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get yourLocation;

  /// No description provided for @useMyLocation.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

  /// No description provided for @useMyLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Official or calculated times for where you are, as set in Prayer calculation'**
  String get useMyLocationHint;

  /// No description provided for @searchPlaces.
  ///
  /// In en, this message translates to:
  /// **'Search for a city or mosque'**
  String get searchPlaces;

  /// No description provided for @noPlacesFound.
  ///
  /// In en, this message translates to:
  /// **'No places match'**
  String get noPlacesFound;

  /// No description provided for @choosePlace.
  ///
  /// In en, this message translates to:
  /// **'Choose a place'**
  String get choosePlace;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t find your location. Allow location access, or choose a place.'**
  String get locationUnavailable;

  /// No description provided for @calculationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Prayer times can\'t be calculated for where you are with these settings (for example, very near the poles, or with Isha after midnight). Please choose a place, or change Prayer calculation in Settings.'**
  String get calculationUnavailable;

  /// No description provided for @loadingTimes.
  ///
  /// In en, this message translates to:
  /// **'Loading prayer times'**
  String get loadingTimes;

  /// No description provided for @hanafiNotPublished.
  ///
  /// In en, this message translates to:
  /// **'This timetable only publishes the standard Asr time.'**
  String get hanafiNotPublished;

  /// The credit agreed with KACST for official Saudi times. Keep the capital C.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura Calendar'**
  String get sourceUmmAlQura;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languagePhone.
  ///
  /// In en, this message translates to:
  /// **'Phone\'s language'**
  String get languagePhone;

  /// No description provided for @asrTime.
  ///
  /// In en, this message translates to:
  /// **'Asr time'**
  String get asrTime;

  /// No description provided for @asrStandard.
  ///
  /// In en, this message translates to:
  /// **'Standard (Shafi\'i, Maliki, Hanbali)'**
  String get asrStandard;

  /// No description provided for @asrStandardHint.
  ///
  /// In en, this message translates to:
  /// **'The earlier Asr time'**
  String get asrStandardHint;

  /// No description provided for @asrHanafiOption.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get asrHanafiOption;

  /// No description provided for @asrHanafiHint.
  ///
  /// In en, this message translates to:
  /// **'The later Asr time'**
  String get asrHanafiHint;

  /// Countdown to the next prayer.
  ///
  /// In en, this message translates to:
  /// **'{prayer} in {countdown}'**
  String nextPrayerIn(String prayer, String countdown);

  /// Where the times on screen came from.
  ///
  /// In en, this message translates to:
  /// **'Source: {name}'**
  String source(String name);

  /// Source label for calculated times, with the method's name. Must always say they are calculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated on this phone ({method} method)'**
  String calculatedWith(String method);

  /// A calculation method's name, as listed and inside calculatedWith; method is its id.
  ///
  /// In en, this message translates to:
  /// **'{method, select, algerian{Algerian} dubai{Dubai} egyptian{Egyptian} france{French UOIF} gulfRegion{Gulf} indonesian{Indonesian} jafari{Jafari} jordan{Jordanian} karachi{Karachi} kuwait{Kuwaiti} moonsightingCommittee{Moonsighting Committee} morocco{Moroccan} muslimWorldLeague{Muslim World League} northAmerica{ISNA} portugal{Portuguese} qatar{Qatari} russia{Russian} singapore{Singapore} tehran{Tehran} tunisia{Tunisian} turkiye{Turkish Diyanet} ummAlQura{Umm al-Qura} custom{Custom} other{}}'**
  String methodName(String method);

  /// Source label for times the user moved by some minutes. Must always say they are adjusted.
  ///
  /// In en, this message translates to:
  /// **'Adjusted: {changes} from {source}'**
  String adjustedFrom(String changes, String source);

  /// No description provided for @minuteChange.
  ///
  /// In en, this message translates to:
  /// **'{prayer} {change} min'**
  String minuteChange(String prayer, String change);

  /// No description provided for @listSeparator.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listSeparator;

  /// No description provided for @adjustedMark.
  ///
  /// In en, this message translates to:
  /// **'Adjusted'**
  String get adjustedMark;

  /// No description provided for @timesOutOfOrder.
  ///
  /// In en, this message translates to:
  /// **'Your minute changes put the prayer times out of order. Please change them.'**
  String get timesOutOfOrder;

  /// No description provided for @calculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated on this phone'**
  String get calculated;

  /// No description provided for @hijriDate.
  ///
  /// In en, this message translates to:
  /// **'{day} {month} {year} AH'**
  String hijriDate(int day, String month, int year);

  /// Hijri month name; month is m1 to m12.
  ///
  /// In en, this message translates to:
  /// **'{month, select, m1{Muharram} m2{Safar} m3{Rabi al-Awwal} m4{Rabi al-Thani} m5{Jumada al-Ula} m6{Jumada al-Akhirah} m7{Rajab} m8{Sha\'ban} m9{Ramadan} m10{Shawwal} m11{Dhu al-Qa\'dah} m12{Dhu al-Hijjah} other{}}'**
  String hijriMonth(String month);

  /// No description provided for @ummAlQuraCalendar.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura calendar'**
  String get ummAlQuraCalendar;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load prayer times. Check your internet connection and try again.'**
  String get loadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @prayerAlerts.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts'**
  String get prayerAlerts;

  /// No description provided for @prayerAlertsHint.
  ///
  /// In en, this message translates to:
  /// **'A notification when each of the five prayers starts'**
  String get prayerAlertsHint;

  /// No description provided for @exactAlarmExplain.
  ///
  /// In en, this message translates to:
  /// **'To alert you exactly when each prayer starts, Android asks you to allow \"Alarms and reminders\" for this app. Without it, alerts may come late.'**
  String get exactAlarmExplain;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @alertsMayBeLate.
  ///
  /// In en, this message translates to:
  /// **'Prayer alerts may come late. You can allow exact timing in the phone\'s settings.'**
  String get alertsMayBeLate;

  /// No description provided for @notificationsBlocked.
  ///
  /// In en, this message translates to:
  /// **'Notifications aren\'t allowed for this app, so prayer alerts are off. You can allow them in the phone\'s settings.'**
  String get notificationsBlocked;

  /// No description provided for @widgetOpenApp.
  ///
  /// In en, this message translates to:
  /// **'Open the app to update the times'**
  String get widgetOpenApp;

  /// No description provided for @calculatedMark.
  ///
  /// In en, this message translates to:
  /// **'Calculated'**
  String get calculatedMark;

  /// Short Hijri month name for the widgets; month is m1 to m12.
  ///
  /// In en, this message translates to:
  /// **'{month, select, m1{Muh} m2{Saf} m3{Rabi I} m4{Rabi II} m5{Jum I} m6{Jum II} m7{Raj} m8{Sha} m9{Ram} m10{Shaw} m11{Dhul Q} m12{Dhul H} other{}}'**
  String hijriMonthShort(String month);

  /// No description provided for @am.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get am;

  /// No description provided for @pm.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pm;

  /// No description provided for @display.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get display;

  /// No description provided for @displayHint.
  ///
  /// In en, this message translates to:
  /// **'Theme, colour, time format and times shown'**
  String get displayHint;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @asPhone.
  ///
  /// In en, this message translates to:
  /// **'As the phone'**
  String get asPhone;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @colour.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get colour;

  /// No description provided for @colourTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get colourTeal;

  /// No description provided for @colourBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colourBlue;

  /// No description provided for @colourGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colourGreen;

  /// No description provided for @colourPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colourPurple;

  /// No description provided for @colourAmber.
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get colourAmber;

  /// No description provided for @colourWallpaper.
  ///
  /// In en, this message translates to:
  /// **'Wallpaper colours'**
  String get colourWallpaper;

  /// No description provided for @colourWallpaperHint.
  ///
  /// In en, this message translates to:
  /// **'Android 12 and newer; other phones show teal'**
  String get colourWallpaperHint;

  /// No description provided for @colourHint.
  ///
  /// In en, this message translates to:
  /// **'Widgets change colour on Android 12 and newer'**
  String get colourHint;

  /// No description provided for @asPhoneClockHint.
  ///
  /// In en, this message translates to:
  /// **'A change on the phone shows when the app next starts'**
  String get asPhoneClockHint;

  /// No description provided for @timeFormat.
  ///
  /// In en, this message translates to:
  /// **'Time format'**
  String get timeFormat;

  /// No description provided for @timeFormat12.
  ///
  /// In en, this message translates to:
  /// **'12-hour (5:53 PM)'**
  String get timeFormat12;

  /// No description provided for @timeFormat24.
  ///
  /// In en, this message translates to:
  /// **'24-hour (17:53)'**
  String get timeFormat24;

  /// No description provided for @timesShown.
  ///
  /// In en, this message translates to:
  /// **'Times shown'**
  String get timesShown;

  /// No description provided for @timesShownHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden times are still counted down to, and their alerts still come.'**
  String get timesShownHint;

  /// No description provided for @prayerCalculation.
  ///
  /// In en, this message translates to:
  /// **'Prayer calculation'**
  String get prayerCalculation;

  /// No description provided for @prayerCalculationHint.
  ///
  /// In en, this message translates to:
  /// **'Method, Asr, high latitudes and minute changes'**
  String get prayerCalculationHint;

  /// No description provided for @officialFirst.
  ///
  /// In en, this message translates to:
  /// **'Official timetables first'**
  String get officialFirst;

  /// No description provided for @officialFirstOn.
  ///
  /// In en, this message translates to:
  /// **'Official times where there\'s one (London, Saudi Arabia); your method everywhere else'**
  String get officialFirstOn;

  /// No description provided for @officialFirstOff.
  ///
  /// In en, this message translates to:
  /// **'Your method everywhere, always labelled Calculated'**
  String get officialFirstOff;

  /// No description provided for @method.
  ///
  /// In en, this message translates to:
  /// **'Method'**
  String get method;

  /// No description provided for @methodAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get methodAutomatic;

  /// No description provided for @methodAutomaticHint.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura in Saudi Arabia, Muslim World League elsewhere'**
  String get methodAutomaticHint;

  /// No description provided for @angleOf.
  ///
  /// In en, this message translates to:
  /// **'{prayer} {angle}'**
  String angleOf(String prayer, String angle);

  /// No description provided for @minutesAfterSunset.
  ///
  /// In en, this message translates to:
  /// **'{prayer} {minutes} min after sunset'**
  String minutesAfterSunset(String prayer, int minutes);

  /// No description provided for @limitedBySeason.
  ///
  /// In en, this message translates to:
  /// **'limited by season'**
  String get limitedBySeason;

  /// No description provided for @customAngles.
  ///
  /// In en, this message translates to:
  /// **'Custom angles'**
  String get customAngles;

  /// No description provided for @customAnglesHint.
  ///
  /// In en, this message translates to:
  /// **'How far the sun is below the horizon at each time'**
  String get customAnglesHint;

  /// No description provided for @byAngle.
  ///
  /// In en, this message translates to:
  /// **'Angle'**
  String get byAngle;

  /// No description provided for @byMinutesAfterSunset.
  ///
  /// In en, this message translates to:
  /// **'Minutes after sunset'**
  String get byMinutesAfterSunset;

  /// No description provided for @atSunset.
  ///
  /// In en, this message translates to:
  /// **'At sunset'**
  String get atSunset;

  /// No description provided for @highLatitude.
  ///
  /// In en, this message translates to:
  /// **'High-latitude rule'**
  String get highLatitude;

  /// No description provided for @highLatitudeHint.
  ///
  /// In en, this message translates to:
  /// **'For places far from the equator, where the sky doesn\'t get dark enough, such as UK summers'**
  String get highLatitudeHint;

  /// No description provided for @highLatitudeAutomaticHint.
  ///
  /// In en, this message translates to:
  /// **'Seventh of the night beyond 48°, middle of the night nearer the equator'**
  String get highLatitudeAutomaticHint;

  /// No description provided for @middleOfTheNight.
  ///
  /// In en, this message translates to:
  /// **'Middle of the night'**
  String get middleOfTheNight;

  /// No description provided for @middleOfTheNightHint.
  ///
  /// In en, this message translates to:
  /// **'Not for UK summers: Isha would fall after midnight'**
  String get middleOfTheNightHint;

  /// No description provided for @seventhOfTheNight.
  ///
  /// In en, this message translates to:
  /// **'Seventh of the night'**
  String get seventhOfTheNight;

  /// No description provided for @twilightAngle.
  ///
  /// In en, this message translates to:
  /// **'Twilight angle'**
  String get twilightAngle;

  /// No description provided for @minuteChanges.
  ///
  /// In en, this message translates to:
  /// **'Minute changes'**
  String get minuteChanges;

  /// No description provided for @minuteChangesHint.
  ///
  /// In en, this message translates to:
  /// **'Move a time earlier or later, by up to {max} minutes. Changed times are labelled Adjusted.'**
  String minuteChangesHint(int max);

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String minutesValue(String minutes);

  /// Screen-reader label for a minus button.
  ///
  /// In en, this message translates to:
  /// **'Decrease {name}'**
  String decrease(String name);

  /// Screen-reader label for a plus button.
  ///
  /// In en, this message translates to:
  /// **'Increase {name}'**
  String increase(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
