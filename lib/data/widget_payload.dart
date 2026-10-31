/// What the home-screen widgets show, saved by the app so the widgets stay
/// right with the app closed. Pure Dart, so it can be tested without a phone.
library;

import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart' show Bidi, DateFormat;
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/app_colour.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/prayer_name.dart';

/// How many days of times the widgets keep: a month without the app.
const widgetDays = 30;

/// The payload's format. The widget ignores any other version.
const widgetPayloadVersion = 2;

/// Everything the widgets show for the next [widgetDays] days of [times]:
/// ready-made text in [text]'s language, and each moment in milliseconds
/// since 1970 (UTC), so the widget needs no time-zone rules of its own.
Map<String, Object> widgetPayload({
  required ResolvedTimes times,
  required DateTime now,
  required AsrMethod asr,
  required AppLocalizations text,
  Set<Prayer> hidden = const {},
  ClockFormat clock = ClockFormat.phone,
  AppColour colour = AppColour.teal,
}) {
  final timetable = times.timetable;
  final zone = tz.getLocation(timetable.timeZone);
  // One date more than shown: each day ends where the next one begins.
  final dates = datesFrom(zone, now, widgetDays + 1);
  return {
    'v': widgetPayloadVersion,
    'rtl': Bidi.isRtlLanguage(text.localeName),
    // For the phone's AM/PM words in 12-hour time.
    'lang': text.localeName,
    'place': times.place?.nameFor(text.localeName) ?? text.yourLocation,
    // Every widget shows this mark, so calculated times never look official.
    'calculated': isCalculated(timetable) ? text.calculatedMark : '',
    'openApp': text.widgetOpenApp,
    // Display choices, left out when they are the defaults. With no
    // 'is24Hour', the widget follows the phone's own setting at each redraw.
    'is24Hour': ?clock.forced24Hour,
    if (colour.widgetColours case final colours?)
      'colours': {
        'card': colours.card,
        'pill': colours.pill,
        'onPill': colours.onPill,
        'icon': colours.icon,
      },
    if (colour == AppColour.wallpaper) 'wallpaper': true,
    'days': [
      for (var i = 0; i < widgetDays; i++)
        if (timetable.days[dates[i]] case final day?)
          _day(zone, dates[i], dates[i + 1], day, asr, text, hidden),
    ],
  };
}

/// One day: when it starts and ends, its two dates, and its six times.
Map<String, Object> _day(
  tz.Location zone,
  String date,
  String nextDate,
  DayTimes day,
  AsrMethod asr,
  AppLocalizations text,
  Set<Prayer> hidden,
) {
  final calendarDate = DateTime.parse(date);
  // The same Umm al-Qura date the app shows, with a short month name.
  final hijri = HijriCalendar.fromDate(calendarDate);
  return {
    'start': _ms(zone, date, '00:00'),
    'end': _ms(zone, nextDate, '00:00'),
    'date': DateFormat('EEE d MMM', text.localeName).format(calendarDate),
    'hijri': '${hijri.hDay} ${text.hijriMonthShort('m${hijri.hMonth}')}',
    'rows': [
      for (final prayer in Prayer.values)
        if (day.startOf(prayer, asr) case final time?)
          {
            'name': prayerName(text, prayer),
            'time': time,
            'at': _ms(zone, date, time),
            'counts': countdownPrayers.contains(prayer),
            // Kept, not dropped: the widget hides its column, so the strip's
            // icons stay with their prayers.
            if (hidden.contains(prayer)) 'hidden': true,
          },
    ],
  };
}

int _ms(tz.Location zone, String date, String time) =>
    momentOf(zone, date, time).millisecondsSinceEpoch;
