import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/services/gym_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('GymService', () {
    late DatabaseHelper dbHelper;
    late GymService gymService;

    setUp(() async {
      final dbPath = await getDatabasesPath();
      final path = '$dbPath/diary.db';
      await databaseFactory.deleteDatabase(path);

      dbHelper = DatabaseHelper.test();
      DatabaseHelper.instance = dbHelper;
      gymService = GymService();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('addExercise and getAllExercises', () async {
      final created = await gymService.addExercise('Push Up', 'Bodyweight');
      expect(created.id, isNotNull);
      expect(created.name, 'Push Up');

      final exercises = await gymService.getAllExercises();
      expect(exercises.length, 1);
      expect(exercises.first.name, 'Push Up');
    });

    test('updateExercise', () async {
      final exercise = await gymService.addExercise('Squat');
      final updated = exercise.copyWith(description: 'Legs');

      await gymService.updateExercise(updated);
      final exercises = await gymService.getAllExercises();

      expect(exercises.first.description, 'Legs');
    });

    test('createPlan and getExercisesForPlan', () async {
      final exercise = await gymService.addExercise('Bench Press');

      final plan = GymPlan(name: 'Chest Day');
      final planExercise = GymPlanExercise(
        planId: 0, // Ignored by createPlan
        exerciseId: exercise.id!,
        setCount: 3,
        sortOrder: 1,
      );

      final createdPlan = await gymService.createPlan(plan, [planExercise]);
      expect(createdPlan.id, isNotNull);

      final fetchedExercises = await gymService.getExercisesForPlan(createdPlan.id!);
      expect(fetchedExercises.length, 1);
      expect(fetchedExercises.first.exerciseId, exercise.id);
      expect(fetchedExercises.first.setCount, 3);
    });

    test('saveTraining and history calculation', () async {
      final exercise = await gymService.addExercise('Deadlift');
      final plan = await gymService.createPlan(
        GymPlan(name: 'Back Day'),
        [GymPlanExercise(planId: 0, exerciseId: exercise.id!, setCount: 1, sortOrder: 1)]
      );

      final training = GymTraining(
        planId: plan.id!,
        date: DateTime.now(),
        rating: 5,
      );

      final sets = [
        GymSet(
          trainingId: 0,
          exerciseId: exercise.id!,
          setNumber: 1,
          reps: 10,
          weight: 100,
          isDone: true,
          isWarmup: false,
        )
      ];

      final savedTraining = await gymService.saveTraining(training, sets);
      expect(savedTraining.id, isNotNull);

      final history = await gymService.getHistory();
      expect(history.length, 1);
      expect(history.first.planName, 'Back Day');
      expect(history.first.totalVolume, 1000.0); // 10 * 100
      expect(history.first.volumeDelta, isNull);
    });

    test('history calculates volume delta', () async {
      final exercise = await gymService.addExercise('Curl');
      final plan = await gymService.createPlan(
        GymPlan(name: 'Arm Day'),
        [GymPlanExercise(planId: 0, exerciseId: exercise.id!, setCount: 1, sortOrder: 1)]
      );

      // Training 1 (Older)
      await gymService.saveTraining(
        GymTraining(planId: plan.id!, date: DateTime.now().subtract(Duration(days: 2))),
        [GymSet(trainingId: 0, exerciseId: exercise.id!, setNumber: 1, reps: 10, weight: 10, isDone: true, isWarmup: false)]
      );

      // Training 2 (Newer)
      await gymService.saveTraining(
        GymTraining(planId: plan.id!, date: DateTime.now()),
        [GymSet(trainingId: 0, exerciseId: exercise.id!, setNumber: 1, reps: 10, weight: 15, isDone: true, isWarmup: false)]
      );

      final history = await gymService.getHistory();
      expect(history.length, 2);

      // The first item should be the newer one
      expect(history[0].totalVolume, 150.0); // 10 * 15
      expect(history[0].volumeDelta, 50.0); // 150 - 100
    });
  });
}
