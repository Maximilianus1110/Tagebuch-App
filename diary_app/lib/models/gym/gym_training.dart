class GymTraining {
  final int? id;
  final int planId;
  final DateTime date;
  final String? note;

  GymTraining({
    this.id,
    required this.planId,
    required this.date,
    this.note,
  });

  GymTraining copyWith({
    int? id,
    int? planId,
    DateTime? date,
    String? note,
  }) {
    return GymTraining(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      note: note ?? this.note,
    );
  }

  Map<String, Object?> toJson() => {
        GymTrainingFields.id: id,
        GymTrainingFields.planId: planId,
        GymTrainingFields.date: date.toIso8601String(),
        if (note != null) GymTrainingFields.note: note,
      };

  static GymTraining fromJson(Map<String, Object?> json) => GymTraining(
        id: json[GymTrainingFields.id] as int?,
        planId: json[GymTrainingFields.planId] as int,
        date: DateTime.parse(json[GymTrainingFields.date] as String),
        note: json[GymTrainingFields.note] as String?,
      );
}

class GymSet {
  final int? id;
  final int trainingId;
  final int equipmentId;
  final int setNumber;
  final int? reps;
  final double? weight;
  final bool isDone;

  GymSet({
    this.id,
    required this.trainingId,
    required this.equipmentId,
    required this.setNumber,
    this.reps,
    this.weight,
    this.isDone = false,
  });

  GymSet copyWith({
    int? id,
    int? trainingId,
    int? equipmentId,
    int? setNumber,
    int? reps,
    double? weight,
    bool? isDone,
  }) {
    return GymSet(
      id: id ?? this.id,
      trainingId: trainingId ?? this.trainingId,
      equipmentId: equipmentId ?? this.equipmentId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, Object?> toJson() => {
        GymSetFields.id: id,
        GymSetFields.trainingId: trainingId,
        GymSetFields.equipmentId: equipmentId,
        GymSetFields.setNumber: setNumber,
        if (reps != null) GymSetFields.reps: reps,
        if (weight != null) GymSetFields.weight: weight,
        GymSetFields.isDone: isDone ? 1 : 0,
      };

  static GymSet fromJson(Map<String, Object?> json) => GymSet(
        id: json[GymSetFields.id] as int?,
        trainingId: json[GymSetFields.trainingId] as int,
        equipmentId: json[GymSetFields.equipmentId] as int,
        setNumber: json[GymSetFields.setNumber] as int,
        reps: json[GymSetFields.reps] as int?,
        weight: (json[GymSetFields.weight] as num?)?.toDouble(),
        isDone: (json[GymSetFields.isDone] as int) == 1,
      );
}

class GymTrainingFields {
  static const String tableName = 'gym_trainings';
  static const String id = '_id';
  static const String planId = 'plan_id';
  static const String date = 'date';
  static const String note = 'note';
}

class GymSetFields {
  static const String tableName = 'gym_sets';
  static const String id = '_id';
  static const String trainingId = 'training_id';
  static const String equipmentId = 'equipment_id';
  static const String setNumber = 'set_number';
  static const String reps = 'reps';
  static const String weight = 'weight';
  static const String isDone = 'is_done';
}
