import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/models/gym/gym_equipment.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_training.dart';
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

    // Increment version to trigger onUpgrade for existing users
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textTypeNullable = 'TEXT'; // Titles can be null/empty

    await db.execute('''
CREATE TABLE ${DiaryEntryFields.tableName} (
  ${DiaryEntryFields.id} $idType,
  ${DiaryEntryFields.date} $textType,
  ${DiaryEntryFields.content} $textType,
  ${DiaryEntryFields.title} $textTypeNullable
  )
''');

    await _createGymTables(db);
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(
        'ALTER TABLE ${DiaryEntryFields.tableName} ADD COLUMN ${DiaryEntryFields.title} TEXT',
      );
    }
    if (oldVersion < 3) {
      await _createGymTables(db);
    }
  }

  Future _createGymTables(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL';
    const boolType = 'INTEGER NOT NULL DEFAULT 0';
    const textNullable = 'TEXT';
    const intNullable = 'INTEGER';

    // Gym Equipment
    await db.execute('''
CREATE TABLE ${GymEquipmentFields.tableName} (
  ${GymEquipmentFields.id} $idType,
  ${GymEquipmentFields.name} $textType
)
''');

    // Gym Plans
    await db.execute('''
CREATE TABLE ${GymPlanFields.tableName} (
  ${GymPlanFields.id} $idType,
  ${GymPlanFields.name} $textType
)
''');

    // Gym Plan Exercises
    await db.execute('''
CREATE TABLE ${GymPlanExerciseFields.tableName} (
  ${GymPlanExerciseFields.id} $idType,
  ${GymPlanExerciseFields.planId} $intType,
  ${GymPlanExerciseFields.equipmentId} $intType,
  ${GymPlanExerciseFields.setCount} $intType,
  ${GymPlanExerciseFields.sortOrder} $intType,
  FOREIGN KEY (${GymPlanExerciseFields.planId}) REFERENCES ${GymPlanFields.tableName} (${GymPlanFields.id}) ON DELETE CASCADE,
  FOREIGN KEY (${GymPlanExerciseFields.equipmentId}) REFERENCES ${GymEquipmentFields.tableName} (${GymEquipmentFields.id})
)
''');

    // Gym Trainings
    await db.execute('''
CREATE TABLE ${GymTrainingFields.tableName} (
  ${GymTrainingFields.id} $idType,
  ${GymTrainingFields.planId} $intType,
  ${GymTrainingFields.date} $textType,
  ${GymTrainingFields.note} $textNullable,
  FOREIGN KEY (${GymTrainingFields.planId}) REFERENCES ${GymPlanFields.tableName} (${GymPlanFields.id})
)
''');

    // Gym Sets
    await db.execute('''
CREATE TABLE ${GymSetFields.tableName} (
  ${GymSetFields.id} $idType,
  ${GymSetFields.trainingId} $intType,
  ${GymSetFields.equipmentId} $intType,
  ${GymSetFields.setNumber} $intType,
  ${GymSetFields.reps} $intNullable,
  ${GymSetFields.weight} $realType,
  ${GymSetFields.isDone} $boolType,
  FOREIGN KEY (${GymSetFields.trainingId}) REFERENCES ${GymTrainingFields.tableName} (${GymTrainingFields.id}) ON DELETE CASCADE,
  FOREIGN KEY (${GymSetFields.equipmentId}) REFERENCES ${GymEquipmentFields.tableName} (${GymEquipmentFields.id})
)
''');
  }

  // --- Diary Entry CRUD ---

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

  // --- Gym CRUD Methods ---

  // Equipment
  Future<GymEquipment> createEquipment(GymEquipment equipment) async {
    final db = await instance.database;
    final id = await db.insert(GymEquipmentFields.tableName, equipment.toJson());
    return equipment.copyWith(id: id);
  }

  Future<List<GymEquipment>> getAllEquipment() async {
    final db = await instance.database;
    final result = await db.query(GymEquipmentFields.tableName, orderBy: '${GymEquipmentFields.name} ASC');
    return result.map((json) => GymEquipment.fromJson(json)).toList();
  }

  // Plans
  Future<GymPlan> createPlan(GymPlan plan, List<GymPlanExercise> exercises) async {
    final db = await instance.database;
    // Transaction to ensure plan and exercises are created together
    return await db.transaction((txn) async {
      final planId = await txn.insert(GymPlanFields.tableName, plan.toJson());

      for (var exercise in exercises) {
        final exerciseWithPlanId = exercise.copyWith(planId: planId);
        await txn.insert(GymPlanExerciseFields.tableName, exerciseWithPlanId.toJson());
      }

      return plan.copyWith(id: planId);
    });
  }

  Future<List<GymPlan>> getAllPlans() async {
    final db = await instance.database;
    final result = await db.query(GymPlanFields.tableName, orderBy: '${GymPlanFields.name} ASC');
    return result.map((json) => GymPlan.fromJson(json)).toList();
  }

  Future<List<GymPlanExercise>> getExercisesForPlan(int planId) async {
    final db = await instance.database;
    final result = await db.query(
      GymPlanExerciseFields.tableName,
      where: '${GymPlanExerciseFields.planId} = ?',
      whereArgs: [planId],
      orderBy: GymPlanExerciseFields.sortOrder,
    );
    return result.map((json) => GymPlanExercise.fromJson(json)).toList();
  }

  // Trainings
  Future<GymTraining> createTraining(GymTraining training, List<GymSet> sets) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final trainingId = await txn.insert(GymTrainingFields.tableName, training.toJson());

      for (var set in sets) {
        final setWithId = set.copyWith(trainingId: trainingId);
        await txn.insert(GymSetFields.tableName, setWithId.toJson());
      }
      return training.copyWith(id: trainingId);
    });
  }

  Future<List<GymTraining>> getTrainingsForPlan(int planId) async {
    final db = await instance.database;
    final result = await db.query(
      GymTrainingFields.tableName,
      where: '${GymTrainingFields.planId} = ?',
      whereArgs: [planId],
      orderBy: '${GymTrainingFields.date} DESC',
    );
    return result.map((json) => GymTraining.fromJson(json)).toList();
  }

  Future<List<GymSet>> getSetsForTraining(int trainingId) async {
    final db = await instance.database;
    final result = await db.query(
      GymSetFields.tableName,
      where: '${GymSetFields.trainingId} = ?',
      whereArgs: [trainingId],
      orderBy: '${GymSetFields.equipmentId}, ${GymSetFields.setNumber}',
    );
    return result.map((json) => GymSet.fromJson(json)).toList();
  }

  // Helper to get last training for a plan to pre-fill values
  Future<GymTraining?> getLastTraining(int planId) async {
    final db = await instance.database;
    final result = await db.query(
      GymTrainingFields.tableName,
      where: '${GymTrainingFields.planId} = ?',
      whereArgs: [planId],
      orderBy: '${GymTrainingFields.date} DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return GymTraining.fromJson(result.first);
    }
    return null;
  }

  Future close() async {
    final db = await instance.database;

    db.close();
  }
}
