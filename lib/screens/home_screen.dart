import 'dart:async';
import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/adjusted_timetable.dart';
import 'package:prayer_times/data/alert_scheduler.dart';
import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/data/phone_notifications.dart';
import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/prayer_clock.dart';
import 'package:prayer_times/data/source_line.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/widget_publisher.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/prayer_name.dart';
import 'package:prayer_times/screens/alert_permission.dart';
import 'package:prayer_times/screens/calculation_screen.dart';
import 'package:prayer_times/screens/place_screen.dart';
import 'package:prayer_times/screens/settings_screen.dart';
import 'package:prayer_times/screens/times_table.dart';

/// Today's prayer times for the chosen place, a countdown to the next
/// prayer, the Gregorian and Hijri dates, and where the times came from.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.loadTimes,
    required this.place,
    required this.places,
    required this.asrMethod,
    required this.language,
    required this.alerts,
    required this.notifications,
    required this.display,
    required this.calculation,
    this.publishWidgets = noWidgets,
    this.isFirstLaunch = false,
    this.now = DateTime.now,
  });

  /// Loads the times for a chosen place (null: automatic) at a moment.
  final Future<ResolvedTimes> Function(Place? chosen, DateTime now) loadTimes;

  /// The saved choice of place (null: automatic), and every place offered.
  final ValueNotifier<Place?> place;
  final List<Place> places;

  /// The user's choices from settings.
  final ValueNotifier<AsrMethod> asrMethod;
  final ValueNotifier<AppLanguage> language;
  final ValueNotifier<PrayerAlerts> alerts;

  /// The phone's notifications, for the prayer alerts.
  final PhoneNotifications notifications;

  /// Hands the home-screen widgets their payload (JSON).
  final Future<void> Function(String json) publishWidgets;

  /// Theme, colour, time format and times shown (the Display page).
  final DisplaySettings display;

  /// How the times are worked out (the Prayer calculation page). [loadTimes]
  /// reads it; any change loads the times again.
  final CalculationSettings calculation;

  /// True on the app's very first run: if there's no location then, the
  /// place list opens by itself.
  final bool isFirstLaunch;

  /// The current time. Tests pass a fixed moment.
  final DateTime Function() now;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // shortcut: loads once; if the app stays open across midnight on
  // 31 December, "Try again" loads the new year. Fix when adding refresh.
  late Future<ResolvedTimes> _times;

  /// Redraws the screen every second, for the countdown.
  late final Timer _ticker;

  /// Keeps the phone's prayer alerts in step with what this screen shows.
  late final AlertScheduler _scheduler;

  /// Keeps the home-screen widgets in step with what this screen shows.
  late final WidgetPublisher _widgets;

  /// Changes when anything that alters the times' look does.
  late final Listenable _timesLook;

  /// The timetable on screen, for Settings to name its source.
  final _shown = ValueNotifier<Timetable?>(null);

  /// Starts loading. Times that load go on to the alerts. The screen shows
  /// any error; it is also logged, so an unexpected one is never invisible
  /// (and never counts as "unhandled" in the moment before the screen
  /// listens).
  Future<ResolvedTimes> _load() {
    _shown.value = null; // until the new times arrive
    final times = widget.loadTimes(widget.place.value, widget.now());
    unawaited(
      times.then<void>(
        // Only the newest load: an older, slower one (e.g. before a minute
        // change) must never reach the alerts and widgets after it.
        (loaded) => identical(times, _times) ? _afterLoad(loaded) : null,
        onError: (Object error, StackTrace stack) =>
            log('Loading prayer times failed', error: error, stackTrace: stack),
      ),
    );
    return times;
  }

  /// Updates the widgets, asks for alert permission the first time, then
  /// plans the alerts.
  Future<void> _afterLoad(ResolvedTimes times) async {
    if (!mounted) return;
    // Before the permission question, which can take a while to answer.
    _shown.value = times.timetable;
    _widgets.timesLoaded(times);
    if (widget.alerts.value == PrayerAlerts.askFirst) {
      await turnOnAlerts(
        context,
        notifications: widget.notifications,
        alerts: widget.alerts,
      );
    }
    if (mounted) _scheduler.timesLoaded(times);
  }

  /// Back at the front: plans the alerts and widgets again, so they never
  /// run out while the app sits in the background, and the alerts pick up
  /// any change to exact timing.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _scheduler.replan();
    _widgets.republish();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduler = AlertScheduler(
      asr: widget.asrMethod,
      alerts: widget.alerts,
      clock: widget.display.clock,
      replaceAll: widget.notifications.replaceAll,
      now: widget.now,
    );
    _widgets = WidgetPublisher(
      asr: widget.asrMethod,
      display: widget.display,
      publish: widget.publishWidgets,
      now: widget.now,
    );
    _timesLook = Listenable.merge([
      widget.asrMethod,
      widget.display.clock,
      widget.display.hiddenTimes,
    ]);
    _times = _load();
    widget.calculation.changes.addListener(_reload);
    _ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => setState(() {}),
    );
    if (widget.isFirstLaunch) {
      // First run and no location: go straight to the place list.
      unawaited(
        _times.then<void>(
          // It worked: save "automatic" (a SavedPlace saves on every set),
          // so later launches aren't treated as the first.
          (_) => widget.place.value = widget.place.value,
          onError: (Object error) {
            if (error is LocationUnavailable && mounted) {
              unawaited(_openPlaces());
            }
          },
        ),
      );
    }
  }

  /// Runs when the language changes too: the alerts follow the screen's.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final text = AppLocalizations.of(context);
    _scheduler.textChanged(text);
    _widgets.textChanged(text);
    // The widgets read the phone's 12/24-hour setting themselves.
    _scheduler.phoneClockChanged(MediaQuery.alwaysUse24HourFormatOf(context));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.calculation.changes.removeListener(_reload);
    _ticker.cancel();
    _scheduler.dispose();
    _widgets.dispose();
    _shown.dispose();
    super.dispose();
  }

  void _reload() {
    // A block body, not `() => _times = ...`: an arrow would return the
    // Future, and setState rejects callbacks that return a Future.
    setState(() {
      _times = _load();
    });
  }

  Future<void> _openPlaces() async {
    final chosen = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => PlaceScreen(place: widget.place, places: widget.places),
      ),
    );
    if (chosen == true && mounted) _reload();
  }

  void _openSettings() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(
        language: widget.language,
        asrMethod: widget.asrMethod,
        alerts: widget.alerts,
        notifications: widget.notifications,
        display: widget.display,
        calculation: widget.calculation,
        timetable: _shown,
      ),
    ),
  );

  void _openCalculation() => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CalculationScreen(
        calculation: widget.calculation,
        asrMethod: widget.asrMethod,
      ),
    ),
  );

  /// What to show while loading, with times, or with a message instead.
  Widget _content(BuildContext context, AsyncSnapshot<ResolvedTimes> loaded) {
    final text = AppLocalizations.of(context);
    return switch (loaded) {
      AsyncSnapshot(connectionState: ConnectionState.waiting) => Center(
        child: CircularProgressIndicator(
          semanticsLabel:
              text.loadingTimes, // finding a location can take a while
        ),
      ),
      // Redraws whenever the Asr, time format or shown times change (and
      // every second).
      AsyncSnapshot(:final data?) => ListenableBuilder(
        listenable: _timesLook,
        builder: (context, _) => _TodayView(
          times: data,
          automatic: widget.place.value == null,
          now: widget.now(),
          asr: widget.asrMethod.value,
          is24Hour: widget.display.clock.value.resolve(
            phoneIs24Hour: MediaQuery.alwaysUse24HourFormatOf(context),
          ),
          hidden: widget.display.hiddenTimes.value,
          onRetry: _reload,
          onChangePlace: _openPlaces,
        ),
      ),
      AsyncSnapshot(error: LocationUnavailable()) => _Notice(
        message: text.locationUnavailable,
        action: text.choosePlace,
        onPressed: _openPlaces,
      ),
      AsyncSnapshot(error: CalculationUnavailable()) => _Notice(
        message: text.calculationUnavailable,
        action: text.choosePlace,
        onPressed: _openPlaces,
        // The user's own calculation settings can cause it too.
        otherAction: text.prayerCalculation,
        onOther: _openCalculation,
      ),
      AsyncSnapshot(error: TimesOutOfOrder()) => _Notice(
        message: text.timesOutOfOrder,
        action: text.prayerCalculation,
        onPressed: _openCalculation,
      ),
      _ => _Notice(
        message: text.loadFailed,
        action: text.retry,
        onPressed: _reload,
      ),
    };
  }

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
      body: FutureBuilder(future: _times, builder: _content),
    );
  }
}

