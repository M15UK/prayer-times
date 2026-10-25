import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/place.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/place_screen.dart';

import '../unit/data/sample_places.dart';

/// What the place screen handed back when it closed (true: a choice).
bool? closedWith;

/// Opens the place screen from a simple page, as the main screen does, so
/// the test can see what it returns. Starts with [chosen] selected.
Future<ValueNotifier<Place?>> openPlaces(
  WidgetTester tester, {
  Place? chosen = london,
  Locale locale = const Locale('en'),
}) async {
  final place = ValueNotifier<Place?>(chosen);
  closedWith = null;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            closedWith = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => PlaceScreen(place: place, places: samplePlaces),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle(); // no countdown here, so it settles
  return place;
}

void main() {
  testWidgets('offers my location, then the mosque, then the cities', (
    tester,
  ) async {
    await openPlaces(tester);

    double top(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(top('Use my location'), lessThan(top('East London Mosque')));
    expect(top('East London Mosque'), lessThan(top('London')));
    expect(top('London'), lessThan(top('Riyadh')));
  });

  testWidgets('searches English and Arabic names', (tester) async {
    await openPlaces(tester);

    await tester.enterText(find.byType(TextField), 'riy');
    await tester.pump();
    expect(find.text('Riyadh'), findsOneWidget);
    expect(find.text('London'), findsNothing);

    await tester.enterText(find.byType(TextField), 'الرياض');
    await tester.pump();
    expect(find.text('Riyadh'), findsOneWidget);
  });

  testWidgets('choosing a place saves it and closes', (tester) async {
    final place = await openPlaces(tester);

    await tester.tap(find.text('Riyadh'));
    await tester.pumpAndSettle();

    expect(place.value, riyadh);
    expect(closedWith, isTrue);
  });

  testWidgets('"Use my location" chooses automatic', (tester) async {
    final place = await openPlaces(tester);

    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();

    expect(place.value, isNull);
    expect(closedWith, isTrue);
  });

  testWidgets('shows names in Arabic when the app is in Arabic', (
    tester,
  ) async {
    await openPlaces(tester, locale: const Locale('ar'));

    expect(find.text('مسجد شرق لندن'), findsOneWidget);
    expect(find.text('الرياض'), findsOneWidget);
  });
}
