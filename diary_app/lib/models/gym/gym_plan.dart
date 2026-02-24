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
  final int equipmentId;
  final int setCount;
  final int sortOrder;

  GymPlanExercise({
    this.id,
    required this.planId,
    required this.equipmentId,
    required this.setCount,
    required this.sortOrder,
  });

  GymPlanExercise copyWith({
    int? id,
    int? planId,
    int? equipmentId,
    int? setCount,
    int? sortOrder,
  }) {
    return GymPlanExercise(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      equipmentId: equipmentId ?? this.equipmentId,
      setCount: setCount ?? this.setCount,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toJson() => {
        GymPlanExerciseFields.id: id,
        GymPlanExerciseFields.planId: planId,
        GymPlanExerciseFields.equipmentId: equipmentId,
        GymPlanExerciseFields.setCount: setCount,
        GymPlanExerciseFields.sortOrder: sortOrder,
      };

  static GymPlanExercise fromJson(Map<String, Object?> json) => GymPlanExercise(
        id: json[GymPlanExerciseFields.id] as int?,
        planId: json[GymPlanExerciseFields.planId] as int,
        equipmentId: json[GymPlanExerciseFields.equipmentId] as int,
        setCount: json[GymPlanExerciseFields.setCount] as int,
        sortOrder: json[GymPlanExerciseFields.sortOrder] as int,
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
  static const String equipmentId = 'equipment_id';
  static const String setCount = 'set_count';
  static const String sortOrder = 'sort_order';
}
