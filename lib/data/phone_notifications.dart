import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:prayer_times/data/prayer_alerts.dart';

/// The phone's own notifications. The only part of the app that talks to
/// the notifications plugin, so screen tests can use a pretend phone.
class PhoneNotifications {
  final _plugin = FlutterLocalNotificationsPlugin();

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  IOSFlutterLocalNotificationsPlugin? get _ios => _plugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  // shortcut: the Android channel name, shown in the phone's settings, is
  // English only; translate it with the Step 11 polish.
  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'prayer_alerts',
      'Prayer alerts',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Gets the plugin ready. It asks for nothing yet: the app asks once it
  /// has times to alert about.
  Future<void> start() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        // shortcut: the app icon may show as a white square in the status
        // bar; add a proper small icon with the Step 11 polish.
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Asks the user to allow notifications. True if they are allowed.
  Future<bool> askToNotify() async {
    final asking =
        _android?.requestNotificationsPermission() ??
        _ios?.requestPermissions(alert: true, sound: true);
    return await asking ?? false;
  }

  /// Whether alerts can come at the exact minute. Only Android limits this.
  Future<bool> canBeExact() async =>
      await _android?.canScheduleExactNotifications() ?? true;

  /// Opens Android's "Alarms and reminders" switch for this app. True if
  /// exact timing is allowed when the user comes back.
  Future<bool> openExactSwitch() async =>
      await _android?.requestExactAlarmsPermission() ?? true;

  /// Swaps every waiting alert for [alerts]. Alerts already showing stay.
  Future<void> replaceAll(List<PrayerAlert> alerts) async {
    // Checked before cancelling, so a failed check can't leave no alerts.
    final mode = await canBeExact()
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    await _plugin.cancelAllPendingNotifications();
    for (final alert in alerts) {
      // The plugin refuses a moment that has passed while planning.
      if (!alert.at.isAfter(DateTime.now())) continue;
      await _plugin.zonedSchedule(
        id: alert.id,
        scheduledDate: alert.at,
        notificationDetails: _details,
        androidScheduleMode: mode,
        title: alert.title,
        body: alert.body,
      );
    }
  }
}