class _TodayView extends StatelessWidget {
  const _TodayView({
    required this.times,
    required this.automatic,
    required this.now,
    required this.asr,
    required this.is24Hour,
    required this.hidden,
    required this.onRetry,
    required this.onChangePlace,
  });

  final ResolvedTimes times;
  final bool automatic;
  final DateTime now;
  final AsrMethod asr;
  final bool is24Hour;
  final Set<Prayer> hidden;
  final VoidCallback onRetry;
  final VoidCallback onChangePlace;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final timetable = times.timetable;
    final zone = tz.getLocation(timetable.timeZone);
    final today = dateIn(zone, now);
    final day = timetable.days[today];
    if (day == null) {
      return _Notice(
        message: text.loadFailed,
        action: text.retry,
        onPressed: onRetry,
      );
    }

    final next = nextPrayer(timetable, now, asr: asr);
    // After Isha the next prayer is tomorrow's Fajr: highlight nothing today.
    final nextToday = next != null && dateIn(zone, next.at) == today;
    final smallText = Theme.of(context).textTheme.bodySmall;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _PlaceButton(
          place: times.place,
          automatic: automatic,
          onPressed: onChangePlace,
        ),
        if (next != null)
          _Countdown(prayer: next.prayer, left: next.at.difference(now)),
        const SizedBox(height: 16),
        _Dates(date: DateTime.parse(today)),
        const SizedBox(height: 16),
        TimesTable(
          day: day,
          asr: asr,
          highlight: nextToday ? next.prayer : null,
          is24Hour: is24Hour,
          hidden: hidden,
        ),
        // Hanafi chosen, but this source only publishes the standard Asr.
        if (asr == AsrMethod.hanafi && day.asrHanafi == null)
          Text(text.hanafiNotPublished, style: smallText),
        const SizedBox(height: 16),
        // Official sources are named in Settings; calculated or adjusted
        // times must always say so here.
        if (isCalculated(timetable) || isAdjusted(timetable))
          _SourceLabel(timetable: timetable),
      ],
    );
  }
}

