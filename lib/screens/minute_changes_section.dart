import 'package:flutter/material.dart';

import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/bidi_text.dart';
import 'package:prayer_times/l10n/prayer_name.dart';
import 'package:prayer_times/screens/choice_section.dart';
import 'package:prayer_times/screens/stepper_tile.dart';

/// A − / + row per time, moving it up to [maxMinuteChange] minutes either
/// way. Changed times are labelled "Adjusted" wherever they show.
class MinuteChangesSection extends StatelessWidget {
  const MinuteChangesSection({super.key, required this.minutes});

  final ValueNotifier<Map<Prayer, int>> minutes;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: minutes,
      builder: (context, changes, _) {
        /// A new map with [prayer] moved by [step]; 0 removes it.
        void move(Prayer prayer, int step) {
          final change = (changes[prayer] ?? 0) + step;
          minutes.value = Map.unmodifiable({
            for (final MapEntry(key: time, value: moved) in {
              ...changes,
              prayer: change,
            }.entries)
              if (moved != 0) time: moved,
          });
        }

        return Column(
          children: [
            SectionHeading(
              text.minuteChanges,
              hint: text.minuteChangesHint(maxMinuteChange),
            ),
            for (final prayer in Prayer.values)
              StepperTile(
                title: prayerName(text, prayer),
                value: text.minutesValue(signedMinutes(changes[prayer] ?? 0)),
                onDecrease: (changes[prayer] ?? 0) > -maxMinuteChange
                    ? () => move(prayer, -1)
                    : null,
                onIncrease: (changes[prayer] ?? 0) < maxMinuteChange
                    ? () => move(prayer, 1)
                    : null,
              ),
          ],
        );
      },
    );
  }
}
