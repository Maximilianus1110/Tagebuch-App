import 'dart:convert';
import 'dart:io';
import 'package:archive/archive_io.dart';

void main() async {
  // Create dummy data
  final diaryData = jsonEncode({
    'entries': [
      {'id': 1, 'date': '2023-10-27T10:00:00.000', 'content': 'Test Diary Entry 1', 'title': 'Test 1', 'deletedAt': null},
      {'id': 2, 'date': '2023-10-28T10:00:00.000', 'content': 'Test Diary Entry 2', 'title': 'Test 2', 'deletedAt': null},
    ]
  });

  final gymData = jsonEncode({
    'exercises': [
      {'id': 1, 'name': 'Bench Press', 'description': 'Chest exercise'},
      {'id': 2, 'name': 'Squat', 'description': 'Leg exercise'},
    ],
    'plans': [
      {'id': 1, 'name': 'Push Day'},
    ],
    'planExercises': [
      {'id': 1, 'planId': 1, 'exerciseId': 1, 'setCount': 3, 'sortOrder': 0, 'targetReps': '8-10', 'isWarmup': 0},
    ],
    'trainings': [
      {'id': 1, 'planId': 1, 'date': '2023-10-27T10:00:00.000', 'note': 'Good workout', 'durationSeconds': 3600, 'rating': 4},
    ],
    'sets': [
      {'id': 1, 'trainingId': 1, 'exerciseId': 1, 'setNumber': 1, 'reps': 10, 'weight': 60.0, 'isDone': 1, 'durationSeconds': 60, 'isWarmup': 0},
    ]
  });

  final kitchenData = jsonEncode({
    'items': [
      {'id': 1, 'name': 'Milk', 'basisProdukt': 'Milk', 'marke': 'Brand A', 'menge': 1.0, 'einheit': 'l', 'haltbarBis': '2023-11-01T00:00:00.000', 'hinzugefuegt': '2023-10-20T00:00:00.000'},
    ],
    'tags': [
      {'id': 1, 'name': 'Dairy'},
    ],
    'itemTags': [
      {'itemId': 1, 'tagId': 1},
    ],
    'history': [
      {'id': 1, 'itemId': 1, 'name': 'Milk', 'basisProdukt': 'Milk', 'marke': 'Brand A', 'menge': 0.5, 'einheit': 'l', 'eventType': 'CONSUME', 'timestamp': '2023-10-25T10:00:00.000'},
    ],
    'products': [
      {'id': 1, 'name': 'Milk', 'basisProdukt': 'Milk', 'marke': 'Brand A', 'einheit': 'l', 'defaultHaltbarkeitTage': 14},
    ]
  });

  final recipesData = jsonEncode({
    'recipes': [
      {'id': 1, 'name': 'Pancakes', 'description': 'Delicious pancakes', 'prepTimeMinutes': 15, 'createdAt': '2023-10-20T00:00:00.000'},
    ],
    'ingredients': [
      {'id': 1, 'recipeId': 1, 'basisProdukt': 'Milk', 'menge': 0.2, 'einheit': 'l', 'sortOrder': 0},
    ]
  });

  // Create Zip
  final archive = Archive();
  archive.addFile(ArchiveFile('diary.json', diaryData.length, utf8.encode(diaryData)));
  archive.addFile(ArchiveFile('gym.json', gymData.length, utf8.encode(gymData)));
  archive.addFile(ArchiveFile('kitchen.json', kitchenData.length, utf8.encode(kitchenData)));
  archive.addFile(ArchiveFile('recipes.json', recipesData.length, utf8.encode(recipesData)));

  final zipData = ZipEncoder().encode(archive);
  if (zipData != null) {
    // Ensure docs dir exists
    final docsDir = Directory('../docs');
    if (!docsDir.existsSync()) {
      docsDir.createSync(recursive: true);
    }

    final file = File('../docs/backup_example.zip');
    await file.writeAsBytes(zipData);
    print('Backup file created successfully at ${file.path}');
  }
}
