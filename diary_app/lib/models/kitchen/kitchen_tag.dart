class KitchenTagFields {
  static const String tableName = 'kitchen_tags';
  static const String id = 'id';
  static const String name = 'name';

  static const List<String> values = [
    id,
    name,
  ];
}

class KitchenTag {
  final int? id;
  final String name;

  const KitchenTag({
    this.id,
    required this.name,
  });

  KitchenTag copyWith({
    int? id,
    String? name,
  }) {
    return KitchenTag(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, Object?> toJson() => {
        KitchenTagFields.id: id,
        KitchenTagFields.name: name,
      };

  static KitchenTag fromJson(Map<String, Object?> json) => KitchenTag(
        id: json[KitchenTagFields.id] as int?,
        name: json[KitchenTagFields.name] as String,
      );
}

class KitchenItemTagFields {
  static const String tableName = 'kitchen_item_tags';
  static const String itemId = 'item_id';
  static const String tagId = 'tag_id';
}
