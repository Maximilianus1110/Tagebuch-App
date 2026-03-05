import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/models/gym/gym_plan.dart';

void main() {
  group('GymPlan', () {
    test('GymPlan should be created with required fields', () {
      final plan = GymPlan(name: 'Push Day');

      expect(plan.id, isNull);
      expect(plan.name, 'Push Day');
    });

    test('GymPlan should copyWith fields', () {
      final plan = GymPlan(id: 1, name: 'Pull Day');
      final copied = plan.copyWith(name: 'Leg Day');

      expect(copied.id, 1);
      expect(copied.name, 'Leg Day');
    });

    test('GymPlan should serialize and deserialize to JSON', () {
      final plan = GymPlan(id: 2, name: 'Core');
      final json = plan.toJson();

      expect(json[GymPlanFields.id], 2);
      expect(json[GymPlanFields.name], 'Core');

      final fromJsonPlan = GymPlan.fromJson(json);

      expect(fromJsonPlan.id, 2);
      expect(fromJsonPlan.name, 'Core');
    });
  });

  group('GymPlanExercise', () {
    test('GymPlanExercise should be created with required fields', () {
      final exercise = GymPlanExercise(
        planId: 1,
        exerciseId: 2,
        setCount: 3,
        sortOrder: 1,
      );

      expect(exercise.id, isNull);
      expect(exercise.planId, 1);
      expect(exercise.exerciseId, 2);
      expect(exercise.setCount, 3);
      expect(exercise.sortOrder, 1);
      expect(exercise.targetReps, isNull);
      expect(exercise.isWarmup, isFalse);
    });

    test('GymPlanExercise should copyWith fields', () {
      final exercise = GymPlanExercise(
        id: 1,
        planId: 1,
        exerciseId: 2,
        setCount: 3,
        sortOrder: 1,
        targetReps: '8-12',
        isWarmup: false,
      );

      final copied = exercise.copyWith(setCount: 4, isWarmup: true);

      expect(copied.id, 1);
      expect(copied.planId, 1);
      expect(copied.exerciseId, 2);
      expect(copied.setCount, 4);
      expect(copied.sortOrder, 1);
      expect(copied.targetReps, '8-12');
      expect(copied.isWarmup, isTrue);
    });

    test('GymPlanExercise should serialize and deserialize to JSON', () {
      final exercise = GymPlanExercise(
        id: 1,
        planId: 10,
        exerciseId: 20,
        setCount: 5,
        sortOrder: 2,
        targetReps: '5',
        isWarmup: true,
      );

      final json = exercise.toJson();

      expect(json[GymPlanExerciseFields.id], 1);
      expect(json[GymPlanExerciseFields.planId], 10);
      expect(json[GymPlanExerciseFields.exerciseId], 20);
      expect(json[GymPlanExerciseFields.setCount], 5);
      expect(json[GymPlanExerciseFields.sortOrder], 2);
      expect(json[GymPlanExerciseFields.targetReps], '5');
      expect(json[GymPlanExerciseFields.isWarmup], 1);

      final fromJsonExercise = GymPlanExercise.fromJson(json);

      expect(fromJsonExercise.id, 1);
      expect(fromJsonExercise.planId, 10);
      expect(fromJsonExercise.exerciseId, 20);
      expect(fromJsonExercise.setCount, 5);
      expect(fromJsonExercise.sortOrder, 2);
      expect(fromJsonExercise.targetReps, '5');
      expect(fromJsonExercise.isWarmup, isTrue);
    });

    test('GymPlanExercise should omit targetReps if null in toJson', () {
      final exercise = GymPlanExercise(
        planId: 1,
        exerciseId: 2,
        setCount: 3,
        sortOrder: 1,
      );

      final json = exercise.toJson();
      expect(json.containsKey(GymPlanExerciseFields.targetReps), isFalse);
    });
  });
}
