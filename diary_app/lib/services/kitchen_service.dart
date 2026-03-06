import 'dart:convert';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/kitchen/kitchen_history.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/kitchen_product.dart';
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

      // 1.5 Update or Insert Product
      int? defaultHaltbarkeitTage;
      if (item.haltbarBis != null) {
        final diff = item.haltbarBis!.difference(item.hinzugefuegt).inDays;
        if (diff > 0) defaultHaltbarkeitTage = diff;
      }

      final product = KitchenProduct(
        name: item.name,
        basisProdukt: item.basisProdukt,
        marke: item.marke,
        einheit: item.einheit,
        defaultHaltbarkeitTage: defaultHaltbarkeitTage,
      );

      await txn.insert(
        KitchenProductFields.tableName,
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

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

      // 1.5 Update or Insert Product
      int? defaultHaltbarkeitTage;
      if (item.haltbarBis != null) {
        final diff = item.haltbarBis!.difference(item.hinzugefuegt).inDays;
        if (diff > 0) defaultHaltbarkeitTage = diff;
      }

      final product = KitchenProduct(
        name: item.name,
        basisProdukt: item.basisProdukt,
        marke: item.marke,
        einheit: item.einheit,
        defaultHaltbarkeitTage: defaultHaltbarkeitTage,
      );

      await txn.insert(
        KitchenProductFields.tableName,
        product.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
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
    final actualConsumed = newAmount < 0 ? item.menge : consumedAmount;

    await db.transaction((txn) async {
      // Log in history
      final history = KitchenHistory(
        itemId: item.id,
        name: item.name,
        basisProdukt: item.basisProdukt,
        marke: item.marke,
        menge: actualConsumed,
        einheit: item.einheit,
        eventType: 'consumed',
        timestamp: DateTime.now(),
      );
      await txn.insert(KitchenHistoryFields.tableName, history.toJson());

      if (newAmount <= 0) {
        // Delete item
        await txn.delete(
          KitchenItemFields.tableName,
          where: '${KitchenItemFields.id} = ?',
          whereArgs: [itemId],
        );
      } else {
        // Update item amount
        await txn.update(
          KitchenItemFields.tableName,
          {KitchenItemFields.menge: newAmount},
          where: '${KitchenItemFields.id} = ?',
          whereArgs: [itemId],
        );
      }
    });
  }

  // Trash (wegschmeißen) an item completely
  Future<void> trashItem(int itemId) async {
    final db = await _dbHelper.database;

    final itemMap = await db.query(
      KitchenItemFields.tableName,
      where: '${KitchenItemFields.id} = ?',
      whereArgs: [itemId],
    );

    if (itemMap.isEmpty) return;

    final item = KitchenItem.fromJson(itemMap.first);

    await db.transaction((txn) async {
      final history = KitchenHistory(
        itemId: item.id,
        name: item.name,
        basisProdukt: item.basisProdukt,
        marke: item.marke,
        menge: item.menge, // The entire remaining amount is trashed
        einheit: item.einheit,
        eventType: 'trashed',
        timestamp: DateTime.now(),
      );
      await txn.insert(KitchenHistoryFields.tableName, history.toJson());

      await txn.delete(
        KitchenItemFields.tableName,
        where: '${KitchenItemFields.id} = ?',
        whereArgs: [itemId],
      );
    });
  }

  // For future use if tags need to be suggested
  Future<List<KitchenTag>> getAllTags() async {
    final db = await _dbHelper.database;
    final result = await db.query(KitchenTagFields.tableName, orderBy: '${KitchenTagFields.name} ASC');
    return result.map((json) => KitchenTag.fromJson(json)).toList();
  }

  Future<int> importFromJson(String jsonString) async {
    final List<dynamic> jsonList;
    try {
      jsonList = jsonDecode(jsonString) as List<dynamic>;
    } catch (e) {
      throw const FormatException('Ungültiges JSON Format.');
    }

    int importedCount = 0;
    final now = DateTime.now();
    final allowedUnits = ['g', 'kg', 'ml', 'l', 'Stück'];

    for (var itemMap in jsonList) {
      if (itemMap is! Map<String, dynamic>) continue;

      // Validate required fields
      final name = itemMap['name']?.toString().trim();
      final basisProdukt = itemMap['basis_produkt']?.toString().trim();
      final mengeRaw = itemMap['menge'];
      final einheitRaw = itemMap['einheit']?.toString().trim();

      if (name == null || name.isEmpty ||
          basisProdukt == null || basisProdukt.isEmpty ||
          mengeRaw == null ||
          einheitRaw == null || einheitRaw.isEmpty) {
        throw const FormatException('Fehlende Pflichtfelder (name, basis_produkt, menge, einheit).');
      }

      double menge = 0;
      if (mengeRaw is num) {
        menge = mengeRaw.toDouble();
      } else if (mengeRaw is String) {
        menge = double.tryParse(mengeRaw.replaceAll(',', '.')) ?? 0;
      }
      if (menge <= 0) {
        throw FormatException('Ungültige Menge für Produkt: $name');
      }

      String einheit = einheitRaw;
      if (!allowedUnits.contains(einheit)) {
        throw FormatException('Ungültige Einheit ($einheit) für Produkt: $name');
      }

      // Convert units
      if (einheit == 'kg') {
        menge *= 1000;
        einheit = 'g';
      } else if (einheit == 'l') {
        menge *= 1000;
        einheit = 'ml';
      }

      final marke = itemMap['marke']?.toString().trim();

      // Handle expiration
      DateTime? haltbarBis;
      final haltbarBisStr = itemMap['haltbar_bis']?.toString();
      final haltbarTage = itemMap['haltbar_tage'];

      if (haltbarBisStr != null && haltbarBisStr.isNotEmpty) {
        try {
          haltbarBis = DateTime.parse(haltbarBisStr);
        } catch (e) {
          throw FormatException('Ungültiges Datumsformat bei haltbar_bis für Produkt: $name');
        }
      } else if (haltbarTage is num) {
        haltbarBis = now.add(Duration(days: haltbarTage.toInt()));
      } else if (haltbarTage is String) {
         final days = int.tryParse(haltbarTage);
         if (days != null) {
           haltbarBis = now.add(Duration(days: days));
         }
      }

      if (haltbarBis == null) {
         throw FormatException('Entweder haltbar_bis oder haltbar_tage muss angegeben werden für Produkt: $name');
      }

      // Handle tags
      List<String> tags = [];
      if (itemMap['tags'] is List) {
        tags = (itemMap['tags'] as List).map((t) => t.toString().trim()).where((t) => t.isNotEmpty).toList();
      }

      // Handle multiplier (packungen / anzahl)
      int multiplier = 1;
      final packungenRaw = itemMap['packungen'] ?? itemMap['anzahl'];
      if (packungenRaw is num) {
        multiplier = packungenRaw.toInt();
      } else if (packungenRaw is String) {
        multiplier = int.tryParse(packungenRaw) ?? 1;
      }
      if (multiplier < 1) multiplier = 1;

      final newItem = KitchenItem(
        name: name,
        basisProdukt: basisProdukt,
        marke: marke?.isNotEmpty == true ? marke : null,
        menge: menge,
        einheit: einheit,
        haltbarBis: haltbarBis,
        hinzugefuegt: now,
      );

      for (int i = 0; i < multiplier; i++) {
        await createItem(newItem, tags);
        importedCount++;
      }
    }

    return importedCount;
  }

  // Get distinct item names and their details for autocomplete
  Future<List<Map<String, dynamic>>> getDistinctItemsForAutocomplete() async {
    final db = await _dbHelper.database;
    final result = await db.query(KitchenProductFields.tableName);

    List<Map<String, dynamic>> productsWithTags = [];
    for (var row in result) {
      final name = row[KitchenProductFields.name] as String;

      // Try to find the latest item with this name to get its tags
      final latestItemResult = await db.query(
        KitchenItemFields.tableName,
        where: '${KitchenItemFields.name} = ?',
        whereArgs: [name],
        orderBy: '${KitchenItemFields.id} DESC',
        limit: 1,
      );

      String tagNames = '';
      if (latestItemResult.isNotEmpty) {
         final itemId = latestItemResult.first[KitchenItemFields.id] as int;
         final tags = await getTagsForItem(itemId);
         tagNames = tags.map((t) => t.name).join(', ');
      }

      productsWithTags.add({
        'name': name,
        'basisProdukt': row[KitchenProductFields.basisProdukt],
        'marke': row[KitchenProductFields.marke],
        'einheit': row[KitchenProductFields.einheit],
        'defaultHaltbarkeitTage': row[KitchenProductFields.defaultHaltbarkeitTage],
        'tags': tagNames,
      });
    }

    return productsWithTags;
  }

  // --- Statistics Methods ---

  Future<List<KitchenHistory>> getHistoryEvents() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      KitchenHistoryFields.tableName,
      orderBy: '${KitchenHistoryFields.timestamp} DESC',
    );
    return result.map((json) => KitchenHistory.fromJson(json)).toList();
  }
}
