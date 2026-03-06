import 'package:diary_app/db/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:diary_app/models/diary_entry.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('BackupService Tests', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      dbHelper = DatabaseHelper.test();
      DatabaseHelper.instance = dbHelper;

      // Clean DB before test
      await dbHelper.clearDiary();
      await dbHelper.clearGym();
      await dbHelper.clearKitchen();
      await dbHelper.clearRecipes();
    });

    test('Test clear and batch insert works properly via DatabaseHelper', () async {
      // Create tables explicitly to avoid "no such table" errors if lazy initialization hasn't occurred
      final db = await dbHelper.database; // This will trigger _initDB and create tables

      // Insert some dummy data via batch
      final dummyEntries = [
        {'_id': 1, 'date': '2023-10-27T10:00:00.000', 'content': 'Test Diary Entry 1', 'title': 'Test 1', 'deletedAt': null},
        {'_id': 2, 'date': '2023-10-28T10:00:00.000', 'content': 'Test Diary Entry 2', 'title': 'Test 2', 'deletedAt': null},
      ];

      await dbHelper.batchInsert(DiaryEntryFields.tableName, dummyEntries);

      final result = await db.query(DiaryEntryFields.tableName);
      expect(result.length, 2);
      expect(result.first['content'], 'Test Diary Entry 1');

      // Now clear
      await dbHelper.clearDiary();
      final afterClear = await db.query(DiaryEntryFields.tableName);
      expect(afterClear.isEmpty, true);
    });

    // We can't easily test `createBackup` end-to-end here because it relies on
    // `Share.shareXFiles` and `path_provider` which use native platform channels.
    // However, the export/import logic in dbHelper is the crucial part that we tested above.
  });
}
