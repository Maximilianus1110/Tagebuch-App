import 'package:diary_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    // Initialize FFI
    sqfliteFfiInit();
    // Change the default factory
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App allows navigation to Add Entry screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Allow some time for initial render, but don't wait for infinite animations (loading)
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Home Screen
    expect(find.text('Mein Tagebuch'), findsOneWidget);

    // Tap the '+' icon to go to Add Entry screen.
    await tester.tap(find.byIcon(Icons.add));

    // Wait for navigation animation
    await tester.pumpAndSettle();

    // Verify we are on the Add Entry screen.
    expect(find.text('Neuer Eintrag'), findsOneWidget);

    // Tap Back button
    await tester.pageBack();

    // Wait for navigation back. Use pump with duration instead of settle if loading spinner is active
    await tester.pump(const Duration(milliseconds: 500));

    // Verify we are back on Home Screen.
    expect(find.text('Mein Tagebuch'), findsOneWidget);
  });
}
