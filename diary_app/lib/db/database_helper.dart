import 'package:diary_app/models/diary_entry.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('diary.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
CREATE TABLE ${DiaryEntryFields.tableName} (
  ${DiaryEntryFields.id} $idType,
  ${DiaryEntryFields.date} $textType,
  ${DiaryEntryFields.content} $textType
  )
''');
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
    final result = await db.query(DiaryEntryFields.tableName, orderBy: orderBy);

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

  Future<int> delete(int id) async {
    final db = await instance.database;

    return await db.delete(
      DiaryEntryFields.tableName,
      where: '${DiaryEntryFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
