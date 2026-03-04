import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_tag.dart';
import 'package:sqflite/sqflite.dart';

class KitchenService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- Items ---

  Future<KitchenItem> createItem(KitchenItem item, List<String> tagNames) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Insert item
      final id = await txn.insert(KitchenItemFields.tableName, item.toJson());
      final newItem = item.copyWith(id: id);

      // 2. Insert tags and relationships
      for (final tagName in tagNames) {
        final tag = tagName.trim();
        if (tag.isEmpty) continue;

        // Try to find existing tag
        final existingTags = await txn.query(
          KitchenTagFields.tableName,
          where: '${KitchenTagFields.name} = ?',
          whereArgs: [tag],
        );

        int tagId;
        if (existingTags.isNotEmpty) {
          tagId = existingTags.first[KitchenTagFields.id] as int;
        } else {
          // Create new tag
          tagId = await txn.insert(
            KitchenTagFields.tableName,
            {KitchenTagFields.name: tag},
          );
        }

        // Link item to tag
        await txn.insert(
          KitchenItemTagFields.tableName,
          {
            KitchenItemTagFields.itemId: id,
            KitchenItemTagFields.tagId: tagId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      return newItem;
    });
  }

  Future<KitchenItem> updateItem(KitchenItem item, List<String> tagNames) async {
    final db = await _dbHelper.database;
    return await db.transaction((txn) async {
      // 1. Update item
      await txn.update(
        KitchenItemFields.tableName,
        item.toJson(),
        where: '${KitchenItemFields.id} = ?',
        whereArgs: [item.id],
      );

      // 2. Delete old tags relationships
      await txn.delete(
        KitchenItemTagFields.tableName,
        where: '${KitchenItemTagFields.itemId} = ?',
        whereArgs: [item.id],
      );

      // 3. Insert new tags and relationships
      for (final tagName in tagNames) {
        final tag = tagName.trim();
        if (tag.isEmpty) continue;

        final existingTags = await txn.query(
          KitchenTagFields.tableName,
          where: '${KitchenTagFields.name} = ?',
          whereArgs: [tag],
        );

        int tagId;
        if (existingTags.isNotEmpty) {
          tagId = existingTags.first[KitchenTagFields.id] as int;
        } else {
          tagId = await txn.insert(
            KitchenTagFields.tableName,
            {KitchenTagFields.name: tag},
          );
        }

        await txn.insert(
          KitchenItemTagFields.tableName,
          {
            KitchenItemTagFields.itemId: item.id,
            KitchenItemTagFields.tagId: tagId,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }

      return item;
    });
  }

  Future<List<KitchenItem>> getAllItems() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      KitchenItemFields.tableName,
      orderBy: '${KitchenItemFields.haltbarBis} ASC',
    );
    return result.map((json) => KitchenItem.fromJson(json)).toList();
  }

  Future<List<KitchenTag>> getTagsForItem(int itemId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT t.* FROM ${KitchenTagFields.tableName} t
      INNER JOIN ${KitchenItemTagFields.tableName} it ON t.${KitchenTagFields.id} = it.${KitchenItemTagFields.tagId}
      WHERE it.${KitchenItemTagFields.itemId} = ?
    ''', [itemId]);
    return result.map((json) => KitchenTag.fromJson(json)).toList();
  }

  // Consume (verbrauchen) an item partially or fully
  Future<void> consumeItem(int itemId, double consumedAmount) async {
    final db = await _dbHelper.database;

    // Get current item
    final itemMap = await db.query(
      KitchenItemFields.tableName,
      where: '${KitchenItemFields.id} = ?',
      whereArgs: [itemId],
    );

    if (itemMap.isEmpty) return;

    final item = KitchenItem.fromJson(itemMap.first);
    final newAmount = item.menge - consumedAmount;

    if (newAmount <= 0) {
      // Delete item
      await db.delete(
        KitchenItemFields.tableName,
        where: '${KitchenItemFields.id} = ?',
        whereArgs: [itemId],
      );
    } else {
      // Update item amount
      await db.update(
        KitchenItemFields.tableName,
        {KitchenItemFields.menge: newAmount},
        where: '${KitchenItemFields.id} = ?',
        whereArgs: [itemId],
      );
    }
  }

  // For future use if tags need to be suggested
  Future<List<KitchenTag>> getAllTags() async {
    final db = await _dbHelper.database;
    final result = await db.query(KitchenTagFields.tableName, orderBy: '${KitchenTagFields.name} ASC');
    return result.map((json) => KitchenTag.fromJson(json)).toList();
  }

  // Get distinct item names and their details for autocomplete
  Future<List<Map<String, dynamic>>> getDistinctItemsForAutocomplete() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT MAX(${KitchenItemFields.id}) as id,
             ${KitchenItemFields.name},
             ${KitchenItemFields.basisProdukt},
             ${KitchenItemFields.marke},
             ${KitchenItemFields.einheit}
      FROM ${KitchenItemFields.tableName}
      GROUP BY ${KitchenItemFields.name}
    ''');

    List<Map<String, dynamic>> itemsWithTags = [];
    for (var row in result) {
      final itemId = row['id'] as int;
      final tags = await getTagsForItem(itemId);
      final tagNames = tags.map((t) => t.name).join(', ');

      itemsWithTags.add({
        'name': row[KitchenItemFields.name],
        'basisProdukt': row[KitchenItemFields.basisProdukt],
        'marke': row[KitchenItemFields.marke],
        'einheit': row[KitchenItemFields.einheit],
        'tags': tagNames,
      });
    }

    return itemsWithTags;
  }
}
