import 'dart:async';
import 'dart:convert';
import 'dart:developer' show log;

import 'package:flutter/foundation.dart';

import 'package:prayer_times/data/place_times.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/data/widget_payload.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

/// Keeps the home-screen widgets in step with the screen: hands them a new
/// payload whenever the times, the Asr method or the language change.
class WidgetPublisher {
  WidgetPublisher({
    required this.asr,
    required this.publish,
    this.now = DateTime.now,
  }) {
    asr.addListener(republish);
  }

  final ValueListenable<AsrMethod> asr;

  /// Hands the payload (JSON) to the widgets.
  final Future<void> Function(String json) publish;
  final DateTime Function() now;

  ResolvedTimes? _times;
  AppLocalizations? _text;

  /// The screen is showing new times.
  void timesLoaded(ResolvedTimes times) {
    _times = times;
    republish();
  }

  /// The screen's language may have changed. The same language again (the
  /// screen tells us often) changes nothing.
  void textChanged(AppLocalizations text) {
    if (text.localeName == _text?.localeName) return;
    _text = text;
    republish();
  }

  /// Publishes again from today, so the widgets' days never run out while
  /// the app is in use.
  void republish() {
    final (times, text) = (_times, _text);
    if (times == null || text == null) return;
    final payload = widgetPayload(
      times: times,
      now: now(),
      asr: asr.value,
      text: text,
    );
    unawaited(_publish(jsonEncode(payload)));
  }

  Future<void> _publish(String json) async {
    try {
      await publish(json);
    } on Exception catch (error, stack) {
      // The widgets keep their last times; the next change tries again.
      log('Updating the widgets failed', error: error, stackTrace: stack);
    }
  }

  void dispose() => asr.removeListener(republish);
}

/// Publishes nowhere: the default where there are no widgets (and in tests).
Future<void> noWidgets(String json) async {}
