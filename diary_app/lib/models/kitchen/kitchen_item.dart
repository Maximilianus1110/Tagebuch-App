class KitchenItemFields {
  static const String tableName = 'kitchen_items';
  static const String id = 'id';
  static const String name = 'name';
  static const String basisProdukt = 'basis_produkt';
  static const String marke = 'marke';
  static const String menge = 'menge';
  static const String einheit = 'einheit'; // 'g', 'ml', 'Stueck'
  static const String haltbarBis = 'haltbar_bis';
  static const String hinzugefuegt = 'hinzugefuegt';

  static const List<String> values = [
    id,
    name,
    basisProdukt,
    marke,
    menge,
    einheit,
    haltbarBis,
    hinzugefuegt,
  ];
}

class KitchenItem {
  final int? id;
  final String name;
  final String basisProdukt;
  final String? marke;
  final double menge;
  final String einheit; // Should be 'g', 'ml', 'Stueck' in DB
  final DateTime? haltbarBis;
  final DateTime hinzugefuegt;

  const KitchenItem({
    this.id,
    required this.name,
    required this.basisProdukt,
    this.marke,
    required this.menge,
    required this.einheit,
    this.haltbarBis,
    required this.hinzugefuegt,
  });

  KitchenItem copyWith({
    int? id,
    String? name,
    String? basisProdukt,
    String? marke,
    double? menge,
    String? einheit,
    DateTime? haltbarBis,
    DateTime? hinzugefuegt,
  }) {
    return KitchenItem(
      id: id ?? this.id,
      name: name ?? this.name,
      basisProdukt: basisProdukt ?? this.basisProdukt,
      marke: marke ?? this.marke,
      menge: menge ?? this.menge,
      einheit: einheit ?? this.einheit,
      haltbarBis: haltbarBis ?? this.haltbarBis,
      hinzugefuegt: hinzugefuegt ?? this.hinzugefuegt,
    );
  }

  Map<String, Object?> toJson() => {
        KitchenItemFields.id: id,
        KitchenItemFields.name: name,
        KitchenItemFields.basisProdukt: basisProdukt,
        KitchenItemFields.marke: marke,
        KitchenItemFields.menge: menge,
        KitchenItemFields.einheit: einheit,
        KitchenItemFields.haltbarBis: haltbarBis?.toIso8601String(),
        KitchenItemFields.hinzugefuegt: hinzugefuegt.toIso8601String(),
      };

  static KitchenItem fromJson(Map<String, Object?> json) => KitchenItem(
        id: json[KitchenItemFields.id] as int?,
        name: json[KitchenItemFields.name] as String,
        basisProdukt: json[KitchenItemFields.basisProdukt] as String,
        marke: json[KitchenItemFields.marke] as String?,
        menge: (json[KitchenItemFields.menge] as num).toDouble(),
        einheit: json[KitchenItemFields.einheit] as String,
        haltbarBis: json[KitchenItemFields.haltbarBis] != null
            ? DateTime.parse(json[KitchenItemFields.haltbarBis] as String)
            : null,
        hinzugefuegt: DateTime.parse(json[KitchenItemFields.hinzugefuegt] as String),
      );
}
