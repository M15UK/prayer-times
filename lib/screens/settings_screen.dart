import 'package:flutter/material.dart';

import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';

/// The app's settings. For now: which Asr time to use.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.asrMethod});

  /// The Asr choice; setting it saves it and updates the main screen.
  final ValueNotifier<AsrMethod> asrMethod;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.settings)),
      body: ValueListenableBuilder(
        valueListenable: asrMethod,
        // RadioGroup lets screen readers announce the two options as one
        // choice ("1 of 2, selected").
        builder: (context, selected, _) => RadioGroup<AsrMethod>(
          groupValue: selected,
          onChanged: (method) {
            if (method != null) asrMethod.value = method;
          },
          child: ListView(
            children: [
              ListTile(title: Text(text.asrTime)),
              RadioListTile(
                value: AsrMethod.standard,
                title: Text(text.asrStandard),
                subtitle: Text(text.asrStandardHint),
              ),
              RadioListTile(
                value: AsrMethod.hanafi,
                title: Text(text.asrHanafiOption),
                subtitle: Text(text.asrHanafiHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
