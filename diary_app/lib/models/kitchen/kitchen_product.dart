class KitchenProductFields {
  static const String tableName = 'kitchen_products';
  static const String id = 'id';
  static const String name = 'name';
  static const String basisProdukt = 'basis_produkt';
  static const String marke = 'marke';
  static const String einheit = 'einheit'; // 'g', 'ml', 'Stueck'
  static const String defaultHaltbarkeitTage = 'default_haltbarkeit_tage';

  static const List<String> values = [
    id,
    name,
    basisProdukt,
    marke,
    einheit,
    defaultHaltbarkeitTage,
  ];
}

class KitchenProduct {
  final int? id;
  final String name;
  final String basisProdukt;
  final String? marke;
  final String einheit; // Should be 'g', 'ml', 'Stueck' in DB
  final int? defaultHaltbarkeitTage;

  const KitchenProduct({
    this.id,
    required this.name,
    required this.basisProdukt,
    this.marke,
    required this.einheit,
    this.defaultHaltbarkeitTage,
  });

  KitchenProduct copyWith({
    int? id,
    String? name,
    String? basisProdukt,
    String? marke,
    String? einheit,
    int? defaultHaltbarkeitTage,
  }) {
    return KitchenProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      basisProdukt: basisProdukt ?? this.basisProdukt,
      marke: marke ?? this.marke,
      einheit: einheit ?? this.einheit,
      defaultHaltbarkeitTage: defaultHaltbarkeitTage ?? this.defaultHaltbarkeitTage,
    );
  }

  Map<String, Object?> toJson() => {
        KitchenProductFields.id: id,
        KitchenProductFields.name: name,
        KitchenProductFields.basisProdukt: basisProdukt,
        KitchenProductFields.marke: marke,
        KitchenProductFields.einheit: einheit,
        KitchenProductFields.defaultHaltbarkeitTage: defaultHaltbarkeitTage,
      };

  static KitchenProduct fromJson(Map<String, Object?> json) => KitchenProduct(
        id: json[KitchenProductFields.id] as int?,
        name: json[KitchenProductFields.name] as String,
        basisProdukt: json[KitchenProductFields.basisProdukt] as String,
        marke: json[KitchenProductFields.marke] as String?,
        einheit: json[KitchenProductFields.einheit] as String,
        defaultHaltbarkeitTage: json[KitchenProductFields.defaultHaltbarkeitTage] as int?,
      );
}
