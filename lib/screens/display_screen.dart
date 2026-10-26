import 'package:flutter/material.dart';

import 'package:prayer_times/data/app_colour.dart';
import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/prayer_name.dart';
import 'package:prayer_times/screens/choice_section.dart';

/// The Display page: theme, colour, time format and which times show. Each
/// choice saves at once and updates the app (and widgets) straight away.
class DisplayScreen extends StatelessWidget {
  const DisplayScreen({super.key, required this.display});

  final DisplaySettings display;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.display)),
      body: ListView(
        children: [
          ChoiceSection(
            heading: text.theme,
            setting: display.themeMode,
            options: [
              (ThemeMode.system, text.asPhone, null),
              (ThemeMode.light, text.themeLight, null),
              (ThemeMode.dark, text.themeDark, null),
            ],
          ),
          const Divider(),
          ChoiceSection(
            heading: text.colour,
            hint: text.colourHint,
            setting: display.colour,
            options: [
              (AppColour.teal, text.colourTeal, null),
              (AppColour.blue, text.colourBlue, null),
              (AppColour.green, text.colourGreen, null),
              (AppColour.purple, text.colourPurple, null),
              (AppColour.amber, text.colourAmber, null),
              (
                AppColour.wallpaper,
                text.colourWallpaper,
                text.colourWallpaperHint,
              ),
            ],
          ),
          const Divider(),
          ChoiceSection(
            heading: text.timeFormat,
            setting: display.clock,
            options: [
              // Flutter learns of a change to the phone's own setting only
              // when the app next starts (the widgets see it at once).
              (ClockFormat.phone, text.asPhone, text.asPhoneClockHint),
              (ClockFormat.twelveHour, text.timeFormat12, null),
              (ClockFormat.twentyFourHour, text.timeFormat24, null),
            ],
          ),
          const Divider(),
          _TimesShown(hiddenTimes: display.hiddenTimes),
        ],
      ),
    );
  }
}

/// A tick box per time; unticked times leave the list and the widgets.
class _TimesShown extends StatelessWidget {
  const _TimesShown({required this.hiddenTimes});

  final ValueNotifier<Set<Prayer>> hiddenTimes;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: hiddenTimes,
      builder: (context, hidden, _) => Column(
        children: [
          SectionHeading(text.timesShown, hint: text.timesShownHint),
          for (final prayer in Prayer.values)
            CheckboxListTile(
              title: Text(prayerName(text, prayer)),
              value: !hidden.contains(prayer),
              // A new set each time, which also saves it.
              onChanged: (shown) => hiddenTimes.value = shown == true
                  ? (Set.of(hidden)..remove(prayer))
                  : {...hidden, prayer},
            ),
        ],
      ),
    );
  }
}
