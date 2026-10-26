import 'package:flutter/material.dart';

/// A section heading that screen readers announce as a heading.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.hint});

  final String text;

  /// An optional line underneath, e.g. what the choice does.
  final String? hint;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    ),
    subtitle: hint == null ? null : Text(hint!),
  );
}

/// A heading and a one-of-several choice, saved straight into [setting].
class ChoiceSection<T> extends StatelessWidget {
  const ChoiceSection({
    super.key,
    required this.heading,
    required this.setting,
    required this.options,
    this.hint,
  });

  final String heading;
  final ValueNotifier<T> setting;

  /// An optional line under the heading, about all the options.
  final String? hint;

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
            SectionHeading(heading, hint: hint),
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
