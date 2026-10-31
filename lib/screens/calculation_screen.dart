import 'package:flutter/material.dart';

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/source_line.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/bidi_text.dart';
import 'package:prayer_times/screens/choice_section.dart';
import 'package:prayer_times/screens/custom_angles_section.dart';
import 'package:prayer_times/screens/minute_changes_section.dart';

/// The Prayer calculation page: official timetables first or not, the
/// method (and Custom angles), the high-latitude rule, Asr, and minute
/// changes. Each choice saves at once and the times are worked out again.
class CalculationScreen extends StatelessWidget {
  const CalculationScreen({
    super.key,
    required this.calculation,
    required this.asrMethod,
  });

  final CalculationSettings calculation;
  final ValueNotifier<AsrMethod> asrMethod;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.prayerCalculation)),
      body: ListView(
        children: [
          ValueListenableBuilder(
            valueListenable: calculation.officialFirst,
            builder: (context, on, _) => SwitchListTile(
              title: Text(text.officialFirst),
              subtitle: Text(on ? text.officialFirstOn : text.officialFirstOff),
              value: on,
              onChanged: (choice) => calculation.officialFirst.value = choice,
            ),
          ),
          const Divider(),
          ValueListenableBuilder(
            valueListenable: calculation.method,
            builder: (context, method, _) => Column(
              children: [
                ListTile(
                  title: Text(text.method),
                  subtitle: Text(_methodTitle(text, method)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => _MethodScreen(calculation: calculation),
                    ),
                  ),
                ),
                if (method == CalculatedMethod.custom)
                  CustomAnglesSection(
                    key: const Key('customAngles'),
                    custom: calculation.custom,
                  ),
              ],
            ),
          ),
          const Divider(),
          ChoiceSection(
            heading: text.highLatitude,
            hint: text.highLatitudeHint,
            setting: calculation.highLatitude,
            options: [
              (
                HighLatitude.automatic,
                text.methodAutomatic,
                text.highLatitudeAutomaticHint,
              ),
              (
                HighLatitude.middleOfTheNight,
                text.middleOfTheNight,
                text.middleOfTheNightHint,
              ),
              (HighLatitude.seventhOfTheNight, text.seventhOfTheNight, null),
              (HighLatitude.twilightAngle, text.twilightAngle, null),
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
          const Divider(),
          MinuteChangesSection(
            key: const Key('minuteChanges'),
            minutes: calculation.minutes,
          ),
        ],
      ),
    );
  }
}

/// Every method, each with its angles underneath.
class _MethodScreen extends StatelessWidget {
  const _MethodScreen({required this.calculation});

  final CalculationSettings calculation;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.method)),
      body: ValueListenableBuilder(
        // The Custom method's hint shows the user's own angles.
        valueListenable: calculation.custom,
        builder: (context, custom, _) => ListView(
          children: [
            ChoiceSection<CalculatedMethod?>(
              heading: text.method,
              setting: calculation.method,
              options: [
                (null, text.methodAutomatic, text.methodAutomaticHint),
                for (final method in CalculatedMethod.values)
                  (
                    method,
                    _methodTitle(text, method),
                    _methodHint(text, method, custom),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _methodTitle(AppLocalizations text, CalculatedMethod? method) =>
    method == null ? text.methodAutomatic : text.methodName(method.name);

/// "Fajr 18°, Isha 17°, Dhuhr +1 min": [method]'s angles (or Isha minutes,
/// or Maghrib angle) and its own minute corrections.
String _methodHint(
  AppLocalizations text,
  CalculatedMethod method,
  MethodAngles custom,
) {
  final angles = anglesOf(method, custom: custom);
  final corrections = methodCorrections(method);
  return [
    text.angleOf(text.prayerFajr, degrees(angles.fajrAngle)),
    if (angles.maghribAngle case final maghrib?)
      text.angleOf(text.prayerMaghrib, degrees(maghrib)),
    if (angles.ishaMinutes case final minutes?)
      text.minutesAfterSunset(text.prayerIsha, minutes)
    else
      text.angleOf(text.prayerIsha, degrees(angles.ishaAngle)),
    // The library limits this method's Fajr and Isha by the season.
    if (method == CalculatedMethod.moonsightingCommittee) text.limitedBySeason,
    if (corrections.isNotEmpty) minuteChanges(corrections, text),
  ].join(text.listSeparator);
}