/// "Asr in 2:08:05": the next prayer and the time left until it starts.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.prayer, required this.left});

  final Prayer prayer;
  final Duration left;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          text.nextPrayerIn(prayerName(text, prayer), formatCountdown(left)),
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Which place the times are for; tap to choose another.
class _PlaceButton extends StatelessWidget {
  const _PlaceButton({
    required this.place,
    required this.automatic,
    required this.onPressed,
  });

  /// Null when the times are calculated for the user's own position.
  final Place? place;
  final bool automatic;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    final icon = automatic
        ? Icons.my_location
        : (place?.isMosque ?? false)
        ? Icons.mosque
        : Icons.place;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Tooltip(
        message: text.location,
        child: TextButton.icon(
          onPressed: onPressed,
          // Screen readers hear "Use my location" for automatic mode.
          icon: Icon(
            icon,
            semanticLabel: automatic ? text.useMyLocation : null,
          ),
          label: Text(place?.nameFor(text.localeName) ?? text.yourLocation),
        ),
      ),
    );
  }
}

/// Shown only for calculated or adjusted times: says so, with an icon, so
/// they can never be mistaken for an official timetable.
class _SourceLabel extends StatelessWidget {
  const _SourceLabel({required this.timetable});

  final Timetable timetable;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Icon(
          isCalculated(timetable) ? Icons.calculate_outlined : Icons.tune,
          size: 16,
          color: style?.color,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            sourceLine(timetable, AppLocalizations.of(context)),
            style: style,
          ),
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

/// A message instead of times, with a way forward (or two).
class _Notice extends StatelessWidget {
  const _Notice({
    required this.message,
    required this.action,
    required this.onPressed,
    this.otherAction,
    this.onOther,
  });

  final String message;
  final String action;
  final VoidCallback onPressed;

  /// An optional second, quieter way forward.
  final String? otherAction;
  final VoidCallback? onOther;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onPressed, child: Text(action)),
            if (otherAction case final other?)
              TextButton(onPressed: onOther, child: Text(other)),
          ],
        ),
      ),
    );
  }
}
