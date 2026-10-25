import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/prayer_name.dart';
import 'package:prayer_times/screens/settings_screen.dart';
import 'package:prayer_times/screens/times_table.dart';

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
                  prayerName(text, next.prayer),
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
        TimesTable(
          day: day,
          asr: asr,
          highlight: nextToday ? next.prayer : null,
        ),
        const SizedBox(height: 16),
        _SourceLabel(timetable: timetable),
      ],
    );
  }
}

/// Unicode isolate marks (U+2068, U+2069): they keep an English name in one
/// piece inside Arabic text, so its closing ")" stays put.
final _isolateStart = String.fromCharCode(0x2068);
final _isolateEnd = String.fromCharCode(0x2069);

/// Where the times came from. Calculated times say so, with an icon, so
/// they can never be mistaken for an official timetable.
class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.timetable});

  final Timetable timetable;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final calculated = isCalculated(timetable);
    final name = switch (calculatedMethodOf(timetable)) {
      CalculatedMethod.ummAlQura => text.calculatedUmmAlQura,
      CalculatedMethod.muslimWorldLeague => text.calculatedMuslimWorldLeague,
      // A method this version doesn't know: still say "calculated".
      null when calculated => text.calculated,
      null => '$_isolateStart${timetable.sourceName}$_isolateEnd',
    };
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        if (calculated) ...[
          Icon(Icons.calculate_outlined, size: 16, color: style?.color),
          const SizedBox(width: 4),
        ],
        Expanded(child: Text(text.source(name), style: style)),
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
