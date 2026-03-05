import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/models/kitchen/kitchen_history.dart';

void main() {
  group('KitchenHistory', () {
    test('KitchenHistory should be created with required fields', () {
      final history = KitchenHistory(
        name: 'Milk',
        basisProdukt: 'Milk',
        menge: 200,
        einheit: 'ml',
        eventType: 'consumed',
        timestamp: DateTime(2023, 1, 1),
      );

      expect(history.id, isNull);
      expect(history.itemId, isNull);
      expect(history.name, 'Milk');
      expect(history.basisProdukt, 'Milk');
      expect(history.marke, isNull);
      expect(history.menge, 200);
      expect(history.einheit, 'ml');
      expect(history.eventType, 'consumed');
      expect(history.timestamp, DateTime(2023, 1, 1));
    });

    test('KitchenHistory should copyWith fields', () {
      final history = KitchenHistory(
        id: 1,
        itemId: 10,
        name: 'Cheese',
        basisProdukt: 'Cheese',
        marke: 'BrandX',
        menge: 100,
        einheit: 'g',
        eventType: 'trashed',
        timestamp: DateTime(2023, 1, 1),
      );

      final copied = history.copyWith(
        id: 2,
        name: 'Cheddar',
        menge: 50,
      );

      expect(copied.id, 2);
      expect(copied.itemId, 10);
      expect(copied.name, 'Cheddar');
      expect(copied.basisProdukt, 'Cheese');
      expect(copied.marke, 'BrandX');
      expect(copied.menge, 50);
      expect(copied.einheit, 'g');
      expect(copied.eventType, 'trashed');
      expect(copied.timestamp, DateTime(2023, 1, 1));
    });

    test('KitchenHistory should serialize and deserialize to JSON', () {
      final history = KitchenHistory(
        id: 5,
        itemId: 20,
        name: 'Yogurt',
        basisProdukt: 'Yogurt',
        marke: 'BrandY',
        menge: 150,
        einheit: 'g',
        eventType: 'consumed',
        timestamp: DateTime(2023, 1, 2),
      );

      final json = history.toJson();

      expect(json[KitchenHistoryFields.id], 5);
      expect(json[KitchenHistoryFields.itemId], 20);
      expect(json[KitchenHistoryFields.name], 'Yogurt');
      expect(json[KitchenHistoryFields.basisProdukt], 'Yogurt');
      expect(json[KitchenHistoryFields.marke], 'BrandY');
      expect(json[KitchenHistoryFields.menge], 150.0);
      expect(json[KitchenHistoryFields.einheit], 'g');
      expect(json[KitchenHistoryFields.eventType], 'consumed');
      expect(json[KitchenHistoryFields.timestamp], DateTime(2023, 1, 2).toIso8601String());

      final fromJsonHistory = KitchenHistory.fromJson(json);

      expect(fromJsonHistory.id, 5);
      expect(fromJsonHistory.itemId, 20);
      expect(fromJsonHistory.name, 'Yogurt');
      expect(fromJsonHistory.basisProdukt, 'Yogurt');
      expect(fromJsonHistory.marke, 'BrandY');
      expect(fromJsonHistory.menge, 150.0);
      expect(fromJsonHistory.einheit, 'g');
      expect(fromJsonHistory.eventType, 'consumed');
      expect(fromJsonHistory.timestamp, DateTime(2023, 1, 2));
    });
  });
}
