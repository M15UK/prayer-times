import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/settings_screen.dart';

import 'alert_permission_test.dart' show notificationsBlocked;
import 'fake_notifications.dart';

void main() {
  Future<void> pumpSettings(
    WidgetTester tester,
    ValueNotifier<PrayerAlerts> alerts,
    FakeNotifications phone,
  ) => tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SettingsScreen(
        language: ValueNotifier(AppLanguage.phone),
        asrMethod: ValueNotifier(AsrMethod.standard),
        alerts: alerts,
        notifications: phone,
      ),
    ),
  );

  final alertsSwitch = find.widgetWithText(SwitchListTile, 'Prayer alerts');

  testWidgets('the prayer alerts switch is on until switched off, and '
      'switching it on asks the phone', (tester) async {
    final phone = FakeNotifications();
    final alerts = ValueNotifier(PrayerAlerts.askFirst);
    await pumpSettings(tester, alerts, phone);

    expect(tester.widget<SwitchListTile>(alertsSwitch).value, isTrue);

    await tester.tap(alertsSwitch);
    await tester.pump();
    expect(alerts.value, PrayerAlerts.off);
    expect(tester.widget<SwitchListTile>(alertsSwitch).value, isFalse);

    await tester.tap(alertsSwitch);
    await tester.pump();
    expect(phone.asked, ['notify']);
    expect(alerts.value, PrayerAlerts.on);
  });

  testWidgets('stays off, and says why, if the phone blocks notifications', (
    tester,
  ) async {
    final alerts = ValueNotifier(PrayerAlerts.off);
    await pumpSettings(tester, alerts, FakeNotifications(allowed: false));

    await tester.tap(alertsSwitch);
    await tester.pump();

    expect(alerts.value, PrayerAlerts.off);
    expect(find.text(notificationsBlocked), findsOneWidget);
  });
}
