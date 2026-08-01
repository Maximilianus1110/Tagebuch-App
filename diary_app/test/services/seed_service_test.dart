import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/services/kitchen_service.dart';
import 'package:diary_app/services/seed_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class MockDatabaseHelper extends DatabaseHelper {
  MockDatabaseHelper() : super.test();

  List<DiaryEntry> entries = [];

  @override
  Future<List<DiaryEntry>> readAllEntries() async {
    return entries.where((e) => e.deletedAt == null).toList();
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = DatabaseHelper.instance;
    await db.clearDiary();
    await db.clearGym();
    await db.clearKitchen();
    await db.clearRecipes();
  });

  test('SeedService populates data when seedDatabase is called', () async {
    final db = DatabaseHelper.instance;

    await SeedService.seedDatabase(overwrite: true);

    final entries = await db.readAllEntries();
    expect(entries.isNotEmpty, isTrue);

    final exercises = await db.getAllExercises();
    expect(exercises.isNotEmpty, isTrue);

    final plans = await db.getAllPlans();
    expect(plans.isNotEmpty, isTrue);

    final kitchenItems = await KitchenService().getAllItems();
    expect(kitchenItems.isNotEmpty, isTrue);

    final recipes = await db.getAllRecipes();
    expect(recipes.isNotEmpty, isTrue);

    // Clean up to prevent affecting other test suites
    await db.clearDiary();
    await db.clearGym();
    await db.clearKitchen();
    await db.clearRecipes();
  });
}
