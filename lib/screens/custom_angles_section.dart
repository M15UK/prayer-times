import 'package:flutter/material.dart';

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/l10n/bidi_text.dart';
import 'package:prayer_times/screens/choice_section.dart';
import 'package:prayer_times/screens/stepper_tile.dart';

/// The Custom method's angles, in the order of the day: Fajr, Maghrib (at
/// sunset or by angle), Isha (by angle or minutes after sunset). Each stays
/// within the limits in calculation_settings.dart.
class CustomAnglesSection extends StatelessWidget {
  const CustomAnglesSection({super.key, required this.custom});

  final ValueNotifier<MethodAngles> custom;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ValueListenableBuilder(
      valueListenable: custom,
      builder: (context, angles, _) {
        final (:fajrAngle, :ishaAngle, :ishaMinutes, :maghribAngle) = angles;
        return Column(
          children: [
            SectionHeading(text.customAngles, hint: text.customAnglesHint),
            _stepper(
              title: text.prayerFajr,
              value: degrees(fajrAngle),
              current: fajrAngle,
              min: minCustomAngle,
              max: maxCustomAngle,
              step: angleStep,
              onChanged: (angle) =>
                  custom.value = angles.withFajrAngle(angle.toDouble()),
            ),
            _TwoWays(
              title: text.prayerMaghrib,
              first: text.atSunset,
              second: text.byAngle,
              isSecond: maghribAngle != null,
              onChanged: (byAngle) => custom.value = angles.withMaghribAngle(
                byAngle ? startMaghribAngle : null,
              ),
            ),
            if (maghribAngle != null)
              _stepper(
                title: text.prayerMaghrib,
                value: degrees(maghribAngle),
                current: maghribAngle,
                min: minMaghribAngle,
                max: maxMaghribAngle,
                step: angleStep,
                onChanged: (angle) =>
                    custom.value = angles.withMaghribAngle(angle.toDouble()),
              ),
            _TwoWays(
              title: text.prayerIsha,
              first: text.byAngle,
              second: text.byMinutesAfterSunset,
              isSecond: ishaMinutes != null,
              onChanged: (byMinutes) => custom.value = angles.withIshaMinutes(
                byMinutes ? startIshaMinutes : null,
              ),
            ),
            if (ishaMinutes != null)
              _stepper(
                title: text.prayerIsha,
                value: text.minutesValue('$ishaMinutes'),
                current: ishaMinutes,
                min: minIshaMinutes,
                max: maxIshaMinutes,
                step: ishaMinutesStep,
                onChanged: (minutes) =>
                    custom.value = angles.withIshaMinutes(minutes.toInt()),
              )
            else
              _stepper(
                title: text.prayerIsha,
                value: degrees(ishaAngle),
                current: ishaAngle,
                min: minCustomAngle,
                max: maxCustomAngle,
                step: angleStep,
                onChanged: (angle) =>
                    custom.value = angles.withIshaAngle(angle.toDouble()),
              ),
          ],
        );
      },
    );
  }

  /// − / + by [step], greyed out at [min] and [max].
  Widget _stepper({
    required String title,
    required String value,
    required num current,
    required num min,
    required num max,
    required num step,
    required ValueChanged<num> onChanged,
  }) => StepperTile(
    title: title,
    value: value,
    // Clamped too, in case a saved value sits between steps.
    onDecrease: current > min
        ? () => onChanged((current - step).clamp(min, max))
        : null,
    onIncrease: current < max
        ? () => onChanged((current + step).clamp(min, max))
        : null,
  );
}

/// A time that can be worked out one of two ways, e.g. Maghrib "At sunset"
/// or by "Angle".
class _TwoWays extends StatelessWidget {
  const _TwoWays({
    required this.title,
    required this.first,
    required this.second,
    required this.isSecond,
    required this.onChanged,
  });

  final String title;
  final String first;
  final String second;
  final bool isSecond;

  /// Called with true when the second way is chosen.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    subtitle: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: false, label: Text(first)),
          ButtonSegment(value: true, label: Text(second)),
        ],
        selected: {isSecond},
        showSelectedIcon: false,
        onSelectionChanged: (chosen) => onChanged(chosen.first),
      ),
    ),
  );
}
