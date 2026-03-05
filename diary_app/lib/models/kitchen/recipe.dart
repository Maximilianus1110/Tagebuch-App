class RecipeFields {
  static const String tableName = 'recipes';

  static const String id = '_id';
  static const String name = 'name';
  static const String description = 'description';
  static const String prepTimeMinutes = 'prep_time_minutes';
  static const String createdAt = 'created_at';

  static const List<String> values = [
    id, name, description, prepTimeMinutes, createdAt
  ];
}

class Recipe {
  final int? id;
  final String name;
  final String? description;
  final int? prepTimeMinutes;
  final DateTime createdAt;

  const Recipe({
    this.id,
    required this.name,
    this.description,
    this.prepTimeMinutes,
    required this.createdAt,
  });

  Recipe copyWith({
    int? id,
    String? name,
    String? description,
    int? prepTimeMinutes,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    RecipeFields.id: id,
    RecipeFields.name: name,
    RecipeFields.description: description,
    RecipeFields.prepTimeMinutes: prepTimeMinutes,
    RecipeFields.createdAt: createdAt.toIso8601String(),
  };

  static Recipe fromJson(Map<String, dynamic> json) => Recipe(
    id: json[RecipeFields.id] as int?,
    name: json[RecipeFields.name] as String,
    description: json[RecipeFields.description] as String?,
    prepTimeMinutes: json[RecipeFields.prepTimeMinutes] as int?,
    createdAt: DateTime.parse(json[RecipeFields.createdAt] as String),
  );
}
