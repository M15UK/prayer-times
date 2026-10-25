import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

/// A Dart 3 switch over an enum: the compiler insists every prayer is
/// covered, so a new one can never be left without a name.
String prayerName(AppLocalizations text, Prayer prayer) => switch (prayer) {
  Prayer.fajr => text.prayerFajr,
  Prayer.sunrise => text.prayerSunrise,
  Prayer.dhuhr => text.prayerDhuhr,
  Prayer.asr => text.prayerAsr,
  Prayer.maghrib => text.prayerMaghrib,
  Prayer.isha => text.prayerIsha,
};
