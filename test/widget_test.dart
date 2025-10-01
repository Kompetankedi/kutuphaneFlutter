// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:kutuphane/main.dart';
import 'package:kutuphane/theme_provider.dart';

void main() {
  testWidgets('Library App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the main menu screen loads
    expect(find.text('Okul Kütüphanesi Ana Menü'), findsOneWidget);
    expect(find.text('Türk Roman İşlemleri'), findsOneWidget);
    expect(find.text('Yabancı Roman İşlemleri'), findsOneWidget);
    expect(find.text('Ödünç İşlemleri'), findsOneWidget);
  });

  testWidgets('Dark mode toggle works', (WidgetTester tester) async {
    final themeProvider = ThemeProvider();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider.value(value: themeProvider, child: const MyApp()),
    );

    // Initial state should be light mode
    expect(themeProvider.isDarkMode, false);

    // Navigate to settings screen
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    // Find and tap the dark mode switch
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify dark mode is now enabled
    expect(themeProvider.isDarkMode, true);
  });
}
