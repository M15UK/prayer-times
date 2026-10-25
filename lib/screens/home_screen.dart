import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/settings_screen.dart';

/// Today's prayer times, a countdown to the next prayer, the Gregorian and
/// Hijri dates, and where the times came from.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.loadTimetable,
    required this.asrMethod,
    required this.language,
    this.now = DateTime.now,
  });

  /// Loads the timetable covering [now], or null if none is available.
  final Future<Timetable?> Function(DateTime now) loadTimetable;

  /// The user's choices from settings.
  final ValueNotifier<AsrMethod> asrMethod;
  final ValueNotifier<AppLanguage> language;

  /// The current time. Tests pass a fixed moment.
  final DateTime Function() now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // shortcut: loads once; if the app stays open across midnight on
  // 31 December, "Try again" loads the new year. Fix when adding refresh.
  late Future<Timetable?> _timetable = widget.loadTimetable(widget.now());

  /// A new "now" every second, which redraws the countdown.
  late final Stream<DateTime> _ticks = Stream.periodic(
    const Duration(seconds: 1),
    (_) => widget.now(),
  );

  void _retry() {
    // A block body, not `() => _timetable = ...`: an arrow would return the
    // Future, and setState rejects callbacks that return a Future.
    setState(() {
      _timetable = widget.loadTimetable(widget.now());
    });
  }

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(
        language: widget.language,
        asrMethod: widget.asrMethod,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(text.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: text.settings, // also read out by screen readers
            onPressed: _openSettings,
          ),
        ],
      ),
      body: FutureBuilder(
        future: _timetable,
        builder: (context, loaded) => switch (loaded) {
          AsyncSnapshot(connectionState: ConnectionState.waiting) =>
            const Center(child: CircularProgressIndicator()),
          AsyncSnapshot(:final data?) => StreamBuilder(
            stream: _ticks,
            initialData: widget.now(),
            // Redraws every second, and whenever the Asr setting changes.
            builder: (context, tick) => ValueListenableBuilder(
              valueListenable: widget.asrMethod,
              builder: (context, asr, _) => _TodayView(
                timetable: data,
                now: tick.data ?? widget.now(),
                asr: asr,
                onRetry: _retry,
              ),
            ),
          ),
          _ => _LoadFailed(onRetry: _retry),
        },
      ),
    );
  }
}

class _TodayView extends StatelessWidget {
  const _TodayView({
    required this.timetable,
    required this.now,
    required this.asr,
    required this.onRetry,
  });

  final Timetable timetable;
  final DateTime now;
  final AsrMethod asr;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final zone = tz.getLocation(timetable.timeZone);
    final today = dateIn(zone, now);
    final day = timetable.days[today];
    if (day == null) return _LoadFailed(onRetry: onRetry);

    final next = nextPrayer(timetable, now, asr: asr);
    // After Isha the next prayer is tomorrow's Fajr: highlight nothing today.
    final nextToday = next != null && dateIn(zone, next.at) == today;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (next != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                text.nextPrayerIn(
                  _prayerName(text, next.prayer),
                  formatCountdown(next.at.difference(now)),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        const SizedBox(height: 16),
        _Dates(date: DateTime.parse(today)),
        const SizedBox(height: 16),
        _TimesTable(
          day: day,
          asr: asr,
          highlight: nextToday ? next.prayer : null,
        ),
        const SizedBox(height: 16),
        Text(
          // The isolate marks (U+2068 and U+2069) keep an English name in one
          // piece inside Arabic text, so its closing ")" stays put.
          text.source('\u2068${timetable.sourceName}\u2069'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// The Gregorian date and the Umm al-Qura Hijri date.
class _Dates extends StatelessWidget {
  const _Dates({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    // Only the numbers come from the library; month names are our own,
    // checked in English and Arabic.
    final hijri = HijriCalendar.fromDate(date);
    final hijriDate = text.hijriDate(
      hijri.hDay,
      text.hijriMonth('m${hijri.hMonth}'),
      hijri.hYear,
    );
    return Column(
      children: [
        Text(
          DateFormat('EEEE d MMMM y', text.localeName).format(date),
          style: textTheme.titleMedium,
        ),
        Text(
          '$hijriDate · ${text.ummAlQuraCalendar}',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// One row per time: the prayer, its start time and its jama'ah time.
class _TimesTable extends StatelessWidget {
  const _TimesTable({
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
            Text(_prayerName(text, prayer), style: theme.textTheme.titleMedium),
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

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text.loadFailed, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(text.retry)),
          ],
        ),
      ),
    );
  }
}

/// A Dart 3 switch over an enum: the compiler insists every prayer is
/// covered, so a new one can never be left without a name.
String _prayerName(AppLocalizations text, Prayer prayer) => switch (prayer) {
  Prayer.fajr => text.prayerFajr,
  Prayer.sunrise => text.prayerSunrise,
  Prayer.dhuhr => text.prayerDhuhr,
  Prayer.asr => text.prayerAsr,
  Prayer.maghrib => text.prayerMaghrib,
  Prayer.isha => text.prayerIsha,
};
