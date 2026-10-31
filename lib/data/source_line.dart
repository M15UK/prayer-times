import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/bidi_text.dart';
import 'package:prayer_times/l10n/prayer_name.dart';

/// "Source: …" for [timetable], as the app and its widgets show it.
/// Calculated times say so, so they can never be mistaken for an official
/// timetable; times the user moved say "Adjusted" and by how much.
String sourceLine(Timetable timetable, AppLocalizations text) {
  final name = _sourceName(timetable, text);
  return isAdjusted(timetable)
      ? text.adjustedFrom(minuteChanges(timetable.adjustments, text), name)
      : text.source(name);
}

String _sourceName(Timetable timetable, AppLocalizations text) =>
    switch (calculatedMethodOf(timetable)) {
      final method? => text.calculatedWith(text.methodName(method.name)),
      // A method this version doesn't know: still say "calculated".
      null when isCalculated(timetable) => text.calculated,
      // The official Saudi credit, translated as agreed with KACST.
      null when timetable.sourceId == 'umm-al-qura' => text.sourceUmmAlQura,
      null => isolated(timetable.sourceName),
    };

/// "Fajr +2 min, Isha −3 min", in the order of the day.
String minuteChanges(Map<Prayer, int> changes, AppLocalizations text) => [
  for (final prayer in Prayer.values)
    if (changes[prayer] case final change? when change != 0)
      text.minuteChange(prayerName(text, prayer), signedMinutes(change)),
].join(text.listSeparator);
