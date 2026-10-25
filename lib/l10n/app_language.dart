import 'dart:ui';

/// The app's language: the phone's own, or a fixed choice from Settings.
///
/// An "enhanced enum": each option carries the locale it stands for.
enum AppLanguage {
  phone(null),
  english(Locale('en')),
  arabic(Locale('ar'));

  const AppLanguage(this.locale);

  /// The language to use, or null to follow the phone.
  final Locale? locale;
}
