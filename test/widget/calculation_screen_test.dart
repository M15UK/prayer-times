import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/data/calculated_timetable.dart';
import 'package:prayer_times/data/calculation_settings.dart';
import 'package:prayer_times/data/timetable.dart';
import 'package:prayer_times/l10n/app_localizations.dart';
import 'package:prayer_times/screens/calculation_screen.dart';

import 'home_screen_test.dart' show finishTransition;

void main() {
  late ValueNotifier<AsrMethod> asr;

  /// The Prayer calculation page with [calculation] (fresh choices if null).
  Future<CalculationSettings> pumpCalculation(
    WidgetTester tester, {
    CalculationSettings? calculation,
    Locale locale = const Locale('en'),
  }) async {
    // A tall screen, so the whole page is built without scrolling.
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final settings = calculation ?? CalculationSettings();
    asr = ValueNotifier(AsrMethod.standard);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CalculationScreen(calculation: settings, asrMethod: asr),
      ),
    );
    return settings;
  }

  /// [text] kept the right way round in Arabic, as the page shows numbers.
  String isolated(String text) => '\u2068$text\u2069';

  /// The plus or minus button labelled [tooltip], inside [section] if given.
  Finder button(String tooltip, {Finder? section}) {
    final labelled = find.ancestor(
      of: find.byTooltip(tooltip),
      matching: find.byType(IconButton),
    );
    return section == null
        ? labelled
        : find.descendant(of: section, matching: labelled);
  }

  bool isEnabled(WidgetTester tester, Finder iconButton) =>
      tester.widget<IconButton>(iconButton).onPressed != null;

  testWidgets('switching official timetables off saves it and says what '
      'happens', (tester) async {
    final calculation = await pumpCalculation(tester);
    expect(find.textContaining('your method everywhere else'), findsOneWidget);

    await tester.tap(find.text('Official timetables first'));
    await tester.pump();

    expect(calculation.officialFirst.value, isFalse);
    expect(
      find.text('Your method everywhere, always labelled Calculated'),
      findsOneWidget,
    );
  });

  testWidgets('picks a method from the list, each with its angles', (
    tester,
  ) async {
    final calculation = await pumpCalculation(tester);
    final methodTile = find.widgetWithText(ListTile, 'Method');
    expect(
      find.descendant(of: methodTile, matching: find.text('Automatic')),
      findsOneWidget,
    );

    await tester.tap(find.text('Method'));
    await finishTransition(tester);
    final fifteen = isolated('15°');
    expect(
      find.text('Fajr $fifteen, Isha $fifteen, Dhuhr ${isolated('+1')} min'),
      findsOneWidget, // ISNA
    );
    final eighteen = isolated('18°');
    expect(
      find.text(
        'Fajr $eighteen, Isha $eighteen, limited by season, '
        'Dhuhr ${isolated('+5')} min, Maghrib ${isolated('+3')} min',
      ),
      findsOneWidget, // Moonsighting Committee
    );
    expect(
      find.text('Fajr ${isolated('18.5°')}, Isha 90 min after sunset'),
      findsOneWidget,
    );
    expect(
      find.text(
        'Fajr ${isolated('16°')}, Maghrib ${isolated('4°')}, '
        'Isha ${isolated('14°')}',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('ISNA'));
    await tester.pump();
    await tester.pageBack();
    await finishTransition(tester);

    expect(calculation.method.value, CalculatedMethod.northAmerica);
    expect(
      find.descendant(of: methodTile, matching: find.text('ISNA')),
      findsOneWidget,
    );
  });

  testWidgets('can go back to the automatic method', (tester) async {
    final calculation = await pumpCalculation(
      tester,
      calculation: CalculationSettings(
        method: ValueNotifier(CalculatedMethod.karachi),
      ),
    );

    await tester.tap(find.text('Method'));
    await finishTransition(tester);
    await tester.tap(find.text('Automatic'));
    await tester.pump();

    expect(calculation.method.value, isNull);
  });

  group('custom angles', () {
    final customAngles = find.byKey(const Key('customAngles'));

    Future<CalculationSettings> pumpCustom(WidgetTester tester) =>
        pumpCalculation(
          tester,
          calculation: CalculationSettings(
            method: ValueNotifier(CalculatedMethod.custom),
          ),
        );

    testWidgets('show only for the Custom method', (tester) async {
      final calculation = await pumpCalculation(tester);
      expect(find.text('Custom angles'), findsNothing);

      calculation.method.value = CalculatedMethod.custom;
      await tester.pump();

      expect(find.text('Custom angles'), findsOneWidget);
    });

    testWidgets('change Fajr by half a degree, within the limits', (
      tester,
    ) async {
      final calculation = await pumpCustom(tester);
      final increase = button('Increase Fajr', section: customAngles);

      await tester.tap(increase);
      await tester.pump();
      expect(calculation.custom.value.fajrAngle, 18.5);
      expect(find.text(isolated('18.5°')), findsOneWidget);

      calculation.custom.value = (
        fajrAngle: maxCustomAngle,
        ishaAngle: 17,
        ishaMinutes: null,
        maghribAngle: null,
      );
      await tester.pump();
      expect(isEnabled(tester, increase), isFalse);
    });

    testWidgets('never step past a limit, even from a saved angle between '
        'steps', (tester) async {
      final calculation = await pumpCalculation(
        tester,
        calculation: CalculationSettings(
          method: ValueNotifier(CalculatedMethod.custom),
          custom: ValueNotifier((
            fajrAngle: 10.2,
            ishaAngle: 17,
            ishaMinutes: null,
            maghribAngle: null,
          )),
        ),
      );

      await tester.tap(button('Decrease Fajr', section: customAngles));
      await tester.pump();

      expect(calculation.custom.value.fajrAngle, minCustomAngle);
    });

    testWidgets('can set Isha by minutes after sunset', (tester) async {
      final calculation = await pumpCustom(tester);

      await tester.tap(find.text('Minutes after sunset'));
      await tester.pump();
      expect(calculation.custom.value.ishaMinutes, 90);

      await tester.tap(button('Increase Isha', section: customAngles));
      await tester.pump();
      expect(calculation.custom.value.ishaMinutes, 95);
      expect(find.text('95 min'), findsOneWidget);
    });

    testWidgets('can set Maghrib by angle, and back to sunset', (tester) async {
      final calculation = await pumpCustom(tester);

      // Maghrib comes before Isha, so its "Angle" is the first.
      await tester.tap(find.text('Angle').first);
      await tester.pump();
      expect(calculation.custom.value.maghribAngle, 4);

      await tester.tap(find.text('At sunset'));
      await tester.pump();
      expect(calculation.custom.value.maghribAngle, isNull);
    });
  });

  testWidgets('chooses the high-latitude rule', (tester) async {
    final calculation = await pumpCalculation(tester);
    expect(
      find.text('Not for UK summers: Isha would fall after midnight'),
      findsOneWidget,
    );

    await tester.tap(find.text('Twilight angle'));
    await tester.pump();

    expect(calculation.highLatitude.value, HighLatitude.twilightAngle);
  });

  testWidgets('chooses the Asr time here', (tester) async {
    await pumpCalculation(tester);

    await tester.tap(find.text('Hanafi'));
    await tester.pump();

    expect(asr.value, AsrMethod.hanafi);
  });

  group('minute changes', () {
    final minuteChanges = find.byKey(const Key('minuteChanges'));

    testWidgets('move a time later or earlier, a minute at a time', (
      tester,
    ) async {
      final calculation = await pumpCalculation(tester);

      await tester.tap(button('Increase Fajr', section: minuteChanges));
      await tester.pump();
      await tester.tap(button('Increase Fajr', section: minuteChanges));
      await tester.pump();
      await tester.tap(button('Decrease Isha', section: minuteChanges));
      await tester.pump();

      expect(calculation.minutes.value, {Prayer.fajr: 2, Prayer.isha: -1});
      expect(find.text('${isolated('+2')} min'), findsOneWidget);
      expect(find.text('${isolated('\u22121')} min'), findsOneWidget);
      expect(find.text('${isolated('0')} min'), findsNWidgets(4)); // the rest
    });

    testWidgets('going back to 0 removes the change', (tester) async {
      final calculation = await pumpCalculation(
        tester,
        calculation: CalculationSettings(
          minutes: ValueNotifier(const {Prayer.asr: 1}),
        ),
      );

      await tester.tap(button('Decrease Asr', section: minuteChanges));
      await tester.pump();

      expect(calculation.minutes.value, isEmpty);
    });

    testWidgets('stop at $maxMinuteChange minutes either way', (tester) async {
      await pumpCalculation(
        tester,
        calculation: CalculationSettings(
          minutes: ValueNotifier(const {
            Prayer.fajr: maxMinuteChange,
            Prayer.isha: -maxMinuteChange,
          }),
        ),
      );

      expect(
        isEnabled(tester, button('Increase Fajr', section: minuteChanges)),
        isFalse,
      );
      expect(
        isEnabled(tester, button('Decrease Isha', section: minuteChanges)),
        isFalse,
      );
      expect(
        isEnabled(tester, button('Decrease Fajr', section: minuteChanges)),
        isTrue,
      );
    });
  });

  testWidgets('speaks Arabic', (tester) async {
    await pumpCalculation(tester, locale: const Locale('ar'));

    expect(find.text('حساب أوقات الصلاة'), findsOneWidget);
    expect(find.text('الجداول الرسمية أولًا'), findsOneWidget);
  });
}
