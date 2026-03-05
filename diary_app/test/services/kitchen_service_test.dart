import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/services/kitchen_service.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_history.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  late KitchenService kitchenService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    DatabaseHelper.instance = DatabaseHelper.test();
    kitchenService = KitchenService();
    // Clear db for clean slate
    final db = await DatabaseHelper.instance.database;
    await db.delete(KitchenItemFields.tableName);
    await db.delete(KitchenHistoryFields.tableName);
  });

  test('importFromJson with multiplier should create multiple items', () async {
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

  test('trashItem should delete item and add to history', () async {
    final newItem = KitchenItem(
        name: 'TestItem',
        basisProdukt: 'TestBasis',
        menge: 100,
        einheit: 'g',
        hinzugefuegt: DateTime.now(),
    );
    final created = await kitchenService.createItem(newItem, []);

    expect(created.id, isNotNull);

    await kitchenService.trashItem(created.id!);

    final items = await kitchenService.getAllItems();
    expect(items.isEmpty, true);

    final history = await kitchenService.getHistoryEvents();
    expect(history.length, 1);
    expect(history.first.eventType, 'trashed');
    expect(history.first.name, 'TestItem');
  });
}
