class GymExercise {
  final int? id;
  final String name;
  final String? description;

  GymExercise({
    this.id,
    required this.name,
    this.description,
  });

  GymExercise copyWith({
    int? id,
    String? name,
    String? description,
  }) {
    return GymExercise(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  Map<String, Object?> toJson() => {
        GymExerciseFields.id: id,
        GymExerciseFields.name: name,
        GymExerciseFields.description: description,
      };

  static GymExercise fromJson(Map<String, Object?> json) => GymExercise(
        id: json[GymExerciseFields.id] as int?,
        name: json[GymExerciseFields.name] as String,
        description: json[GymExerciseFields.description] as String?,
      );
}

class GymExerciseFields {
  static const String tableName = 'gym_equipment'; // Keep table name for migration ease
  static const String id = '_id';
  static const String name = 'name';
  static const String description = 'description';
}
