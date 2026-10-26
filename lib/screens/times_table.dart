import 'package:flutter/material.dart';

import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/format_clock.dart';
import 'package:prayer_times/l10n/prayer_name.dart';

/// One row per time shown: the prayer, its start time and its jama'ah time.
class TimesTable extends StatelessWidget {
  const TimesTable({
    super.key,
    required this.day,
    required this.asr,
    required this.highlight,
    required this.is24Hour,
    this.hidden = const {},
  });

  final DayTimes day;
  final AsrMethod asr;
  final Prayer? highlight;
  final bool is24Hour;

  /// Times the user chose not to show (on the Display page).
  final Set<Prayer> hidden;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String? clock(String? time) =>
        time == null ? null : formatClock(time, is24Hour: is24Hour, text: text);
    final heading = theme.textTheme.labelLarge;
    // Some sources (e.g. the Umm al-Qura Calendar) publish no jama'ah times.
    final showJamaah = day.jamaah.isNotEmpty;

    TableRow row(List<Widget> cells, {bool highlighted = false}) => TableRow(
      decoration: highlighted
          ? BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      children: [
        for (final cell in cells)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: cell,
          ),
      ],
    );

    return Table(
      columnWidths: const {0: FlexColumnWidth(2)},
      children: [
        // Screen readers hear each heading with its time instead (_TimeCell).
        row([
          const SizedBox.shrink(),
          ExcludeSemantics(child: Text(text.startHeader, style: heading)),
          if (showJamaah)
            ExcludeSemantics(child: Text(text.jamaahHeader, style: heading)),
        ]),
        for (final prayer in Prayer.values)
          if (!hidden.contains(prayer))
            row(highlighted: prayer == highlight, [
              Text(
                prayerName(text, prayer),
                style: theme.textTheme.titleMedium,
              ),
              _TimeCell(
                time: clock(day.startOf(prayer, asr)),
                column: text.startHeader,
              ),
              if (showJamaah)
                _TimeCell(
                  time: clock(day.jamaah[prayer]),
                  column: text.jamaahHeader,
                ),
            ]),
      ],
    );
  }
}

/// A time that screen readers announce with its column, e.g. "Start 05:04".
/// A missing time shows "—", which screen readers skip.
class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.time, required this.column});

  final String? time;
  final String column;

  @override
  Widget build(BuildContext context) => switch (time) {
    final time? => Text(time, semanticsLabel: '$column $time'),
    null => const ExcludeSemantics(child: Text('—')),
  };
}
