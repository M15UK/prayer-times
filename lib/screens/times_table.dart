import 'package:flutter/material.dart';

import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/prayer_name.dart';

/// One row per time: the prayer, its start time and its jama'ah time.
class TimesTable extends StatelessWidget {
  const TimesTable({
    super.key,
    required this.day,
    required this.asr,
    required this.highlight,
  });

  final DayTimes day;
  final AsrMethod asr;
  final Prayer? highlight;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final heading = theme.textTheme.labelLarge;

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
          ExcludeSemantics(child: Text(text.jamaahHeader, style: heading)),
        ]),
        for (final prayer in Prayer.values)
          row(highlighted: prayer == highlight, [
            Text(prayerName(text, prayer), style: theme.textTheme.titleMedium),
            _TimeCell(time: day.startOf(prayer, asr), column: text.startHeader),
            _TimeCell(time: day.jamaah[prayer], column: text.jamaahHeader),
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
