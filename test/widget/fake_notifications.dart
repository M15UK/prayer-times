import 'package:flutter/services.dart';

import 'package:prayer_times/data/phone_notifications.dart';
import 'package:prayer_times/data/prayer_alerts.dart';

/// A pretend phone for screen tests: answers permission questions as told
/// and records what the app asks for and which alerts it hands over.
class FakeNotifications implements PhoneNotifications {
  FakeNotifications({
    this.allowed = true,
    this.exact = true,
    this.exactAfterSwitch = true,
    this.fails = false,
  });

  /// Whether the user allows notifications when asked.
  final bool allowed;

  /// Whether asking fails, as the plugin does if a request is already open.
  final bool fails;

  /// Whether exact alarms are allowed now, and after the switch is opened.
  bool exact;
  final bool exactAfterSwitch;

  /// What the app asked the phone for, in order.
  final asked = <String>[];

  /// Every list of alerts handed to the phone, oldest first.
  final replaced = <List<PrayerAlert>>[];

  @override
  Future<void> start() async {}

  @override
  Future<bool> askToNotify() async {
    if (fails) throw PlatformException(code: 'permissionRequestInProgress');
    asked.add('notify');
    return allowed;
  }

  @override
  Future<bool> canBeExact() async => exact;

  @override
  Future<bool> openExactSwitch() async {
    asked.add('exact switch');
    return exact = exactAfterSwitch;
  }

  @override
  Future<void> replaceAll(List<PrayerAlert> alerts) async =>
      replaced.add(alerts);
}
