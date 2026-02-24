class GymPlan {
  final int? id;
  final String name;

  GymPlan({
    this.id,
    required this.name,
  });

  GymPlan copyWith({
    int? id,
    String? name,
  }) {
    return GymPlan(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  Map<String, Object?> toJson() => {
        GymPlanFields.id: id,
        GymPlanFields.name: name,
      };

  static GymPlan fromJson(Map<String, Object?> json) => GymPlan(
        id: json[GymPlanFields.id] as int?,
        name: json[GymPlanFields.name] as String,
      );
}

class GymPlanExercise {
  final int? id;
  final int planId;
  final int exerciseId; // Was equipmentId
  final int setCount;
  final int sortOrder;
  final String? targetReps;
  final bool isWarmup;

  GymPlanExercise({
    this.id,
    required this.planId,
    required this.exerciseId,
    required this.setCount,
    required this.sortOrder,
    this.targetReps,
    this.isWarmup = false,
  });

  GymPlanExercise copyWith({
    int? id,
    int? planId,
    int? exerciseId,
    int? setCount,
    int? sortOrder,
    String? targetReps,
    bool? isWarmup,
  }) {
    return GymPlanExercise(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      exerciseId: exerciseId ?? this.exerciseId,
      setCount: setCount ?? this.setCount,
      sortOrder: sortOrder ?? this.sortOrder,
      targetReps: targetReps ?? this.targetReps,
      isWarmup: isWarmup ?? this.isWarmup,
    );
  }

  Map<String, Object?> toJson() => {
        GymPlanExerciseFields.id: id,
        GymPlanExerciseFields.planId: planId,
        GymPlanExerciseFields.exerciseId: exerciseId,
        GymPlanExerciseFields.setCount: setCount,
        GymPlanExerciseFields.sortOrder: sortOrder,
        if (targetReps != null) GymPlanExerciseFields.targetReps: targetReps,
        GymPlanExerciseFields.isWarmup: isWarmup ? 1 : 0,
      };

  static GymPlanExercise fromJson(Map<String, Object?> json) => GymPlanExercise(
        id: json[GymPlanExerciseFields.id] as int?,
        planId: json[GymPlanExerciseFields.planId] as int,
        exerciseId: json[GymPlanExerciseFields.exerciseId] as int,
        setCount: json[GymPlanExerciseFields.setCount] as int,
        sortOrder: json[GymPlanExerciseFields.sortOrder] as int,
        targetReps: json[GymPlanExerciseFields.targetReps] as String?,
        isWarmup: (json[GymPlanExerciseFields.isWarmup] as int?) == 1,
      );
}

class GymPlanFields {
  static const String tableName = 'gym_plans';
  static const String id = '_id';
  static const String name = 'name';
}

class GymPlanExerciseFields {
  static const String tableName = 'gym_plan_exercises';
  static const String id = '_id';
  static const String planId = 'plan_id';
  static const String exerciseId = 'equipment_id'; // Keep old column name
  static const String setCount = 'set_count';
  static const String sortOrder = 'sort_order';
  static const String targetReps = 'target_reps';
  static const String isWarmup = 'is_warmup';
}
