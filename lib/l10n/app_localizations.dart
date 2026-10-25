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
    Locale('ar'),
    Locale('en'),
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
  /// **'The nearest official timetable, or times calculated for where you are'**
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
  /// **'Prayer times can\'t be calculated for where you are (for example, very near the poles). Please choose a place.'**
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

  /// Source label for times calculated with Saudi Arabia's official method. Must always say they are calculated.
  ///
  /// In en, this message translates to:
  /// **'Calculated on this phone (Umm al-Qura method)'**
  String get calculatedUmmAlQura;

  /// No description provided for @calculatedMuslimWorldLeague.
  ///
  /// In en, this message translates to:
  /// **'Calculated on this phone (Muslim World League method)'**
  String get calculatedMuslimWorldLeague;

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
