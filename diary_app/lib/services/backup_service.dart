import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/models/kitchen/kitchen_history.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_product.dart';
import 'package:diary_app/models/kitchen/kitchen_tag.dart';
import 'package:diary_app/models/kitchen/recipe.dart';
import 'package:diary_app/models/kitchen/recipe_ingredient.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> createBackup({
    required bool includeDiary,
    required bool includeGym,
    required bool includeKitchen,
    required bool includeRecipes,
  }) async {
    final archive = Archive();

    if (includeDiary) {
      final diaryData = await _exportDiary();
      archive.addFile(ArchiveFile('diary.json', diaryData.length, diaryData));
    }

    if (includeGym) {
      final gymData = await _exportGym();
      archive.addFile(ArchiveFile('gym.json', gymData.length, gymData));
    }

    if (includeKitchen) {
      final kitchenData = await _exportKitchen();
      archive.addFile(ArchiveFile('kitchen.json', kitchenData.length, kitchenData));
    }

    if (includeRecipes) {
      final recipesData = await _exportRecipes();
      archive.addFile(ArchiveFile('recipes.json', recipesData.length, recipesData));
    }

    if (archive.isEmpty) return; // Nothing selected

    final zipData = ZipEncoder().encode(archive);

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
    final file = File('${tempDir.path}/diary_backup_$timestamp.zip');
    await file.writeAsBytes(zipData); // ZipEncoder.encode guarantees not null for valid input

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(file.path)], text: 'Tagebuch App Backup');
  }

  Future<bool> restoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any, // Android can sometimes be picky with custom zip extensions
      );

      if (result == null || result.files.single.path == null) {
        return false; // User canceled
      }

      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      final archive = ZipDecoder().decodeBytes(bytes);
      bool dataRestored = false;

      for (final archiveFile in archive) {
        if (archiveFile.isFile) {
          final filename = archiveFile.name;
          final data = archiveFile.content as List<int>;
          final jsonString = utf8.decode(data);
          final dynamic jsonData = jsonDecode(jsonString);

          if (filename == 'diary.json') {
            await _importDiary(jsonData);
            dataRestored = true;
          } else if (filename == 'gym.json') {
            await _importGym(jsonData);
            dataRestored = true;
          } else if (filename == 'kitchen.json') {
            await _importKitchen(jsonData);
            dataRestored = true;
          } else if (filename == 'recipes.json') {
            await _importRecipes(jsonData);
            dataRestored = true;
          }
        }
      }
      return dataRestored;
    } catch (e) {
      // Print error to console and return false to indicate failure to UI
      // ignore: avoid_print
      print('Error restoring backup: $e');
      return false;
    }
  }

  // --- Export Helpers ---

  Future<List<int>> _exportDiary() async {
    final db = await _db.database;
    final entries = await db.query(DiaryEntryFields.tableName);
    return utf8.encode(jsonEncode({'entries': entries}));
  }

  Future<List<int>> _exportGym() async {
    final db = await _db.database;
    final exercises = await db.query(GymExerciseFields.tableName);
    final plans = await db.query(GymPlanFields.tableName);
    final planExercises = await db.query(GymPlanExerciseFields.tableName);
    final trainings = await db.query(GymTrainingFields.tableName);
    final sets = await db.query(GymSetFields.tableName);

    return utf8.encode(jsonEncode({
      'exercises': exercises,
      'plans': plans,
      'planExercises': planExercises,
      'trainings': trainings,
      'sets': sets,
    }));
  }

  Future<List<int>> _exportKitchen() async {
    final db = await _db.database;
    final items = await db.query(KitchenItemFields.tableName);
    final tags = await db.query(KitchenTagFields.tableName);
    final itemTags = await db.query(KitchenItemTagFields.tableName);
    final history = await db.query(KitchenHistoryFields.tableName);
    final products = await db.query(KitchenProductFields.tableName);

    return utf8.encode(jsonEncode({
      'items': items,
      'tags': tags,
      'itemTags': itemTags,
      'history': history,
      'products': products,
    }));
  }

  Future<List<int>> _exportRecipes() async {
    final db = await _db.database;
    final recipes = await db.query(RecipeFields.tableName);
    final ingredients = await db.query(RecipeIngredientFields.tableName);

    return utf8.encode(jsonEncode({
      'recipes': recipes,
      'ingredients': ingredients,
    }));
  }

  // --- Import Helpers ---

  Future<void> _importDiary(dynamic data) async {
    final entries = data['entries'] as List<dynamic>?;
    if (entries != null) {
      await _db.clearDiary();
      await _db.batchInsert(DiaryEntryFields.tableName, entries);
    }
  }

  Future<void> _importGym(dynamic data) async {
    final exercises = data['exercises'] as List<dynamic>?;
    final plans = data['plans'] as List<dynamic>?;
    final planExercises = data['planExercises'] as List<dynamic>?;
    final trainings = data['trainings'] as List<dynamic>?;
    final sets = data['sets'] as List<dynamic>?;

    if (exercises != null || plans != null || planExercises != null || trainings != null || sets != null) {
        await _db.clearGym();
        if (exercises != null) await _db.batchInsert(GymExerciseFields.tableName, exercises);
        if (plans != null) await _db.batchInsert(GymPlanFields.tableName, plans);
        if (planExercises != null) await _db.batchInsert(GymPlanExerciseFields.tableName, planExercises);
        if (trainings != null) await _db.batchInsert(GymTrainingFields.tableName, trainings);
        if (sets != null) await _db.batchInsert(GymSetFields.tableName, sets);
    }
  }

  Future<void> _importKitchen(dynamic data) async {
    final items = data['items'] as List<dynamic>?;
    final tags = data['tags'] as List<dynamic>?;
    final itemTags = data['itemTags'] as List<dynamic>?;
    final history = data['history'] as List<dynamic>?;
    final products = data['products'] as List<dynamic>?;

    if (items != null || tags != null || itemTags != null || history != null || products != null) {
        await _db.clearKitchen();
        if (items != null) await _db.batchInsert(KitchenItemFields.tableName, items);
        if (tags != null) await _db.batchInsert(KitchenTagFields.tableName, tags);
        if (itemTags != null) await _db.batchInsert(KitchenItemTagFields.tableName, itemTags);
        if (history != null) await _db.batchInsert(KitchenHistoryFields.tableName, history);
        if (products != null) await _db.batchInsert(KitchenProductFields.tableName, products);
    }
  }

  Future<void> _importRecipes(dynamic data) async {
    final recipes = data['recipes'] as List<dynamic>?;
    final ingredients = data['ingredients'] as List<dynamic>?;

    if (recipes != null || ingredients != null) {
        await _db.clearRecipes();
        if (recipes != null) await _db.batchInsert(RecipeFields.tableName, recipes);
        if (ingredients != null) await _db.batchInsert(RecipeIngredientFields.tableName, ingredients);
    }
  }
}
