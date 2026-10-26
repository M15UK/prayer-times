import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';

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
    required this.replaceAll,
    this.now = DateTime.now,
  }) {
    asr.addListener(replan);
    alerts.addListener(replan);
  }

  final ValueListenable<AsrMethod> asr;
  final ValueListenable<PrayerAlerts> alerts;

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
        : planAlerts(times: times, now: now(), asr: asr.value, text: text);
    _queue = _queue.then((_) => _replace(planned));
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
  }
}
