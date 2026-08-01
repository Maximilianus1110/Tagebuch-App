import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/main.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class MockDatabaseHelper extends DatabaseHelper {
  MockDatabaseHelper() : super.test();

  List<DiaryEntry> entries = [];
  int nextId = 1;

  @override
  Future<List<DiaryEntry>> readAllEntries() async {
    // Return copy to simulate DB behavior, filtering out deleted
    return entries.where((e) => e.deletedAt == null).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<DiaryEntry> create(DiaryEntry entry) async {
    final newEntry = entry.copyWith(id: nextId++);
    entries.add(newEntry);
    return newEntry;
  }

  @override
  Future<int> update(DiaryEntry entry) async {
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) {
      entries[index] = entry;
      return 1;
    }
    return 0;
  }

  @override
  Future<int> delete(int id) async {
    // Soft delete
    final index = entries.indexWhere((e) => e.id == id);
    if (index != -1) {
      entries[index] = DiaryEntry(
        id: entries[index].id,
        date: entries[index].date,
        content: entries[index].content,
        title: entries[index].title,
        deletedAt: DateTime.now(),
      );
      return 1;
    }
    return 0;
  }

  @override
  Future<List<DiaryEntry>> readTrashEntries() async {
    return entries.where((e) => e.deletedAt != null).toList()
      ..sort((a, b) => b.deletedAt!.compareTo(a.deletedAt!));
  }

  @override
  Future<int> hardDelete(int id) async {
    entries.removeWhere((e) => e.id == id);
    return 1;
  }

  @override
  Future<int> restore(int id) async {
    final index = entries.indexWhere((e) => e.id == id);
    if (index != -1) {
        entries[index] = DiaryEntry(
            id: entries[index].id,
            date: entries[index].date,
            content: entries[index].content,
            title: entries[index].title,
            deletedAt: null,
        );
        return 1;
    }
    return 0;
  }

  @override
  Future<int> cleanupTrash() async {
      return 0;
  }
}

void main() {
  setUp(() {
    DatabaseHelper.instance = MockDatabaseHelper();
  });

  testWidgets('Create, Verify List, Search, Edit, Delete', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle(); // Should resolve quickly with mock

    // Navigate to Diary
    expect(find.text('Tagebuch App'), findsOneWidget);
    await tester.tap(find.text('Tagebuch'));
    await tester.pumpAndSettle();

    // 1. Verify Empty List
    expect(find.text('Keine Einträge vorhanden.'), findsOneWidget);

    // 2. Create Entry
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify Title Field Exists
    expect(find.text('Titel (optional)'), findsOneWidget);

    // Enter Data
    await tester.enterText(find.widgetWithText(TextFormField, 'Titel (optional)'), 'My Test Title');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tagebucheintrag'), 'This is a long test content to check truncation and display.');

    // Save
    await tester.tap(find.text('SPEICHERN'));
    await tester.pumpAndSettle();

    // 3. Verify List Item
    expect(find.text('My Test Title'), findsOneWidget);

    // Verify Truncation (visually hard, but check content text exists)
    expect(find.text('This is a long test content to check truncation and display.'), findsOneWidget);

    // 4. Search
    // Search for non-existent
    await tester.enterText(find.widgetWithText(TextField, 'Suchen...'), 'NotExist');
    await tester.pumpAndSettle(); // Filter updates
    expect(find.text('My Test Title'), findsNothing);

    // Search for existent
    await tester.enterText(find.widgetWithText(TextField, 'Suchen...'), 'Test');
    await tester.pumpAndSettle();
    expect(find.text('My Test Title'), findsOneWidget);

    // Clear Search
    await tester.enterText(find.widgetWithText(TextField, 'Suchen...'), '');
    await tester.pumpAndSettle();
    expect(find.text('My Test Title'), findsOneWidget);

    // 5. Edit Entry
    await tester.tap(find.text('My Test Title'));
    await tester.pumpAndSettle();

    // Verify Edit Screen
    expect(find.text('Eintrag bearbeiten'), findsOneWidget);
    expect(find.text('My Test Title'), findsOneWidget);

    // Change Title
    await tester.enterText(find.widgetWithText(TextFormField, 'Titel (optional)'), 'Updated Title');
    await tester.tap(find.text('SPEICHERN'));
    await tester.pumpAndSettle();

    // Verify Update
    expect(find.text('Updated Title'), findsOneWidget);
    expect(find.text('My Test Title'), findsNothing);

    // 6. Delete Entry
    await tester.tap(find.text('Updated Title'));
    await tester.pumpAndSettle();

    // Click Delete Icon
    await tester.tap(find.byIcon(Icons.delete));
    await tester.pumpAndSettle();

    // Confirm Dialog
    expect(find.text('Eintrag löschen?'), findsOneWidget);
    await tester.tap(find.text('Ja'));
    await tester.pumpAndSettle();

    // Verify Deletion
    expect(find.text('Updated Title'), findsNothing);
    expect(find.text('Keine Einträge vorhanden.'), findsOneWidget);
  });
}
