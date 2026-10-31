import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/clock_format.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/format_clock.dart';

void main() {
  final english = lookupAppLocalizations(const Locale('en'));
  final arabic = lookupAppLocalizations(const Locale('ar'));

  group('formatClock', () {
    test('leaves 24-hour times as the timetable gives them', () {
      expect(formatClock('17:53', is24Hour: true, text: english), '17:53');
    });

    test('shows 12-hour times with AM or PM', () {
      expect(formatClock('17:53', is24Hour: false, text: english), '5:53 PM');
      expect(formatClock('05:04', is24Hour: false, text: english), '5:04 AM');
    });

    test('midnight and noon are 12', () {
      expect(formatClock('00:05', is24Hour: false, text: english), '12:05 AM');
      expect(formatClock('12:30', is24Hour: false, text: english), '12:30 PM');
    });

    test('speaks Arabic, keeping the digits the app uses everywhere', () {
      expect(formatClock('17:53', is24Hour: false, text: arabic), '5:53 م');
      expect(formatClock('05:04', is24Hour: false, text: arabic), '5:04 ص');
    });

    test('shows anything else as it is', () {
      expect(formatClock('soon', is24Hour: false, text: english), 'soon');
      expect(formatClock('25:00', is24Hour: false, text: english), '25:00');
    });
  });

  group('ClockFormat', () {
    test("follows the phone unless one is chosen", () {
      expect(ClockFormat.phone.resolve(phoneIs24Hour: true), isTrue);
      expect(ClockFormat.phone.resolve(phoneIs24Hour: false), isFalse);
      expect(ClockFormat.twelveHour.resolve(phoneIs24Hour: true), isFalse);
      expect(ClockFormat.twentyFourHour.resolve(phoneIs24Hour: false), isTrue);
    });
  });
}
