import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

// Unicode isolate marks (U+2068, U+2069): they keep an English name in one
// piece inside Arabic text, so its closing ")" stays put.
final _isolateStart = String.fromCharCode(0x2068);
final _isolateEnd = String.fromCharCode(0x2069);

/// "Source: …" for [timetable], as the app and its widgets show it.
/// Calculated times say so, so they can never be mistaken for an official
/// timetable.
String sourceLine(Timetable timetable, AppLocalizations text) {
  final name = switch (calculatedMethodOf(timetable)) {
    CalculatedMethod.ummAlQura => text.calculatedUmmAlQura,
    CalculatedMethod.muslimWorldLeague => text.calculatedMuslimWorldLeague,
    // A method this version doesn't know: still say "calculated".
    null when isCalculated(timetable) => text.calculated,
    // The official Saudi credit, translated as agreed with KACST.
    null when timetable.sourceId == 'umm-al-qura' => text.sourceUmmAlQura,
    null => '$_isolateStart${timetable.sourceName}$_isolateEnd',
  };
  return text.source(name);
}
