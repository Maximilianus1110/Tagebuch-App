import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
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

    final db = await openDatabase(
      path,
      version: 5,
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

    await _createGymTables(db);
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
    if (oldVersion < 4) {
      await _createGymTables(db);
    }
    if (oldVersion < 5) {
      // Version 5: Add description to exercises, targetReps/isWarmup to plan exercises, duration/isWarmup to sets
      try {
        await db.execute('ALTER TABLE ${GymExerciseFields.tableName} ADD COLUMN ${GymExerciseFields.description} TEXT');
      } catch (e) {
        // Ignore if exists
      }
      try {
        await db.execute('ALTER TABLE ${GymPlanExerciseFields.tableName} ADD COLUMN ${GymPlanExerciseFields.targetReps} TEXT');
      } catch (e) {
        // Ignore
      }
      try {
        await db.execute('ALTER TABLE ${GymPlanExerciseFields.tableName} ADD COLUMN ${GymPlanExerciseFields.isWarmup} INTEGER DEFAULT 0');
      } catch (e) {
        // Ignore
      }
      try {
        await db.execute('ALTER TABLE ${GymSetFields.tableName} ADD COLUMN ${GymSetFields.durationSeconds} INTEGER');
      } catch (e) {
        // Ignore
      }
      try {
        await db.execute('ALTER TABLE ${GymSetFields.tableName} ADD COLUMN ${GymSetFields.isWarmup} INTEGER DEFAULT 0');
      } catch (e) {
        // Ignore
      }
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

    // Gym Exercises (formerly Equipment)
    await db.execute('''
CREATE TABLE IF NOT EXISTS ${GymExerciseFields.tableName} (
  ${GymExerciseFields.id} $idType,
  ${GymExerciseFields.name} $textType,
  ${GymExerciseFields.description} $textNullable
)
''');

    // Gym Plans
    await db.execute('''
CREATE TABLE IF NOT EXISTS ${GymPlanFields.tableName} (
  ${GymPlanFields.id} $idType,
  ${GymPlanFields.name} $textType
)
''');

    // Gym Plan Exercises
    await db.execute('''
CREATE TABLE IF NOT EXISTS ${GymPlanExerciseFields.tableName} (
  ${GymPlanExerciseFields.id} $idType,
  ${GymPlanExerciseFields.planId} $intType,
  ${GymPlanExerciseFields.exerciseId} $intType,
  ${GymPlanExerciseFields.setCount} $intType,
  ${GymPlanExerciseFields.sortOrder} $intType,
  ${GymPlanExerciseFields.targetReps} $textNullable,
  ${GymPlanExerciseFields.isWarmup} $boolType,
  FOREIGN KEY (${GymPlanExerciseFields.planId}) REFERENCES ${GymPlanFields.tableName} (${GymPlanFields.id}) ON DELETE CASCADE,
  FOREIGN KEY (${GymPlanExerciseFields.exerciseId}) REFERENCES ${GymExerciseFields.tableName} (${GymExerciseFields.id})
)
''');

    // Gym Trainings
    await db.execute('''
CREATE TABLE IF NOT EXISTS ${GymTrainingFields.tableName} (
  ${GymTrainingFields.id} $idType,
  ${GymTrainingFields.planId} $intType,
  ${GymTrainingFields.date} $textType,
  ${GymTrainingFields.note} $textNullable,
  FOREIGN KEY (${GymTrainingFields.planId}) REFERENCES ${GymPlanFields.tableName} (${GymPlanFields.id})
)
''');

    // Gym Sets
    await db.execute('''
CREATE TABLE IF NOT EXISTS ${GymSetFields.tableName} (
  ${GymSetFields.id} $idType,
  ${GymSetFields.trainingId} $intType,
  ${GymSetFields.exerciseId} $intType,
  ${GymSetFields.setNumber} $intType,
  ${GymSetFields.reps} $intNullable,
  ${GymSetFields.weight} $realType,
  ${GymSetFields.isDone} $boolType,
  ${GymSetFields.durationSeconds} $intNullable,
  ${GymSetFields.isWarmup} $boolType,
  FOREIGN KEY (${GymSetFields.trainingId}) REFERENCES ${GymTrainingFields.tableName} (${GymTrainingFields.id}) ON DELETE CASCADE,
  FOREIGN KEY (${GymSetFields.exerciseId}) REFERENCES ${GymExerciseFields.tableName} (${GymExerciseFields.id})
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

  // --- Gym CRUD Methods ---

  // Exercises
  Future<GymExercise> createExercise(GymExercise exercise) async {
    final db = await instance.database;
    final id = await db.insert(GymExerciseFields.tableName, exercise.toJson());
    return exercise.copyWith(id: id);
  }

  Future<int> updateExercise(GymExercise exercise) async {
    final db = await instance.database;
    return await db.update(
      GymExerciseFields.tableName,
      exercise.toJson(),
      where: '${GymExerciseFields.id} = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<List<GymExercise>> getAllExercises() async {
    final db = await instance.database;
    final result = await db.query(GymExerciseFields.tableName, orderBy: '${GymExerciseFields.name} ASC');
    return result.map((json) => GymExercise.fromJson(json)).toList();
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
  Future<GymTraining?> getLastTraining(int planId, {DateTime? beforeDate}) async {
    final db = await instance.database;

    String where = '${GymTrainingFields.planId} = ?';
    List<Object?> args = [planId];

    if (beforeDate != null) {
      where += ' AND ${GymTrainingFields.date} < ?';
      args.add(beforeDate.toIso8601String());
    }

    final result = await db.query(
      GymTrainingFields.tableName,
      where: where,
      whereArgs: args,
      orderBy: '${GymTrainingFields.date} DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      return GymTraining.fromJson(result.first);
    }
    return null;
  }

  // Get the latest set for a specific exercise (globally) to pre-fill values
  Future<GymSet?> getLatestSetForExercise(int exerciseId) async {
    final db = await instance.database;
    // Join trainings to order by date? Or rely on ID order if chronological?
    // Let's rely on ID order or join. For simplicity, ID order usually matches time if autoincrement.
    // Better to join training and order by date.

    final result = await db.rawQuery('''
      SELECT s.*
      FROM ${GymSetFields.tableName} s
      INNER JOIN ${GymTrainingFields.tableName} t ON s.${GymSetFields.trainingId} = t.${GymTrainingFields.id}
      WHERE s.${GymSetFields.exerciseId} = ?
      ORDER BY t.${GymTrainingFields.date} DESC, s.${GymSetFields.setNumber} DESC
      LIMIT 1
    ''', [exerciseId]);

    if (result.isNotEmpty) {
      return GymSet.fromJson(result.first);
    }
    return null;
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
