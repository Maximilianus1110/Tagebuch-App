import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/screens/home_screen.dart';
import 'package:diary_app/services/theme_provider.dart';
import 'package:provider/provider.dart';

void main() {
  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: const MaterialApp(
        home: HomeScreen(),
      ),
    );
  }

  group('HomeScreen Tests', () {
    testWidgets('Renders all menu items', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Menü'), findsOneWidget);
      expect(find.text('Gym'), findsOneWidget);
      expect(find.text('Tagebuch'), findsOneWidget);
      expect(find.text('Küche'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.fitness_center), findsOneWidget);
      expect(find.byIcon(Icons.book), findsOneWidget);
      expect(find.byIcon(Icons.kitchen), findsOneWidget);
    });
  });
}
