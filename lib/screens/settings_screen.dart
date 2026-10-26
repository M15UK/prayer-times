import 'package:flutter/material.dart';

import 'package:prayer_times/data/display_settings.dart';
import 'package:prayer_times/data/phone_notifications.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/source_line.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/alert_permission.dart';
import 'package:prayer_times/screens/choice_section.dart';
import 'package:prayer_times/screens/display_screen.dart';

/// The app's settings: prayer alerts, the Display page, language and Asr
/// time, and where the times on screen came from.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.language,
    required this.asrMethod,
    required this.alerts,
    required this.notifications,
    required this.display,
    this.timetable,
  });

  /// Setting any of these saves it and updates the whole app at once.
  final ValueNotifier<AppLanguage> language;
  final ValueNotifier<AsrMethod> asrMethod;
  final ValueNotifier<PrayerAlerts> alerts;

  /// The phone, asked for permission when alerts are switched on.
  final PhoneNotifications notifications;

  /// Theme, colour, time format and times shown (the Display page).
  final DisplaySettings display;

  /// The times on screen, for their source (null: none loaded yet).
  final Timetable? timetable;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.settings)),
      body: ListView(
        children: [
          ValueListenableBuilder(
            valueListenable: alerts,
            builder: (context, choice, _) => SwitchListTile(
              title: Text(text.prayerAlerts),
              subtitle: Text(text.prayerAlertsHint),
              // Not yet asked counts as on.
              value: choice != PrayerAlerts.off,
              onChanged: (on) => on
                  ? turnOnAlerts(
                      context,
                      notifications: notifications,
                      alerts: alerts,
                    )
                  : alerts.value = PrayerAlerts.off,
            ),
          ),
          const Divider(),
          ListTile(
            title: Text(text.display),
            subtitle: Text(text.displayHint),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => DisplayScreen(display: display),
              ),
            ),
          ),
          const Divider(),
          ChoiceSection(
            heading: text.language,
            setting: language,
            options: [
              (AppLanguage.phone, text.languagePhone, null),
              // Each language is named in itself, so anyone can find theirs.
              (AppLanguage.english, 'English', null),
              (AppLanguage.arabic, 'العربية', null),
            ],
          ),
          const Divider(),
          ChoiceSection(
            heading: text.asrTime,
            setting: asrMethod,
            options: [
              (AsrMethod.standard, text.asrStandard, text.asrStandardHint),
              (AsrMethod.hanafi, text.asrHanafiOption, text.asrHanafiHint),
            ],
          ),
          if (timetable case final shown?) ...[
            const Divider(),
            ListTile(title: Text(sourceLine(shown, text))),
          ],
        ],
      ),
    );
  }
}
