import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_training.dart';

class TrainingHistoryItem {
  final GymTraining training;
  final String planName;
  final double totalVolume;
  final double? volumeDelta;

  TrainingHistoryItem({
    required this.training,
    required this.planName,
    required this.totalVolume,
    this.volumeDelta,
  });
}

class GymService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // --- Exercises ---
  Future<List<GymExercise>> getAllExercises() async {
    return await _dbHelper.getAllExercises();
  }

  Future<GymExercise> addExercise(String name, [String? description]) async {
    final exercise = GymExercise(name: name, description: description);
    return await _dbHelper.createExercise(exercise);
  }

  Future<int> updateExercise(GymExercise exercise) async {
    return await _dbHelper.updateExercise(exercise);
  }

  // --- Plans ---
  Future<List<GymPlan>> getAllPlans() async {
    return await _dbHelper.getAllPlans();
  }

  Future<GymPlan> createPlan(GymPlan plan, List<GymPlanExercise> exercises) async {
    return await _dbHelper.createPlan(plan, exercises);
  }

  Future<List<GymPlanExercise>> getExercisesForPlan(int planId) async {
    return await _dbHelper.getExercisesForPlan(planId);
  }

  // --- Training ---
  Future<GymTraining> saveTraining(GymTraining training, List<GymSet> sets) async {
    return await _dbHelper.createTraining(training, sets);
  }

  Future<List<GymSet>> getSetsForTraining(int trainingId) async {
    return await _dbHelper.getSetsForTraining(trainingId);
  }

  /// Returns a map of "${exerciseId}_${setNumber}" -> GymSet (last used values)
  Future<Map<String, GymSet>> getLastTrainingSets(int planId, {DateTime? beforeDate}) async {
    final lastTraining = await _dbHelper.getLastTraining(planId, beforeDate: beforeDate);
    if (lastTraining == null || lastTraining.id == null) {
      return {};
    }

    final sets = await _dbHelper.getSetsForTraining(lastTraining.id!);

    final Map<String, GymSet> resultMap = {};
    for (var s in sets) {
      resultMap['${s.exerciseId}_${s.setNumber}'] = s;
    }
    return resultMap;
  }

  Future<GymSet?> getLatestSetForExercise(int exerciseId) async {
    return await _dbHelper.getLatestSetForExercise(exerciseId);
  }

  Future<List<TrainingHistoryItem>> getHistory() async {
    final db = await _dbHelper.database;

    // 1. Fetch Plans for names
    final plans = await _dbHelper.getAllPlans();
    final planMap = {for (var p in plans) p.id: p.name};

    // 2. Fetch all trainings
    final trainingMaps = await db.query(
      GymTrainingFields.tableName,
      orderBy: '${GymTrainingFields.date} DESC',
    );
    final trainings = trainingMaps.map((json) => GymTraining.fromJson(json)).toList();

    if (trainings.isEmpty) return [];

    // 3. Fetch all sets
    final setMaps = await db.query(GymSetFields.tableName);
    final allSets = setMaps.map((json) => GymSet.fromJson(json)).toList();

    // Group sets by trainingId
    final Map<int, List<GymSet>> setsByTraining = {};
    for (var s in allSets) {
      setsByTraining.putIfAbsent(s.trainingId, () => []).add(s);
    }

    // Helper to calc volume
    double getVolume(int tId) {
      final sets = setsByTraining[tId] ?? [];
      double vol = 0;
      for (var s in sets) {
        if (s.reps != null && s.weight != null) {
          vol += s.reps! * s.weight!;
        }
      }
      return vol;
    }

    List<TrainingHistoryItem> history = [];

    for (var i = 0; i < trainings.length; i++) {
      final t = trainings[i];
      final planName = planMap[t.planId] ?? 'Unbekannter Plan'; // 'Unknown Plan' in German

      final currentVol = getVolume(t.id!);

      // Find previous training for SAME plan
      double? prevVol;
      for (var j = i + 1; j < trainings.length; j++) {
        if (trainings[j].planId == t.planId) {
          prevVol = getVolume(trainings[j].id!);
          break;
        }
      }

      double? delta;
      if (prevVol != null) {
        delta = currentVol - prevVol;
      }

      history.add(TrainingHistoryItem(
        training: t,
        planName: planName,
        totalVolume: currentVol,
        volumeDelta: delta,
      ));
    }

    return history;
  }
}
