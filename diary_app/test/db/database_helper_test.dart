import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

void main() {
  setUpAll(() {
    // Initialize FFI for tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DatabaseHelper', () {
    late DatabaseHelper dbHelper;

    setUp(() async {
      // Clean up before starting
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/diary.db';
      await databaseFactory.deleteDatabase(path); // Clean before each test

      dbHelper = DatabaseHelper.test(); // Create a fresh instance
      DatabaseHelper.instance = dbHelper; // Override the singleton
    });

    tearDown(() async {
      // Close database and clear singleton cache if we could.
      // Instead we will let deleteDatabase in setUp handle starting fresh.
      await dbHelper.close();

      // We must reset the internal static _database to null in the app code
      // since the class caches it. Since _database is private, a small workaround:
      // We just delete it. Next time dbHelper.database is called, it returns the closed one.
      // So we have to expose a way or use a memory db.
    });

    test('Should create and read diary entry', () async {
      final entry = DiaryEntry(
        date: DateTime(2023, 10, 1),
        content: 'Test entry',
      );

      final created = await dbHelper.create(entry);
      expect(created.id, isNotNull);
      expect(created.content, 'Test entry');

      final read = await dbHelper.readEntry(created.id!);
      expect(read.content, 'Test entry');
      expect(read.date, DateTime(2023, 10, 1));
    });

    test('Should update diary entry', () async {
      final entry = await dbHelper.create(DiaryEntry(date: DateTime.now(), content: 'Old text'));
      final toUpdate = entry.copyWith(content: 'New text');

      await dbHelper.update(toUpdate);

      final read = await dbHelper.readEntry(entry.id!);
      expect(read.content, 'New text');
    });

    test('Should soft delete and restore diary entry', () async {
      final entry = await dbHelper.create(DiaryEntry(date: DateTime.now(), content: 'To delete'));

      await dbHelper.delete(entry.id!);

      final allEntries = await dbHelper.readAllEntries();
      expect(allEntries.any((e) => e.id == entry.id), isFalse);

      final trashEntries = await dbHelper.readTrashEntries();
      expect(trashEntries.any((e) => e.id == entry.id), isTrue);

      await dbHelper.restore(entry.id!);

      final allEntriesAfterRestore = await dbHelper.readAllEntries();
      expect(allEntriesAfterRestore.any((e) => e.id == entry.id), isTrue);
    });

    test('Should hard delete diary entry', () async {
      final entry = await dbHelper.create(DiaryEntry(date: DateTime.now(), content: 'To hard delete'));

      await dbHelper.hardDelete(entry.id!);

      expect(
        () async => await dbHelper.readEntry(entry.id!),
        throwsException,
      );
    });
  });
}
