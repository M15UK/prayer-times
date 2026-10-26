import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

/// Keeps the phone's waiting alerts in step with the times on the screen:
/// it plans them again whenever the times, the Asr method, the language or
/// the on/off choice changes.
class AlertScheduler {
  AlertScheduler({
    required this.asr,
    required this.alerts,
    required this.clock,
    required this.replaceAll,
    this.now = DateTime.now,
  }) {
    asr.addListener(replan);
    alerts.addListener(replan);
    clock.addListener(replan);
  }

  final ValueListenable<AsrMethod> asr;
  final ValueListenable<PrayerAlerts> alerts;

  /// 12- or 24-hour times in the alerts, or as the phone shows them.
  final ValueListenable<ClockFormat> clock;

  /// Swaps every waiting alert on the phone for these.
  final Future<void> Function(List<PrayerAlert>) replaceAll;
  final DateTime Function() now;

  ResolvedTimes? _times;
  AppLocalizations? _text;

  /// Each replacement waits for the one before, so the latest plan always
  /// lands last.
  Future<void> _queue = Future.value();

  /// The screen is showing new times.
  void timesLoaded(ResolvedTimes times) {
    _times = times;
    replan();
  }

  /// The screen's language may have changed. The same language again (the
  /// screen tells us often) changes nothing.
  void textChanged(AppLocalizations text) {
    if (text.localeName == _text?.localeName) return;
    _text = text;
    replan();
  }

  /// Plans the next [alertDays] days again from now. Also picks up a change
  /// to exact timing made in the phone's settings.
  void replan() {
    final (times, text) = (_times, _text);
    if (times == null || text == null) return;
    final planned = alerts.value == PrayerAlerts.off
        ? <PrayerAlert>[]
        : planAlerts(
            times: times,
            now: now(),
            asr: asr.value,
            text: text,
            is24Hour: clock.value.resolve(phoneIs24Hour: _phoneIs24Hour),
          );
    _queue = _queue.then((_) => _replace(planned));
  }

  // Assumed until the screen reports the phone's own setting.
  bool _phoneIs24Hour = true;

  /// The phone's own 12/24-hour setting, for "as the phone". The same
  /// setting again (the screen tells us often) changes nothing.
  void phoneClockChanged(bool is24Hour) {
    if (is24Hour == _phoneIs24Hour) return;
    _phoneIs24Hour = is24Hour;
    replan();
  }

  Future<void> _replace(List<PrayerAlert> planned) async {
    try {
      await replaceAll(planned);
    } on Exception catch (error, stack) {
      // The next change tries again; nothing else can be done here.
      log('Scheduling prayer alerts failed', error: error, stackTrace: stack);
    }
  }

  void dispose() {
    asr.removeListener(replan);
    alerts.removeListener(replan);
    clock.removeListener(replan);
  }
}
