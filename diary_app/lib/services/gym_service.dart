import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/gym/gym_equipment.dart';
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

  // --- Equipment ---
  Future<List<GymEquipment>> getAllEquipment() async {
    return await _dbHelper.getAllEquipment();
  }

  Future<GymEquipment> addEquipment(String name) async {
    final equipment = GymEquipment(name: name);
    return await _dbHelper.createEquipment(equipment);
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

  /// Returns a map of "${equipmentId}_${setNumber}" -> GymSet (last used values)
  Future<Map<String, GymSet>> getLastTrainingSets(int planId) async {
    final lastTraining = await _dbHelper.getLastTraining(planId);
    if (lastTraining == null || lastTraining.id == null) {
      return {};
    }

    final sets = await _dbHelper.getSetsForTraining(lastTraining.id!);

    final Map<String, GymSet> resultMap = {};
    for (var s in sets) {
      resultMap['${s.equipmentId}_${s.setNumber}'] = s;
    }
    return resultMap;
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
