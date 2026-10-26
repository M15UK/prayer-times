import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:prayer_times/data/phone_notifications.dart';
import 'package:prayer_times/data/prayer_alerts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  // The plugin's own line to Android, answered here instead of by a phone.
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;

  /// Pretends to be an Android phone that does or doesn't allow [exact]
  /// timing, recording every call the plugin makes.
  void pretendAndroid({required bool exact}) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return call.method == 'canScheduleExactNotifications' ? exact : null;
        });
  }

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  /// An alert [minutes] from now (negative: already past).
  PrayerAlert alertIn(int minutes, int id) => (
    id: id,
    at: tz.TZDateTime.now(tz.getLocation('Europe/London'))
        .add(Duration(minutes: minutes)),
    title: 'Asr',
    body: '14:17 · London',
  );

  test('checks exact timing first, cancels only waiting alerts, then sets '
      'each alert still to come', () async {
    pretendAndroid(exact: true);

    await PhoneNotifications().replaceAll([
      alertIn(-1, 1),
      alertIn(60, 2),
      alertIn(120, 3),
    ]);

    expect(calls.map((call) => call.method), [
      'canScheduleExactNotifications',
      'cancelAllPendingNotifications',
      'zonedSchedule',
      'zonedSchedule',
    ]);
    final scheduled = calls.where((call) => call.method == 'zonedSchedule');
    expect(scheduled.map((call) => call.arguments['id']), [2, 3]);
    expect(
      scheduled.map(
        (call) => call.arguments['platformSpecifics']['scheduleMode'],
      ),
      everyElement('exactAllowWhileIdle'),
    );
    expect(scheduled.first.arguments['body'], '14:17 · London');
  });

  test('uses inexact timing when the phone does not allow exact', () async {
    pretendAndroid(exact: false);

    await PhoneNotifications().replaceAll([alertIn(60, 2)]);

    final scheduled = calls.singleWhere(
      (call) => call.method == 'zonedSchedule',
    );
    expect(
      scheduled.arguments['platformSpecifics']['scheduleMode'],
      'inexactAllowWhileIdle',
    );
  });
}
