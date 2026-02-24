import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/main.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MockDatabaseHelper extends DatabaseHelper {
  MockDatabaseHelper() : super.test();

  List<DiaryEntry> entries = [];
  int nextId = 1;

  @override
  Future<List<DiaryEntry>> readAllEntries() async {
    return List.from(entries)..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<DiaryEntry> create(DiaryEntry entry) async {
    final newEntry = entry.copyWith(id: nextId++);
    entries.add(newEntry);
    return newEntry;
  }

  @override
  Future<int> update(DiaryEntry entry) async => 1;

  @override
  Future<int> delete(int id) async => 1;
}

void main() {
  setUp(() {
    DatabaseHelper.instance = MockDatabaseHelper();
  });

  testWidgets('Calendar presence and toggle', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify TableCalendar exists
    expect(find.byType(TableCalendar<DiaryEntry>), findsOneWidget);

    // Verify empty state
    expect(find.text('Keine Einträge vorhanden.'), findsOneWidget);

    // Create an entry to show the list
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Tagebucheintrag'), 'Test Content');
    await tester.tap(find.text('SPEICHERN'));
    await tester.pumpAndSettle();

    // Verify ScrollablePositionedList is present
    expect(find.byType(ScrollablePositionedList), findsOneWidget);

    // Verify Collapse Button exists (Up arrow initially)
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);

    // Tap the button to collapse
    await tester.tap(find.byIcon(Icons.keyboard_arrow_up));
    await tester.pumpAndSettle();

    // Verify icon changed to Down arrow (indicating it can be expanded)
    expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    expect(find.byIcon(Icons.keyboard_arrow_up), findsNothing);

    // Tap again to expand
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();

    // Verify icon changed back
    expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
  });
}
