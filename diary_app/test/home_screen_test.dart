import 'package:diary_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Home Screen shows menu options and navigates to Gym', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify Title
    expect(find.text('Menü'), findsOneWidget);

    // Verify Buttons
    expect(find.text('Gym'), findsOneWidget);
    expect(find.byIcon(Icons.fitness_center), findsOneWidget);

    expect(find.text('Tagebuch'), findsOneWidget);
    expect(find.byIcon(Icons.book), findsOneWidget);

    // Tap Gym
    await tester.tap(find.text('Gym'));
    await tester.pumpAndSettle();

    // Verify Gym Screen
    expect(find.text('Gym'), findsOneWidget); // AppBar title
    expect(find.text('Demnächst verfügbar'), findsOneWidget);

    // Go back
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Verify back on Home Screen
    expect(find.text('Menü'), findsOneWidget);
  });
}
