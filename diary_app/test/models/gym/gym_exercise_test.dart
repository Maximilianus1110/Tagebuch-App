import 'package:flutter_test/flutter_test.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';

void main() {
  group('GymExercise', () {
    test('GymExercise should be created with required fields', () {
      final exercise = GymExercise(name: 'Bench Press');

      expect(exercise.id, isNull);
      expect(exercise.name, 'Bench Press');
      expect(exercise.description, isNull);
    });

    test('GymExercise should copyWith fields', () {
      final exercise = GymExercise(id: 1, name: 'Squat', description: 'Leg day');
      final copied = exercise.copyWith(name: 'Front Squat');

      expect(copied.id, 1);
      expect(copied.name, 'Front Squat');
      expect(copied.description, 'Leg day');
    });

    test('GymExercise should serialize and deserialize to JSON', () {
      final exercise = GymExercise(id: 2, name: 'Deadlift', description: 'Heavy lift');
      final json = exercise.toJson();

      expect(json[GymExerciseFields.id], 2);
      expect(json[GymExerciseFields.name], 'Deadlift');
      expect(json[GymExerciseFields.description], 'Heavy lift');

      final fromJsonExercise = GymExercise.fromJson(json);

      expect(fromJsonExercise.id, 2);
      expect(fromJsonExercise.name, 'Deadlift');
      expect(fromJsonExercise.description, 'Heavy lift');
    });

    test('GymExercise should handle null description in JSON', () {
      final exercise = GymExercise(id: 3, name: 'Pull Up');
      final json = exercise.toJson();

      expect(json[GymExerciseFields.description], isNull);

      final fromJsonExercise = GymExercise.fromJson(json);
      expect(fromJsonExercise.description, isNull);
    });
  });
}
