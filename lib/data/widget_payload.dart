/// What the home-screen widgets show, saved by the app so the widgets stay
/// right with the app closed. Pure Dart, so it can be tested without a phone.
library;

import 'package:intl/intl.dart' show Bidi;
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/source_line.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/prayer_name.dart';

/// How many days of times the widgets keep: a month without the app.
const widgetDays = 30;

/// The payload's format. The widget ignores any other version.
const widgetPayloadVersion = 1;

/// Everything the widgets show for the next [widgetDays] days of [times]:
/// ready-made text in [text]'s language, and each moment in milliseconds
/// since 1970 (UTC), so the widget needs no time-zone rules of its own.
Map<String, Object> widgetPayload({
  required ResolvedTimes times,
  required DateTime now,
  required AsrMethod asr,
  required AppLocalizations text,
}) {
  final timetable = times.timetable;
  final zone = tz.getLocation(timetable.timeZone);
  final place = times.place?.nameFor(text.localeName) ?? text.yourLocation;
  // One date more than shown: each day ends where the next one begins.
  final dates = datesFrom(zone, now, widgetDays + 1);
  return {
    'v': widgetPayloadVersion,
    'rtl': Bidi.isRtlLanguage(text.localeName),
    'place': place,
    // The small widget has no source line, so it says "calculated" here,
    // first: on a narrow widget only the place name may be cut short.
    'placeLine': [
      if (isCalculated(timetable)) text.calculated,
      place,
    ].join(' · '),
    'source': sourceLine(timetable, text),
    'openApp': text.widgetOpenApp,
    'days': [
      for (var i = 0; i < widgetDays; i++)
        if (timetable.days[dates[i]] case final day?)
          {
            'start': _ms(zone, dates[i], '00:00'),
            'end': _ms(zone, dates[i + 1], '00:00'),
            'rows': [
              for (final prayer in Prayer.values)
                if (day.startOf(prayer, asr) case final time?)
                  {
                    'name': prayerName(text, prayer),
                    'time': time,
                    'at': _ms(zone, dates[i], time),
                    'counts': countdownPrayers.contains(prayer),
                  },
            ],
          },
    ],
  };
}

int _ms(tz.Location zone, String date, String time) =>
    momentOf(zone, date, time).millisecondsSinceEpoch;
