class GymEquipment {
  final int? id;
  final String name;

  GymEquipment({
    this.id,
    required this.name,
  });

  GymEquipment copyWith({
    int? id,
    String? name,
  }) {
    return GymEquipment(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, Object?> toJson() => {
        GymEquipmentFields.id: id,
        GymEquipmentFields.name: name,
      };

  static GymEquipment fromJson(Map<String, Object?> json) => GymEquipment(
        id: json[GymEquipmentFields.id] as int?,
        name: json[GymEquipmentFields.name] as String,
      );
}

class GymEquipmentFields {
  static const String tableName = 'gym_equipment';
  static const String id = '_id';
  static const String name = 'name';
}
