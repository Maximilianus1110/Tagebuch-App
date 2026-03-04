class KitchenHistoryFields {
  static const String tableName = 'kitchen_history';
  static const String id = 'id';
  static const String itemId = 'item_id';
  static const String name = 'name';
  static const String basisProdukt = 'basis_produkt';
  static const String marke = 'marke';
  static const String menge = 'menge';
  static const String einheit = 'einheit';
  static const String eventType = 'event_type'; // 'consumed' or 'trashed'
  static const String timestamp = 'timestamp';

  static const List<String> values = [
    id,
    itemId,
    name,
    basisProdukt,
    marke,
    menge,
    einheit,
    eventType,
    timestamp,
  ];
}

class KitchenHistory {
  final int? id;
  final int? itemId; // Optional, might be null if the original item was fully deleted
  final String name;
  final String basisProdukt;
  final String? marke;
  final double menge;
  final String einheit;
  final String eventType;
  final DateTime timestamp;

  const KitchenHistory({
    this.id,
    this.itemId,
    required this.name,
    required this.basisProdukt,
    this.marke,
    required this.menge,
    required this.einheit,
    required this.eventType,
    required this.timestamp,
  });

  KitchenHistory copyWith({
    int? id,
    int? itemId,
    String? name,
    String? basisProdukt,
    String? marke,
    double? menge,
    String? einheit,
    String? eventType,
    DateTime? timestamp,
  }) {
    return KitchenHistory(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      basisProdukt: basisProdukt ?? this.basisProdukt,
      marke: marke ?? this.marke,
      menge: menge ?? this.menge,
      einheit: einheit ?? this.einheit,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, Object?> toJson() => {
        KitchenHistoryFields.id: id,
        KitchenHistoryFields.itemId: itemId,
        KitchenHistoryFields.name: name,
        KitchenHistoryFields.basisProdukt: basisProdukt,
        KitchenHistoryFields.marke: marke,
        KitchenHistoryFields.menge: menge,
        KitchenHistoryFields.einheit: einheit,
        KitchenHistoryFields.eventType: eventType,
        KitchenHistoryFields.timestamp: timestamp.toIso8601String(),
      };

  static KitchenHistory fromJson(Map<String, Object?> json) => KitchenHistory(
        id: json[KitchenHistoryFields.id] as int?,
        itemId: json[KitchenHistoryFields.itemId] as int?,
        name: json[KitchenHistoryFields.name] as String,
        basisProdukt: json[KitchenHistoryFields.basisProdukt] as String,
        marke: json[KitchenHistoryFields.marke] as String?,
        menge: (json[KitchenHistoryFields.menge] as num).toDouble(),
        einheit: json[KitchenHistoryFields.einheit] as String,
        eventType: json[KitchenHistoryFields.eventType] as String,
        timestamp: DateTime.parse(json[KitchenHistoryFields.timestamp] as String),
      );
}
