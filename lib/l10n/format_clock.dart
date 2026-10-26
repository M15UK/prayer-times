import 'package:prayer_times/l10n/app_localizations.dart';

final _hoursMinutes = RegExp(r'^(\d{2}):(\d{2})$');

/// A timetable time ("17:53") as chosen: unchanged in 24-hour time,
/// otherwise "5:53 PM" (ص/م in Arabic). The digits stay as the app shows
/// them everywhere, like the widgets (WidgetTime.kt). Anything that isn't a
/// valid time is shown as it is.
String formatClock(
  String time, {
  required bool is24Hour,
  required AppLocalizations text,
}) {
  final parts = _hoursMinutes.firstMatch(time);
  final hour = int.tryParse(parts?.group(1) ?? '');
  if (is24Hour || parts == null || hour == null || hour > 23) return time;
  final twelveHour = hour % 12 == 0 ? 12 : hour % 12;
  return '$twelveHour:${parts.group(2)} ${hour < 12 ? text.am : text.pm}';
}
