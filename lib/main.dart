import 'package:flutter/material.dart';

import 'package:prayer_times/l10n/app_localizations.dart';

void main() {
  runApp(const PrayerTimesApp());
}

class PrayerTimesApp extends StatelessWidget {
  const PrayerTimesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The title is translated, so it is built once the language is known.
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      // The app follows the phone's language. Arabic also flips the layout
      // to right-to-left automatically.
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Light and dark themes; the phone's own setting picks between them.
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

/// Placeholder home screen, replaced by the prayer times screen in Step 5.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(text.appTitle)),
      body: Center(child: Text(text.todayPlaceholder)),
    );
  }
}
