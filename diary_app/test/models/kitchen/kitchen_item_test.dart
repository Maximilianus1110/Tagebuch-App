import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';

void main() {
  group('KitchenItem', () {
    test('KitchenItem should be created with required fields', () {
      final item = KitchenItem(
        name: 'Milk',
        basisProdukt: 'Milk',
        menge: 1000,
        einheit: 'ml',
        hinzugefuegt: DateTime(2023, 1, 1),
      );

      expect(item.id, isNull);
      expect(item.name, 'Milk');
      expect(item.basisProdukt, 'Milk');
      expect(item.marke, isNull);
      expect(item.menge, 1000);
      expect(item.einheit, 'ml');
      expect(item.haltbarBis, isNull);
      expect(item.hinzugefuegt, DateTime(2023, 1, 1));
    });

    test('KitchenItem should copyWith fields', () {
      final item = KitchenItem(
        id: 1,
        name: 'Milk',
        basisProdukt: 'Milk',
        marke: 'BrandX',
        menge: 1000,
        einheit: 'ml',
        haltbarBis: DateTime(2023, 1, 10),
        hinzugefuegt: DateTime(2023, 1, 1),
      );

      final copied = item.copyWith(
        name: 'Soy Milk',
        menge: 500,
        marke: 'BrandY',
        haltbarBis: null, // copyWith handles null by using original value if null is passed, but it can't clear a value using copyWith as implemented.
      );

      expect(copied.id, 1);
      expect(copied.name, 'Soy Milk');
      expect(copied.basisProdukt, 'Milk');
      expect(copied.marke, 'BrandY');
      expect(copied.menge, 500);
      expect(copied.einheit, 'ml');
      expect(copied.haltbarBis, DateTime(2023, 1, 10)); // Remains unchanged because of how copyWith is usually written
      expect(copied.hinzugefuegt, DateTime(2023, 1, 1));
    });

    test('KitchenItem should serialize and deserialize to JSON', () {
      final item = KitchenItem(
        id: 2,
        name: 'Apple',
        basisProdukt: 'Apple',
        marke: 'FarmZ',
        menge: 5,
        einheit: 'Stück',
        haltbarBis: DateTime(2023, 2, 1),
        hinzugefuegt: DateTime(2023, 1, 1),
      );

      final json = item.toJson();

      expect(json[KitchenItemFields.id], 2);
      expect(json[KitchenItemFields.name], 'Apple');
      expect(json[KitchenItemFields.basisProdukt], 'Apple');
      expect(json[KitchenItemFields.marke], 'FarmZ');
      expect(json[KitchenItemFields.menge], 5.0);
      expect(json[KitchenItemFields.einheit], 'Stück');
      expect(json[KitchenItemFields.haltbarBis], DateTime(2023, 2, 1).toIso8601String());
      expect(json[KitchenItemFields.hinzugefuegt], DateTime(2023, 1, 1).toIso8601String());

      final fromJsonItem = KitchenItem.fromJson(json);

      expect(fromJsonItem.id, 2);
      expect(fromJsonItem.name, 'Apple');
      expect(fromJsonItem.basisProdukt, 'Apple');
      expect(fromJsonItem.marke, 'FarmZ');
      expect(fromJsonItem.menge, 5.0);
      expect(fromJsonItem.einheit, 'Stück');
      expect(fromJsonItem.haltbarBis, DateTime(2023, 2, 1));
      expect(fromJsonItem.hinzugefuegt, DateTime(2023, 1, 1));
    });

    test('KitchenItem should handle null optionals in JSON', () {
      final item = KitchenItem(
        name: 'Water',
        basisProdukt: 'Water',
        menge: 2000,
        einheit: 'ml',
        hinzugefuegt: DateTime(2023, 1, 1),
      );

      final json = item.toJson();
      expect(json[KitchenItemFields.id], isNull);
      expect(json[KitchenItemFields.marke], isNull);
      expect(json[KitchenItemFields.haltbarBis], isNull);

      final fromJsonItem = KitchenItem.fromJson(json);
      expect(fromJsonItem.id, isNull);
      expect(fromJsonItem.marke, isNull);
      expect(fromJsonItem.haltbarBis, isNull);
    });
  });
}
