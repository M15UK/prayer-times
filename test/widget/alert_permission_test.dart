import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/alert_permission.dart';

import 'fake_notifications.dart';

/// What the app says when the phone blocks notifications.
const notificationsBlocked =
    "Notifications aren't allowed for this app, so prayer alerts are off. "
    "You can allow them in the phone's settings.";

void main() {
  /// Shows an empty English screen, then starts turning alerts on with the
  /// pretend [phone] and the alerts setting at [alerts].
  Future<void> turnOn(
    WidgetTester tester,
    FakeNotifications phone,
    ValueNotifier<PrayerAlerts> alerts,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(),
      ),
    );
    unawaited(
      turnOnAlerts(
        tester.element(find.byType(Scaffold)),
        notifications: phone,
        alerts: alerts,
      ),
    );
    await tester.pump();
  }

  const mayBeLate =
      "Prayer alerts may come late. You can allow exact timing in the phone's "
      'settings.';

  testWidgets('asks the phone and turns alerts on, with nothing more to '
      'explain when exact timing is already allowed', (tester) async {
    final phone = FakeNotifications();
    final alerts = ValueNotifier(PrayerAlerts.askFirst);

    await turnOn(tester, phone, alerts);

    expect(phone.asked, ['notify']);
    expect(alerts.value, PrayerAlerts.on);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('explains exact timing, then opens its switch on Continue', (
    tester,
  ) async {
    final phone = FakeNotifications(exact: false);
    final alerts = ValueNotifier(PrayerAlerts.askFirst);

    await turnOn(tester, phone, alerts);
    expect(find.textContaining('Alarms and reminders'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(phone.asked, ['notify', 'exact switch']);
    expect(alerts.value, PrayerAlerts.on);
    expect(find.text(mayBeLate), findsNothing);
  });

  testWidgets('on Not now, turns alerts on but says they may be late', (
    tester,
  ) async {
    final phone = FakeNotifications(exact: false);
    final alerts = ValueNotifier(PrayerAlerts.askFirst);

    await turnOn(tester, phone, alerts);
    await tester.tap(find.text('Not now'));
    await tester.pump();

    expect(phone.asked, ['notify']);
    expect(alerts.value, PrayerAlerts.on);
    expect(find.text(mayBeLate), findsOneWidget);
  });

  testWidgets('if notifications are refused, turns alerts off and says how '
      'to allow them', (tester) async {
    final phone = FakeNotifications(allowed: false, exact: false);
    final alerts = ValueNotifier(PrayerAlerts.askFirst);

    await turnOn(tester, phone, alerts);

    expect(alerts.value, PrayerAlerts.off);
    expect(find.text(notificationsBlocked), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('if the phone fails to answer, leaves the setting as it was', (
    tester,
  ) async {
    final alerts = ValueNotifier(PrayerAlerts.askFirst);

    await turnOn(tester, FakeNotifications(fails: true), alerts);

    expect(alerts.value, PrayerAlerts.askFirst);
  });
}
