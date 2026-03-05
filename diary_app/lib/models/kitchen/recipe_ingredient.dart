class RecipeIngredientFields {
  static const String tableName = 'recipe_ingredients';

  static const String id = '_id';
  static const String recipeId = 'recipe_id';
  static const String basisProdukt = 'basis_produkt';
  static const String menge = 'menge';
  static const String einheit = 'einheit';
  static const String sortOrder = 'sort_order';

  static const List<String> values = [
    id, recipeId, basisProdukt, menge, einheit, sortOrder
  ];
}

class RecipeIngredient {
  final int? id;
  final int recipeId;
  final String basisProdukt; // Can act as tag as well or broad category
  final double menge;
  final String einheit;
  final int sortOrder;

  const RecipeIngredient({
    this.id,
    required this.recipeId,
    required this.basisProdukt,
    required this.menge,
    required this.einheit,
    required this.sortOrder,
  });

  RecipeIngredient copyWith({
    int? id,
    int? recipeId,
    String? basisProdukt,
    double? menge,
    String? einheit,
    int? sortOrder,
  }) {
    return RecipeIngredient(
      id: id ?? this.id,
      recipeId: recipeId ?? this.recipeId,
      basisProdukt: basisProdukt ?? this.basisProdukt,
      menge: menge ?? this.menge,
      einheit: einheit ?? this.einheit,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
    RecipeIngredientFields.id: id,
    RecipeIngredientFields.recipeId: recipeId,
    RecipeIngredientFields.basisProdukt: basisProdukt,
    RecipeIngredientFields.menge: menge,
    RecipeIngredientFields.einheit: einheit,
    RecipeIngredientFields.sortOrder: sortOrder,
  };

  static RecipeIngredient fromJson(Map<String, dynamic> json) => RecipeIngredient(
    id: json[RecipeIngredientFields.id] as int?,
    recipeId: json[RecipeIngredientFields.recipeId] as int,
    basisProdukt: json[RecipeIngredientFields.basisProdukt] as String,
    menge: (json[RecipeIngredientFields.menge] as num).toDouble(),
    einheit: json[RecipeIngredientFields.einheit] as String,
    sortOrder: json[RecipeIngredientFields.sortOrder] as int,
  );
}
