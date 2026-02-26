import 'package:diary_app/models/gym/gym_training.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GymTraining', () {
    test('should be created with required fields', () {
      final training = GymTraining(
        planId: 1,
        date: DateTime(2023, 10, 27),
      );

      expect(training.planId, 1);
      expect(training.date, DateTime(2023, 10, 27));
      expect(training.rating, null);
      expect(training.note, null);
    });

    test('should copyWith all fields', () {
      final training = GymTraining(
        planId: 1,
        date: DateTime(2023, 10, 27),
      );

      final updated = training.copyWith(
        rating: 5,
        note: 'Great workout',
      );

      expect(updated.rating, 5);
      expect(updated.note, 'Great workout');
      expect(updated.planId, 1); // Unchanged
    });

    test('should serialize and deserialize with rating and note', () {
      final training = GymTraining(
        id: 10,
        planId: 1,
        date: DateTime(2023, 10, 27),
        rating: 4,
        note: 'Good',
      );

      final json = training.toJson();
      expect(json[GymTrainingFields.rating], 4);
      expect(json[GymTrainingFields.note], 'Good');

      final deserialized = GymTraining.fromJson(json);
      expect(deserialized.rating, 4);
      expect(deserialized.note, 'Good');
    });

    test('should handle null rating and note in json', () {
      final json = {
        GymTrainingFields.id: 10,
        GymTrainingFields.planId: 1,
        GymTrainingFields.date: DateTime(2023, 10, 27).toIso8601String(),
        // rating and note missing
      };

      final deserialized = GymTraining.fromJson(json);
      expect(deserialized.rating, null);
      expect(deserialized.note, null);
    });
  });
}
