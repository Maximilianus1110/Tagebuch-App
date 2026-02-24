import 'package:diary_app/models/diary_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static DatabaseHelper _instance = DatabaseHelper._init();

  static DatabaseHelper get instance => _instance;

  // Allow setting instance for testing
  @visibleForTesting
  static set instance(DatabaseHelper helper) {
    _instance = helper;
  }

  static Database? _database;

  DatabaseHelper._init();

  // Constructor for subclasses/mocks
  @visibleForTesting
  DatabaseHelper.test();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    final db = await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );

    // Perform cleanup of old trash entries
    await _cleanupTrash(db);

    return db;
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT'; // Titles/DeletedAt can be null

    await db.execute('''
CREATE TABLE ${DiaryEntryFields.tableName} (
  ${DiaryEntryFields.id} $idType,
  ${DiaryEntryFields.date} $textType,
  ${DiaryEntryFields.content} $textType,
  ${DiaryEntryFields.title} $textTypeNullable,
  ${DiaryEntryFields.deletedAt} $textTypeNullable
  )
''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${DiaryEntryFields.tableName} ADD COLUMN ${DiaryEntryFields.title} TEXT',
      );
    }
    if (oldVersion < 3) {
      await db.execute(
        'ALTER TABLE ${DiaryEntryFields.tableName} ADD COLUMN ${DiaryEntryFields.deletedAt} TEXT',
      );
    }
  }

  Future<DiaryEntry> create(DiaryEntry entry) async {
    final db = await instance.database;

    // Use toIso8601String() to store date as text
    final id = await db.insert(DiaryEntryFields.tableName, entry.toJson());
    return entry.copyWith(id: id);
  }

  Future<DiaryEntry> readEntry(int id) async {
    final db = await instance.database;

    final maps = await db.query(
      DiaryEntryFields.tableName,
      columns: DiaryEntryFields.values,
      where: '${DiaryEntryFields.id} = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return DiaryEntry.fromJson(maps.first);
    } else {
      throw Exception('ID $id not found');
    }
  }

  Future<List<DiaryEntry>> readAllEntries() async {
    final db = await instance.database;

    final orderBy = '${DiaryEntryFields.date} DESC';
    // Filter out deleted entries
    final result = await db.query(
      DiaryEntryFields.tableName,
      orderBy: orderBy,
      where: '${DiaryEntryFields.deletedAt} IS NULL',
    );

    return result.map((json) => DiaryEntry.fromJson(json)).toList();
  }

  Future<List<DiaryEntry>> readTrashEntries() async {
    final db = await instance.database;

    final orderBy = '${DiaryEntryFields.deletedAt} DESC';
    // Only deleted entries
    final result = await db.query(
      DiaryEntryFields.tableName,
      orderBy: orderBy,
      where: '${DiaryEntryFields.deletedAt} IS NOT NULL',
    );

    return result.map((json) => DiaryEntry.fromJson(json)).toList();
  }

  Future<int> update(DiaryEntry entry) async {
    final db = await instance.database;

    return db.update(
      DiaryEntryFields.tableName,
      entry.toJson(),
      where: '${DiaryEntryFields.id} = ?',
      whereArgs: [entry.id],
    );
  }

  // Soft delete
  Future<int> delete(int id) async {
    final db = await instance.database;

    return db.update(
      DiaryEntryFields.tableName,
      {DiaryEntryFields.deletedAt: DateTime.now().toIso8601String()},
      where: '${DiaryEntryFields.id} = ?',
      whereArgs: [id],
    );
  }

  // Restore from trash
  Future<int> restore(int id) async {
    final db = await instance.database;

    return db.update(
      DiaryEntryFields.tableName,
      {DiaryEntryFields.deletedAt: null},
      where: '${DiaryEntryFields.id} = ?',
      whereArgs: [id],
    );
  }

  // Hard delete
  Future<int> hardDelete(int id) async {
    final db = await instance.database;

    return await db.delete(
      DiaryEntryFields.tableName,
      where: '${DiaryEntryFields.id} = ?',
      whereArgs: [id],
    );
  }

  // Cleanup old trash
  Future<int> cleanupTrash() async {
    final db = await instance.database;
    return _cleanupTrash(db);
  }

  // Private helper to allow calling from _initDB
  Future<int> _cleanupTrash(Database db) async {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    return await db.delete(
      DiaryEntryFields.tableName,
      where: '${DiaryEntryFields.deletedAt} IS NOT NULL AND ${DiaryEntryFields.deletedAt} < ?',
      whereArgs: [cutoff.toIso8601String()],
    );
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
