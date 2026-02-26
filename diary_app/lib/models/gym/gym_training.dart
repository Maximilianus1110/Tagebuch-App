class GymTraining {
  final int? id;
  final int planId;
  final DateTime date;
  final String? note;
  final int? rating;

  GymTraining({
    this.id,
    required this.planId,
    required this.date,
    this.note,
    this.rating,
  });

  GymTraining copyWith({
    int? id,
    int? planId,
    DateTime? date,
    String? note,
    int? rating,
  }) {
    return GymTraining(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      date: date ?? this.date,
      note: note ?? this.note,
      rating: rating ?? this.rating,
    );
  }

  Map<String, Object?> toJson() => {
        GymTrainingFields.id: id,
        GymTrainingFields.planId: planId,
        GymTrainingFields.date: date.toIso8601String(),
        if (note != null) GymTrainingFields.note: note,
        if (rating != null) GymTrainingFields.rating: rating,
      };

  static GymTraining fromJson(Map<String, Object?> json) => GymTraining(
        id: json[GymTrainingFields.id] as int?,
        planId: json[GymTrainingFields.planId] as int,
        date: DateTime.parse(json[GymTrainingFields.date] as String),
        note: json[GymTrainingFields.note] as String?,
        rating: json[GymTrainingFields.rating] as int?,
      );
}

class GymSet {
  final int? id;
  final int trainingId;
  final int exerciseId;
  final int setNumber;
  final int? reps;
  final double? weight;
  final bool isDone;
  final int? durationSeconds;
  final bool isWarmup;

  GymSet({
    this.id,
    required this.trainingId,
    required this.exerciseId,
    required this.setNumber,
    this.reps,
    this.weight,
    this.isDone = false,
    this.durationSeconds,
    this.isWarmup = false,
  });

  GymSet copyWith({
    int? id,
    int? trainingId,
    int? exerciseId,
    int? setNumber,
    int? reps,
    double? weight,
    bool? isDone,
    int? durationSeconds,
    bool? isWarmup,
  }) {
    return GymSet(
      id: id ?? this.id,
      trainingId: trainingId ?? this.trainingId,
      exerciseId: exerciseId ?? this.exerciseId,
      setNumber: setNumber ?? this.setNumber,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      isDone: isDone ?? this.isDone,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isWarmup: isWarmup ?? this.isWarmup,
    );
  }

  Map<String, Object?> toJson() => {
        GymSetFields.id: id,
        GymSetFields.trainingId: trainingId,
        GymSetFields.exerciseId: exerciseId,
        GymSetFields.setNumber: setNumber,
        if (reps != null) GymSetFields.reps: reps,
        if (weight != null) GymSetFields.weight: weight,
        GymSetFields.isDone: isDone ? 1 : 0,
        if (durationSeconds != null) GymSetFields.durationSeconds: durationSeconds,
        GymSetFields.isWarmup: isWarmup ? 1 : 0,
      };

  static GymSet fromJson(Map<String, Object?> json) => GymSet(
        id: json[GymSetFields.id] as int?,
        trainingId: json[GymSetFields.trainingId] as int,
        exerciseId: json[GymSetFields.exerciseId] as int,
        setNumber: json[GymSetFields.setNumber] as int,
        reps: json[GymSetFields.reps] as int?,
        weight: (json[GymSetFields.weight] as num?)?.toDouble(),
        isDone: (json[GymSetFields.isDone] as int) == 1,
        durationSeconds: json[GymSetFields.durationSeconds] as int?,
        isWarmup: (json[GymSetFields.isWarmup] as int?) == 1,
      );
}

class GymTrainingFields {
  static const String tableName = 'gym_trainings';
  static const String id = '_id';
  static const String planId = 'plan_id';
  static const String date = 'date';
  static const String note = 'note';
  static const String rating = 'rating';
}

class GymSetFields {
  static const String tableName = 'gym_sets';
  static const String id = '_id';
  static const String trainingId = 'training_id';
  static const String exerciseId = 'equipment_id'; // Keep old column name
  static const String setNumber = 'set_number';
  static const String reps = 'reps';
  static const String weight = 'weight';
  static const String isDone = 'is_done';
  static const String durationSeconds = 'duration_seconds';
  static const String isWarmup = 'is_warmup';
}
