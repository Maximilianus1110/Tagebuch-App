import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/models/kitchen/kitchen_tag.dart';

void main() {
  group('KitchenTag', () {
    test('KitchenTag should be created with required fields', () {
      final tag = KitchenTag(name: 'Vegetarisch');

      expect(tag.id, isNull);
      expect(tag.name, 'Vegetarisch');
    });

    test('KitchenTag should copyWith fields', () {
      final tag = KitchenTag(id: 1, name: 'Vegan');
      final copied = tag.copyWith(name: 'Glutenfrei');

      expect(copied.id, 1);
      expect(copied.name, 'Glutenfrei');
    });

    test('KitchenTag should serialize and deserialize to JSON', () {
      final tag = KitchenTag(id: 2, name: 'Bio');
      final json = tag.toJson();

      expect(json[KitchenTagFields.id], 2);
      expect(json[KitchenTagFields.name], 'Bio');

      final fromJsonTag = KitchenTag.fromJson(json);

      expect(fromJsonTag.id, 2);
      expect(fromJsonTag.name, 'Bio');
    });
  });
}
