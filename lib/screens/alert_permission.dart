import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:prayer_times/data/phone_notifications.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

/// Turns prayer alerts on, asking the phone first. If notifications are
/// refused, alerts go off and the user is told how to allow them. If Android
/// won't allow exact timing, explains why it matters before opening its
/// switch.
Future<void> turnOnAlerts(
  BuildContext context, {
  required PhoneNotifications notifications,
  required ValueNotifier<PrayerAlerts> alerts,
}) async {
  try {
    if (!await notifications.askToNotify()) {
      alerts.value = PrayerAlerts.off;
      if (context.mounted) {
        _tell(context, AppLocalizations.of(context).notificationsBlocked);
      }
      return;
    }
    if (!await notifications.canBeExact() && context.mounted) {
      final exact =
          await _explainExactTiming(context) &&
          await notifications.openExactSwitch();
      if (!exact && context.mounted) {
        _tell(context, AppLocalizations.of(context).alertsMayBeLate);
      }
    }
    alerts.value = PrayerAlerts.on;
  } on PlatformException catch (error, stack) {
    // E.g. another permission request is open. The setting stays as it
    // was, so the next try asks again.
    log('Turning on prayer alerts failed', error: error, stackTrace: stack);
  }
}

void _tell(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));

/// Why exact timing matters. True if the user chose to continue.
Future<bool> _explainExactTiming(BuildContext context) async {
  final text = AppLocalizations.of(context);
  final carryOn = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(text.prayerAlerts),
      content: Text(text.exactAlarmExplain),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(text.notNow),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(text.continueLabel),
        ),
      ],
    ),
  );
  return carryOn ?? false; // closed without choosing: "Not now"
}
