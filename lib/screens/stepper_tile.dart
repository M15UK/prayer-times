import 'package:flutter/material.dart';

import 'package:prayer_times/l10n/app_localizations.dart';

/// A row with a value and − / + buttons, e.g. "Fajr  − 18° +". A button is
/// greyed out (null) at its limit.
class StepperTile extends StatelessWidget {
  const StepperTile({
    super.key,
    required this.title,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String title;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: text.decrease(title), // also read out by screen readers
            onPressed: onDecrease,
          ),
          Text(value),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: text.increase(title),
            onPressed: onIncrease,
          ),
        ],
      ),
    );
  }
}
