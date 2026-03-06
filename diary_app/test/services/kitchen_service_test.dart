import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_product.dart';
import 'package:diary_app/services/kitchen_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('KitchenService', () {
    late DatabaseHelper dbHelper;
    late KitchenService kitchenService;

    setUp(() async {
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/diary_kitchen_test.db';
      await databaseFactory.deleteDatabase(path);

      dbHelper = DatabaseHelper.test();
      DatabaseHelper.instance = dbHelper;

      // We must explicitly ensure db is opened before we start using it on a fresh DB.
      await dbHelper.database;

      kitchenService = KitchenService();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('Should create an item with tags', () async {
      final item = KitchenItem(
        name: 'Milk',
        basisProdukt: 'Milk',
        menge: 1000,
        einheit: 'ml',
        hinzugefuegt: DateTime.now(),
      );

      final created = await kitchenService.createItem(item, ['Bio', 'Drink']);
      expect(created.id, isNotNull);

      final tags = await kitchenService.getTagsForItem(created.id!);
      expect(tags.length, 2);
      expect(tags.any((t) => t.name == 'Bio'), isTrue);
    });

    test('Should update an item and its tags', () async {
      final item = KitchenItem(
        name: 'Cheese',
        basisProdukt: 'Cheese',
        menge: 200,
        einheit: 'g',
        hinzugefuegt: DateTime.now(),
      );
      final created = await kitchenService.createItem(item, ['Dairy']);

      final updated = created.copyWith(menge: 150);
      await kitchenService.updateItem(updated, ['Snack', 'Dairy']);

      final items = await kitchenService.getAllItems();
      final updatedItem = items.firstWhere((i) => i.id == created.id);
      expect(updatedItem.menge, 150.0);

      final tags = await kitchenService.getTagsForItem(created.id!);
      expect(tags.length, 2);
      expect(tags.any((t) => t.name == 'Snack'), isTrue);
    });

    test('consumeItem should reduce quantity and create history event', () async {
      final item = await kitchenService.createItem(
        KitchenItem(
          name: 'Rice',
          basisProdukt: 'Rice',
          menge: 1000,
          einheit: 'g',
          hinzugefuegt: DateTime.now(),
        ),
        []
      );

      // Consume 300g
      await kitchenService.consumeItem(item.id!, 300);

      final items = await kitchenService.getAllItems();
      final updatedItem = items.firstWhere((i) => i.id == item.id);
      expect(updatedItem.menge, 700.0);

      final history = await kitchenService.getHistoryEvents();
      final event = history.firstWhere((h) => h.itemId == item.id && h.eventType == 'consumed');
      expect(event.menge, 300.0);
    });

    test('consumeItem fully should delete item and create history event', () async {
      final item = await kitchenService.createItem(
        KitchenItem(
          name: 'Apple',
          basisProdukt: 'Apple',
          menge: 1,
          einheit: 'Stück',
          hinzugefuegt: DateTime.now(),
        ),
        []
      );

      await kitchenService.consumeItem(item.id!, 1);

      final items = await kitchenService.getAllItems();
      expect(items.any((i) => i.id == item.id), isFalse);

      final history = await kitchenService.getHistoryEvents();
      final event = history.firstWhere((h) => h.itemId == item.id && h.eventType == 'consumed');
      expect(event.menge, 1.0);
    });

    test('trashItem should delete item and create trashed history event', () async {
      final item = await kitchenService.createItem(
        KitchenItem(
          name: 'Yogurt',
          basisProdukt: 'Yogurt',
          menge: 500,
          einheit: 'g',
          hinzugefuegt: DateTime.now(),
        ),
        []
      );

      await kitchenService.trashItem(item.id!);

      final items = await kitchenService.getAllItems();
      expect(items.any((i) => i.id == item.id), isFalse);

      final history = await kitchenService.getHistoryEvents();
      final event = history.firstWhere((h) => h.itemId == item.id && h.eventType == 'trashed');
      expect(event.menge, 500.0);
    });

    test('importFromJson with multiplier should create multiple items', () async {
      // Clear DB manually inside the test to avoid residual items from other tests affecting the count
      final db = await DatabaseHelper.instance.database;
      await db.delete(KitchenItemFields.tableName);

      const jsonStr = '''[
        {
          "name": "Sahne",
          "basis_produkt": "Sahne",
          "menge": 200,
          "einheit": "g",
          "haltbar_tage": 10,
          "packungen": 3
        }
      ]''';

      final count = await kitchenService.importFromJson(jsonStr);
      expect(count, 3);

      final items = await kitchenService.getAllItems();
      expect(items.length, 3);
    });

    test('KitchenService automatically creates KitchenProduct on createItem', () async {
      final now = DateTime.now();
      final item = KitchenItem(
        name: 'Test Spaghetti',
        basisProdukt: 'Spaghetti',
        marke: 'Barilla',
        menge: 500,
        einheit: 'g',
        haltbarBis: now.add(const Duration(days: 30)),
        hinzugefuegt: now,
      );

      await kitchenService.createItem(item, ['Nudeln']);

      final db = await dbHelper.database;
      final products = await db.query(KitchenProductFields.tableName, where: 'name = ?', whereArgs: ['Test Spaghetti']);

      expect(products.length, 1);
      final product = KitchenProduct.fromJson(products.first);
      expect(product.name, 'Test Spaghetti');
      expect(product.basisProdukt, 'Spaghetti');
      expect(product.marke, 'Barilla');
      expect(product.einheit, 'g');
      expect(product.defaultHaltbarkeitTage, 30);
    });

    test('KitchenService updates KitchenProduct on updateItem', () async {
      final now = DateTime.now();
      final item = KitchenItem(
        name: 'Test Milk',
        basisProdukt: 'Milk',
        menge: 1000,
        einheit: 'ml',
        haltbarBis: now.add(const Duration(days: 7)),
        hinzugefuegt: now,
      );

      final created = await kitchenService.createItem(item, []);

      // Update the item, changing expiry to 14 days
      final updatedItem = created.copyWith(
        haltbarBis: now.add(const Duration(days: 14)),
        hinzugefuegt: now,
      );

      await kitchenService.updateItem(updatedItem, []);

      final db = await dbHelper.database;
      final products = await db.query(KitchenProductFields.tableName, where: 'name = ?', whereArgs: ['Test Milk']);

      expect(products.length, 1);
      final product = KitchenProduct.fromJson(products.first);
      expect(product.defaultHaltbarkeitTage, 14);
    });
  });
}
