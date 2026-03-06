import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/models/kitchen/kitchen_history.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_tag.dart';
import 'package:diary_app/models/kitchen/kitchen_product.dart';
import 'package:diary_app/models/kitchen/recipe.dart';
import 'package:diary_app/models/kitchen/recipe_ingredient.dart';
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
      version: 11,
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
    await _createKitchenTables(db);
    await _createRecipeTables(db);
    await _createKitchenProductsTable(db);
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
    if (oldVersion < 6) {
      // Version 6: Add duration to trainings
      try {
        await db.execute('ALTER TABLE ${GymTrainingFields.tableName} ADD COLUMN ${GymTrainingFields.durationSeconds} INTEGER');
      } catch (e) {
        // Ignore
      }
    }
    if (oldVersion < 7) {
      // Version 7: Add rating to trainings
      try {
        await db.execute('ALTER TABLE ${GymTrainingFields.tableName} ADD COLUMN ${GymTrainingFields.rating} INTEGER');
      } catch (e) {
        // Ignore
      }
    }
    if (oldVersion < 8) {
      // Version 8: Add kitchen tables
      await _createKitchenTables(db);
    }
    if (oldVersion < 9) {
      // Version 9: Add kitchen history
      await _createKitchenHistoryTable(db);
    }
    if (oldVersion < 10) {
      // Version 10: Add recipe tables
      await _createRecipeTables(db);
    }
    if (oldVersion < 11) {
      // Version 11: Add kitchen products table
      await _createKitchenProductsTable(db);
      await _migrateKitchenItemsToProducts(db);
    }
  }

  Future _migrateKitchenItemsToProducts(Database db) async {
    // Populate the new kitchen_products table with existing distinct items
    final result = await db.rawQuery('''
      SELECT
        ${KitchenItemFields.name},
        ${KitchenItemFields.basisProdukt},
        ${KitchenItemFields.marke},
        ${KitchenItemFields.einheit},
        MAX(${KitchenItemFields.haltbarBis}) as maxHaltbarBis,
        MAX(${KitchenItemFields.hinzugefuegt}) as maxHinzugefuegt
      FROM ${KitchenItemFields.tableName}
      GROUP BY ${KitchenItemFields.name}
    ''');

    for (var row in result) {
      int? defaultHaltbarkeitTage;

      final haltbarBisStr = row['maxHaltbarBis'] as String?;
      final hinzugefuegtStr = row['maxHinzugefuegt'] as String?;

      if (haltbarBisStr != null && hinzugefuegtStr != null) {
        try {
          final haltbarBis = DateTime.parse(haltbarBisStr);
          final hinzugefuegt = DateTime.parse(hinzugefuegtStr);
          final diff = haltbarBis.difference(hinzugefuegt).inDays;
          if (diff > 0) defaultHaltbarkeitTage = diff;
        } catch (e) {
          // Ignore parsing errors for migration
        }
      }

      await db.insert(
        KitchenProductFields.tableName,
        {
          KitchenProductFields.name: row[KitchenItemFields.name],
          KitchenProductFields.basisProdukt: row[KitchenItemFields.basisProdukt],
          KitchenProductFields.marke: row[KitchenItemFields.marke],
          KitchenProductFields.einheit: row[KitchenItemFields.einheit],
          KitchenProductFields.defaultHaltbarkeitTage: defaultHaltbarkeitTage,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future _createKitchenProductsTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const intNullable = 'INTEGER';

    await db.execute('''
CREATE TABLE IF NOT EXISTS ${KitchenProductFields.tableName} (
  ${KitchenProductFields.id} $idType,
  ${KitchenProductFields.name} $textType UNIQUE,
  ${KitchenProductFields.basisProdukt} $textType,
  ${KitchenProductFields.marke} $textNullable,
  ${KitchenProductFields.einheit} $textType,
  ${KitchenProductFields.defaultHaltbarkeitTage} $intNullable
)
''');
  }

  Future _createRecipeTables(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const intNullable = 'INTEGER';

    await db.execute('''
CREATE TABLE IF NOT EXISTS ${RecipeFields.tableName} (
  ${RecipeFields.id} $idType,
  ${RecipeFields.name} $textType,
  ${RecipeFields.description} $textNullable,
  ${RecipeFields.prepTimeMinutes} $intNullable,
  ${RecipeFields.createdAt} $textType
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS ${RecipeIngredientFields.tableName} (
  ${RecipeIngredientFields.id} $idType,
  ${RecipeIngredientFields.recipeId} $intType,
  ${RecipeIngredientFields.basisProdukt} $textType,
  ${RecipeIngredientFields.menge} $realType,
  ${RecipeIngredientFields.einheit} $textType,
  ${RecipeIngredientFields.sortOrder} $intType,
  FOREIGN KEY (${RecipeIngredientFields.recipeId}) REFERENCES ${RecipeFields.tableName} (${RecipeFields.id}) ON DELETE CASCADE
)
''');
  }

  Future _createKitchenHistoryTable(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intNullable = 'INTEGER';

    await db.execute('''
CREATE TABLE IF NOT EXISTS ${KitchenHistoryFields.tableName} (
  ${KitchenHistoryFields.id} $idType,
  ${KitchenHistoryFields.itemId} $intNullable,
  ${KitchenHistoryFields.name} $textType,
  ${KitchenHistoryFields.basisProdukt} $textType,
  ${KitchenHistoryFields.marke} $textNullable,
  ${KitchenHistoryFields.menge} $realType,
  ${KitchenHistoryFields.einheit} $textType,
  ${KitchenHistoryFields.eventType} $textType,
  ${KitchenHistoryFields.timestamp} $textType
)
''');
  }

  Future _createKitchenTables(Database db) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE IF NOT EXISTS ${KitchenItemFields.tableName} (
  ${KitchenItemFields.id} $idType,
  ${KitchenItemFields.name} $textType,
  ${KitchenItemFields.basisProdukt} $textType,
  ${KitchenItemFields.marke} $textNullable,
  ${KitchenItemFields.menge} $realType,
  ${KitchenItemFields.einheit} $textType,
  ${KitchenItemFields.haltbarBis} $textNullable,
  ${KitchenItemFields.hinzugefuegt} $textType
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS ${KitchenTagFields.tableName} (
  ${KitchenTagFields.id} $idType,
  ${KitchenTagFields.name} TEXT NOT NULL UNIQUE
)
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS ${KitchenItemTagFields.tableName} (
  ${KitchenItemTagFields.itemId} $intType,
  ${KitchenItemTagFields.tagId} $intType,
  PRIMARY KEY (${KitchenItemTagFields.itemId}, ${KitchenItemTagFields.tagId}),
  FOREIGN KEY (${KitchenItemTagFields.itemId}) REFERENCES ${KitchenItemFields.tableName} (${KitchenItemFields.id}) ON DELETE CASCADE,
  FOREIGN KEY (${KitchenItemTagFields.tagId}) REFERENCES ${KitchenTagFields.tableName} (${KitchenTagFields.id}) ON DELETE CASCADE
)
''');

    await _createKitchenHistoryTable(db);
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
  ${GymTrainingFields.durationSeconds} $intNullable,
  ${GymTrainingFields.rating} $intNullable,
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

  // --- Recipe CRUD Methods ---

  Future<Recipe> createRecipe(Recipe recipe, List<RecipeIngredient> ingredients) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final recipeId = await txn.insert(RecipeFields.tableName, recipe.toJson());

      for (var ingredient in ingredients) {
        final ingredientWithId = ingredient.copyWith(recipeId: recipeId);
        await txn.insert(RecipeIngredientFields.tableName, ingredientWithId.toJson());
      }
      return recipe.copyWith(id: recipeId);
    });
  }

  Future<int> updateRecipe(Recipe recipe, List<RecipeIngredient> ingredients) async {
    final db = await instance.database;
    return await db.transaction((txn) async {
      final rowsAffected = await txn.update(
        RecipeFields.tableName,
        recipe.toJson(),
        where: '${RecipeFields.id} = ?',
        whereArgs: [recipe.id],
      );

      // Replace ingredients
      await txn.delete(
        RecipeIngredientFields.tableName,
        where: '${RecipeIngredientFields.recipeId} = ?',
        whereArgs: [recipe.id],
      );

      for (var ingredient in ingredients) {
        final ingredientWithId = ingredient.copyWith(recipeId: recipe.id);
        await txn.insert(RecipeIngredientFields.tableName, ingredientWithId.toJson());
      }

      return rowsAffected;
    });
  }

  Future<int> deleteRecipe(int id) async {
    final db = await instance.database;
    return await db.delete(
      RecipeFields.tableName,
      where: '${RecipeFields.id} = ?',
      whereArgs: [id],
    );
  }

  Future<List<Recipe>> getAllRecipes() async {
    final db = await instance.database;
    final result = await db.query(
      RecipeFields.tableName,
      orderBy: '${RecipeFields.name} ASC',
    );
    return result.map((json) => Recipe.fromJson(json)).toList();
  }

  Future<List<RecipeIngredient>> getIngredientsForRecipe(int recipeId) async {
    final db = await instance.database;
    final result = await db.query(
      RecipeIngredientFields.tableName,
      where: '${RecipeIngredientFields.recipeId} = ?',
      whereArgs: [recipeId],
      orderBy: '${RecipeIngredientFields.sortOrder} ASC',
    );
    return result.map((json) => RecipeIngredient.fromJson(json)).toList();
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
      orderBy: '${GymSetFields.exerciseId}, ${GymSetFields.setNumber}',
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

    // --- Backup/Restore Helpers ---

    Future<void> clearDiary() async {
      final db = await instance.database;
      await db.delete(DiaryEntryFields.tableName);
    }

    Future<void> clearGym() async {
      final db = await instance.database;
      await db.delete(GymSetFields.tableName);
      await db.delete(GymTrainingFields.tableName);
      await db.delete(GymPlanExerciseFields.tableName);
      await db.delete(GymPlanFields.tableName);
      await db.delete(GymExerciseFields.tableName);
    }

    Future<void> clearKitchen() async {
      final db = await instance.database;
      await db.delete(KitchenItemTagFields.tableName);
      await db.delete(KitchenTagFields.tableName);
      await db.delete(KitchenHistoryFields.tableName);
      await db.delete(KitchenProductFields.tableName);
      await db.delete(KitchenItemFields.tableName);
    }

    Future<void> clearRecipes() async {
      final db = await instance.database;
      await db.delete(RecipeIngredientFields.tableName);
      await db.delete(RecipeFields.tableName);
    }

    Future<void> batchInsert(String tableName, List<dynamic> records) async {
      final db = await instance.database;
      final batch = db.batch();
      for (var record in records) {
        batch.insert(tableName, Map<String, dynamic>.from(record));
      }
      await batch.commit(noResult: true);
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
    _database = null; // Clear cached instance so tests can recreate it
  }
}
