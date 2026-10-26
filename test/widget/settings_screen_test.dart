import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/settings_screen.dart';

import '../unit/data/sample_timetable.dart';
import 'alert_permission_test.dart' show notificationsBlocked;
import 'fake_notifications.dart';

void main() {
  /// Settings with the alerts setting at [alerts], the pretend [phone], and
  /// the [timetable] on screen (null: no times loaded yet).
  Future<void> pumpSettings(
    WidgetTester tester,
    ValueNotifier<PrayerAlerts> alerts,
    FakeNotifications phone, {
    Timetable? timetable,
    Locale locale = const Locale('en'),
  }) {
    // A tall, phone-like screen, so the whole list is built without scrolling.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    return tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SettingsScreen(
          language: ValueNotifier(AppLanguage.phone),
          asrMethod: ValueNotifier(AsrMethod.standard),
          alerts: alerts,
          notifications: phone,
          display: DisplaySettings(),
          timetable: timetable,
        ),
      ),
    );
  }

  testWidgets('opens the Display page', (tester) async {
    await pumpSettings(
      tester,
      ValueNotifier(PrayerAlerts.on),
      FakeNotifications(),
    );

    await tester.tap(find.text('Display'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Time format'), findsOneWidget);
  });

  group('the source of the times on screen', () {
    testWidgets('credits the Umm al-Qura Calendar in both languages', (
      tester,
    ) async {
      final alerts = ValueNotifier(PrayerAlerts.on);
      await pumpSettings(
        tester,
        alerts,
        FakeNotifications(),
        timetable: sampleSaudiTimetable(),
      );
      expect(find.text('Source: Umm al-Qura Calendar'), findsOneWidget);

      await pumpSettings(
        tester,
        alerts,
        FakeNotifications(),
        timetable: sampleSaudiTimetable(),
        locale: const Locale('ar'),
      );
      expect(find.text('المصدر: تقويم أم القرى'), findsOneWidget);
    });

    testWidgets('is left out before any times have loaded', (tester) async {
      await pumpSettings(
        tester,
        ValueNotifier(PrayerAlerts.on),
        FakeNotifications(),
      );

      expect(find.textContaining('Source'), findsNothing);
    });
  });

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
