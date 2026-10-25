import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prayer_times/main.dart';

/// Starts the app with the phone set to [language], then checks the title
/// text and which way the layout reads.
Future<void> expectAppInLanguage(
  WidgetTester tester, {
  required String language,
  required String title,
  required TextDirection direction,
}) async {
  // Arrange: pretend the phone's language is [language].
  tester.platformDispatcher.localesTestValue = [Locale(language)];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);

  // Act
  await tester.pumpWidget(const PrayerTimesApp());
  await tester.pumpAndSettle();

  // Assert
  final titleFinder = find.text(title);
  expect(titleFinder, findsOneWidget);
  expect(Directionality.of(tester.element(titleFinder)), direction);
}

void main() {
  testWidgets('shows English left to right when the phone is in English', (
    tester,
  ) async {
    await expectAppInLanguage(
      tester,
      language: 'en',
      title: 'Prayer Times',
      direction: TextDirection.ltr,
    );
  });

  testWidgets('shows Arabic right to left when the phone is in Arabic', (
    tester,
  ) async {
    await expectAppInLanguage(
      tester,
      language: 'ar',
      title: 'مواقيت الصلاة',
      direction: TextDirection.rtl,
    );
  });
}
