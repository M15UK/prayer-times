import 'package:flutter/material.dart';

import 'package:prayer_times/data/phone_notifications.dart';
import 'package:prayer_times/data/prayer_alerts.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_language.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/alert_permission.dart';

/// The app's settings: prayer alerts, language and Asr time.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.language,
    required this.asrMethod,
    required this.alerts,
    required this.notifications,
  });

  /// Setting any of these saves it and updates the whole app at once.
  final ValueNotifier<AppLanguage> language;
  final ValueNotifier<AsrMethod> asrMethod;
  final ValueNotifier<PrayerAlerts> alerts;

  /// The phone, asked for permission when alerts are switched on.
  final PhoneNotifications notifications;

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
          _ChoiceSection(
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
          _ChoiceSection(
            heading: text.asrTime,
            setting: asrMethod,
            options: [
              (AsrMethod.standard, text.asrStandard, text.asrStandardHint),
              (AsrMethod.hanafi, text.asrHanafiOption, text.asrHanafiHint),
            ],
          ),
        ],
      ),
    );
  }
}

/// A heading and a one-of-several choice, saved straight into [setting].
class _ChoiceSection<T> extends StatelessWidget {
  const _ChoiceSection({
    required this.heading,
    required this.setting,
    required this.options,
  });

  final String heading;
  final ValueNotifier<T> setting;

  /// Each option: its value, its title, and an optional hint underneath.
  final List<(T, String, String?)> options;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: setting,
      // RadioGroup lets screen readers announce the options as one choice
      // ("1 of 3, selected").
      builder: (context, selected, _) => RadioGroup<T>(
        groupValue: selected,
        onChanged: (option) {
          if (option != null) setting.value = option;
        },
        child: Column(
          children: [
            ListTile(
              title: Semantics(
                header: true,
                child: Text(
                  heading,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            for (final (value, title, hint) in options)
              RadioListTile<T>(
                value: value,
                title: Text(title),
                subtitle: hint == null ? null : Text(hint),
              ),
          ],
        ),
      ),
    );
  }
}
