/// Plans the prayer alerts: which prayers, when, and what each one says.
/// Pure Dart, so it can be tested without a phone.
library;

import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/format_clock.dart';
import 'package:prayer_times/l10n/prayer_name.dart';

/// The user's choice for prayer alerts. [askFirst] (before the app has asked
/// for permission) counts as on. Saved by name, so never rename these.
enum PrayerAlerts { askFirst, on, off }

/// One alert to show on the phone at [at].
typedef PrayerAlert = ({int id, tz.TZDateTime at, String title, String body});

/// How many days ahead to plan. Five prayers a day keeps this at 50 alerts
/// at most, under the 64 that iOS keeps waiting at once.
const alertDays = 10;

/// A fixed id for [prayer] on its date, e.g. 202610253 for Asr on 25 October
/// 2026. Fixed ids mean replanning only ever replaces an alert already
/// showing with the same prayer's (e.g. Asr moved to the Hanafi time).
int alertId(UpcomingPrayer prayer) =>
    int.parse(prayer.date.replaceAll('-', '')) * 10 + prayer.prayer.index;

/// The alerts for every prayer in the next [alertDays] days of [times],
/// written in [text]'s language. Calculated or adjusted times say so, as on
/// the screen.
List<PrayerAlert> planAlerts({
  required ResolvedTimes times,
  required DateTime now,
  required AsrMethod asr,
  required AppLocalizations text,
  required bool is24Hour,
}) {
  final where = times.place?.nameFor(text.localeName) ?? text.yourLocation;
  final calculated = isCalculated(times.timetable);
  final adjusted = isAdjusted(times.timetable);
  return [
    for (final next in upcomingPrayers(
      times.timetable,
      now,
      asr: asr,
      days: alertDays,
    ))
      (
        id: alertId(next),
        at: next.at,
        title: prayerName(text, next.prayer),
        body: [
          formatClock(next.time, is24Hour: is24Hour, text: text),
          where,
          if (calculated) text.calculated,
          if (adjusted) text.adjustedMark,
        ].join(' · '),
      ),
  ];
}
