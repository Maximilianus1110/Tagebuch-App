import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:archive/archive_io.dart';

void main() async {
  final random = Random(42);

  // --- Diary Data ---
  final diaryEntries = <Map<String, dynamic>>[];
  for (int i = 1; i <= 30; i++) {
    final date = DateTime.now().subtract(Duration(days: 30 - i));
    diaryEntries.add({
      'id': i,
      'date': date.toIso8601String(),
      'content': 'Liebes Tagebuch, heute ist Tag $i meiner Aufzeichnungen. '
          'Das Wetter war ${['sonnig', 'regnerisch', 'bewölkt', 'windig'][random.nextInt(4)]} '
          'und ich habe mich ${['sehr gut', 'okay', 'gestresst', 'produktiv'][random.nextInt(4)]} gefühlt.\n\n'
          'Heute habe ich einiges erledigen können.',
      'title': 'Eintrag $i - Ein ${['guter', 'normaler', 'anstrengender'][random.nextInt(3)]} Tag',
      'deletedAt': null
    });
  }
  final diaryData = jsonEncode({'entries': diaryEntries});

  // --- Gym Data ---
  final exercises = [
    {'id': 1, 'name': 'Bankdrücken', 'description': 'Brustübung mit der Langhantel'},
    {'id': 2, 'name': 'Kniebeugen', 'description': 'Beinübung mit der Langhantel'},
    {'id': 3, 'name': 'Kreuzheben', 'description': 'Rücken- und Beinübung'},
    {'id': 4, 'name': 'Klimmzüge', 'description': 'Rückenübung am Reck'},
    {'id': 5, 'name': 'Schulterdrücken', 'description': 'Schulterübung mit Kurzhanteln'},
    {'id': 6, 'name': 'Bizepscurls', 'description': 'Isolationsübung für den Bizeps'},
    {'id': 7, 'name': 'Trizepsdrücken', 'description': 'Isolationsübung für den Trizeps am Kabelzug'},
    {'id': 8, 'name': 'Beinpresse', 'description': 'Beinübung an der Maschine'},
  ];

  final plans = [
    {'id': 1, 'name': 'Oberkörper'},
    {'id': 2, 'name': 'Unterkörper'},
    {'id': 3, 'name': 'Ganzkörper'},
  ];

  final planExercises = [
    // Oberkörper
    {'id': 1, 'planId': 1, 'exerciseId': 1, 'setCount': 3, 'sortOrder': 0, 'targetReps': '8-10', 'isWarmup': 0},
    {'id': 2, 'planId': 1, 'exerciseId': 4, 'setCount': 3, 'sortOrder': 1, 'targetReps': '8-10', 'isWarmup': 0},
    {'id': 3, 'planId': 1, 'exerciseId': 5, 'setCount': 3, 'sortOrder': 2, 'targetReps': '10-12', 'isWarmup': 0},
    {'id': 4, 'planId': 1, 'exerciseId': 6, 'setCount': 2, 'sortOrder': 3, 'targetReps': '12-15', 'isWarmup': 0},
    {'id': 5, 'planId': 1, 'exerciseId': 7, 'setCount': 2, 'sortOrder': 4, 'targetReps': '12-15', 'isWarmup': 0},
    // Unterkörper
    {'id': 6, 'planId': 2, 'exerciseId': 2, 'setCount': 4, 'sortOrder': 0, 'targetReps': '6-8', 'isWarmup': 0},
    {'id': 7, 'planId': 2, 'exerciseId': 3, 'setCount': 3, 'sortOrder': 1, 'targetReps': '5-8', 'isWarmup': 0},
    {'id': 8, 'planId': 2, 'exerciseId': 8, 'setCount': 3, 'sortOrder': 2, 'targetReps': '10-12', 'isWarmup': 0},
  ];

  final trainings = <Map<String, dynamic>>[];
  final sets = <Map<String, dynamic>>[];
  int setIdCounter = 1;

  for (int i = 1; i <= 10; i++) {
    final date = DateTime.now().subtract(Duration(days: 10 - i, hours: 2));
    final planId = i % 2 == 0 ? 1 : 2; // Wechsel zwischen OK und UK
    trainings.add({
      'id': i,
      'planId': planId,
      'date': date.toIso8601String(),
      'note': 'Gutes Training, Kraft war ${['super', 'okay', 'nicht so gut'][random.nextInt(3)]}',
      'durationSeconds': 3600 + random.nextInt(1800),
      'rating': 3 + random.nextInt(3), // 3 to 5
    });

    final currentPlanExercises = planExercises.where((pe) => pe['planId'] == planId).toList();
    for (var pe in currentPlanExercises) {
      int count = pe['setCount'] as int;
      for (int s = 1; s <= count; s++) {
        sets.add({
          'id': setIdCounter++,
          'trainingId': i,
          'exerciseId': pe['exerciseId'],
          'setNumber': s,
          'reps': 8 + random.nextInt(5),
          'weight': 20.0 + random.nextInt(60),
          'isDone': 1,
          'durationSeconds': 45 + random.nextInt(30),
          'isWarmup': 0,
        });
      }
    }
  }

  final gymData = jsonEncode({
    'exercises': exercises,
    'plans': plans,
    'planExercises': planExercises,
    'trainings': trainings,
    'sets': sets,
  });

  // --- Kitchen Data ---
  final tags = [
    {'id': 1, 'name': 'Kühlregal'},
    {'id': 2, 'name': 'Gemüse'},
    {'id': 3, 'name': 'Obst'},
    {'id': 4, 'name': 'Trockenvorrat'},
    {'id': 5, 'name': 'Fleisch'},
  ];

  final products = [
    {'id': 1, 'name': 'Vollmilch 3,5%', 'basisProdukt': 'Milch', 'marke': 'Weihenstephan', 'einheit': 'l', 'defaultHaltbarkeitTage': 10},
    {'id': 2, 'name': 'Eier Freiland', 'basisProdukt': 'Eier', 'marke': 'Bauernhof', 'einheit': 'Stück', 'defaultHaltbarkeitTage': 20},
    {'id': 3, 'name': 'Weizenmehl 405', 'basisProdukt': 'Mehl', 'marke': 'Aurora', 'einheit': 'kg', 'defaultHaltbarkeitTage': 365},
    {'id': 4, 'name': 'Basmati Reis', 'basisProdukt': 'Reis', 'marke': 'Uncle Bens', 'einheit': 'kg', 'defaultHaltbarkeitTage': 365},
    {'id': 5, 'name': 'Hähnchenbrust', 'basisProdukt': 'Hähnchen', 'marke': 'Wiesenhof', 'einheit': 'kg', 'defaultHaltbarkeitTage': 4},
    {'id': 6, 'name': 'Rispentomaten', 'basisProdukt': 'Tomaten', 'marke': 'Bio', 'einheit': 'kg', 'defaultHaltbarkeitTage': 7},
    {'id': 7, 'name': 'Rote Paprika', 'basisProdukt': 'Paprika', 'marke': '', 'einheit': 'Stück', 'defaultHaltbarkeitTage': 7},
    {'id': 8, 'name': 'Haferflocken', 'basisProdukt': 'Haferflocken', 'marke': 'Kölln', 'einheit': 'kg', 'defaultHaltbarkeitTage': 180},
    {'id': 9, 'name': 'Magerquark', 'basisProdukt': 'Quark', 'marke': 'Milram', 'einheit': 'g', 'defaultHaltbarkeitTage': 14},
    {'id': 10, 'name': 'Äpfel', 'basisProdukt': 'Apfel', 'marke': 'Pink Lady', 'einheit': 'kg', 'defaultHaltbarkeitTage': 14},
  ];

  final items = <Map<String, dynamic>>[];
  final itemTags = <Map<String, dynamic>>[];
  final history = <Map<String, dynamic>>[];
  
  for (int i = 1; i <= 25; i++) {
    final product = products[random.nextInt(products.length)];
    final dateAdd = DateTime.now().subtract(Duration(days: random.nextInt(14)));
    final dateExp = dateAdd.add(Duration(days: product['defaultHaltbarkeitTage'] as int));
    
    double menge = 1.0;
    if (product['einheit'] == 'g') menge = 500.0;
    if (product['einheit'] == 'Stück' && product['basisProdukt'] == 'Eier') menge = 10.0;
    if (product['einheit'] == 'Stück' && product['basisProdukt'] == 'Paprika') menge = 3.0;

    items.add({
      'id': i,
      'name': product['name'],
      'basisProdukt': product['basisProdukt'],
      'marke': product['marke'],
      'menge': menge,
      'einheit': product['einheit'],
      'haltbarBis': dateExp.toIso8601String(),
      'hinzugefuegt': dateAdd.toIso8601String(),
    });

    // Add tags
    int tagId = 4; // Trockenvorrat default
    if (product['basisProdukt'] == 'Milch' || product['basisProdukt'] == 'Quark') tagId = 1;
    if (product['basisProdukt'] == 'Tomaten' || product['basisProdukt'] == 'Paprika') tagId = 2;
    if (product['basisProdukt'] == 'Apfel') tagId = 3;
    if (product['basisProdukt'] == 'Hähnchen') tagId = 5;

    itemTags.add({'itemId': i, 'tagId': tagId});

    // Add some consume history
    if (random.nextBool()) {
      history.add({
        'id': i,
        'itemId': i,
        'name': product['name'],
        'basisProdukt': product['basisProdukt'],
        'marke': product['marke'],
        'menge': menge / 2,
        'einheit': product['einheit'],
        'eventType': 'CONSUME',
        'timestamp': DateTime.now().subtract(Duration(days: random.nextInt(5))).toIso8601String(),
      });
    }
  }

  final kitchenData = jsonEncode({
    'items': items,
    'tags': tags,
    'itemTags': itemTags,
    'history': history,
    'products': products,
  });

  // --- Recipes Data ---
  final recipes = [
    {'id': 1, 'name': 'Pfannkuchen', 'description': 'Klassische Pfannkuchen, super lecker und schnell gemacht.', 'prepTimeMinutes': 15, 'createdAt': DateTime.now().subtract(Duration(days: 20)).toIso8601String()},
    {'id': 2, 'name': 'Hähnchen mit Reis', 'description': 'Fitness-Mahlzeit. Hähnchen anbraten, Reis kochen, mischen.', 'prepTimeMinutes': 25, 'createdAt': DateTime.now().subtract(Duration(days: 15)).toIso8601String()},
    {'id': 3, 'name': 'Rührei mit Tomaten', 'description': 'Eier aufschlagen, Tomaten würfeln, ab in die Pfanne.', 'prepTimeMinutes': 10, 'createdAt': DateTime.now().subtract(Duration(days: 10)).toIso8601String()},
    {'id': 4, 'name': 'Porridge', 'description': 'Haferflocken mit Milch aufkochen, mit Äpfeln garnieren.', 'prepTimeMinutes': 10, 'createdAt': DateTime.now().subtract(Duration(days: 5)).toIso8601String()},
  ];

  final ingredients = [
    // Pfannkuchen
    {'id': 1, 'recipeId': 1, 'basisProdukt': 'Mehl', 'menge': 0.2, 'einheit': 'kg', 'sortOrder': 0},
    {'id': 2, 'recipeId': 1, 'basisProdukt': 'Milch', 'menge': 0.3, 'einheit': 'l', 'sortOrder': 1},
    {'id': 3, 'recipeId': 1, 'basisProdukt': 'Eier', 'menge': 2.0, 'einheit': 'Stück', 'sortOrder': 2},
    // Hähnchen mit Reis
    {'id': 4, 'recipeId': 2, 'basisProdukt': 'Hähnchen', 'menge': 0.25, 'einheit': 'kg', 'sortOrder': 0},
    {'id': 5, 'recipeId': 2, 'basisProdukt': 'Reis', 'menge': 0.1, 'einheit': 'kg', 'sortOrder': 1},
    {'id': 6, 'recipeId': 2, 'basisProdukt': 'Paprika', 'menge': 1.0, 'einheit': 'Stück', 'sortOrder': 2},
    // Rührei mit Tomaten
    {'id': 7, 'recipeId': 3, 'basisProdukt': 'Eier', 'menge': 3.0, 'einheit': 'Stück', 'sortOrder': 0},
    {'id': 8, 'recipeId': 3, 'basisProdukt': 'Tomaten', 'menge': 0.2, 'einheit': 'kg', 'sortOrder': 1},
    // Porridge
    {'id': 9, 'recipeId': 4, 'basisProdukt': 'Haferflocken', 'menge': 0.1, 'einheit': 'kg', 'sortOrder': 0},
    {'id': 10, 'recipeId': 4, 'basisProdukt': 'Milch', 'menge': 0.2, 'einheit': 'l', 'sortOrder': 1},
    {'id': 11, 'recipeId': 4, 'basisProdukt': 'Apfel', 'menge': 1.0, 'einheit': 'Stück', 'sortOrder': 2},
  ];

  final recipesData = jsonEncode({
    'recipes': recipes,
    'ingredients': ingredients,
  });

  // Create Zip
  final archive = Archive();
  archive.addFile(ArchiveFile('diary.json', diaryData.length, utf8.encode(diaryData)));
  archive.addFile(ArchiveFile('gym.json', gymData.length, utf8.encode(gymData)));
  archive.addFile(ArchiveFile('kitchen.json', kitchenData.length, utf8.encode(kitchenData)));
  archive.addFile(ArchiveFile('recipes.json', recipesData.length, utf8.encode(recipesData)));

  final zipData = ZipEncoder().encode(archive);

  // Ensure docs dir exists
  final docsDir = Directory('../docs');
  if (!docsDir.existsSync()) {
    docsDir.createSync(recursive: true);
  }

  final file = File('../docs/backup_example.zip');
  await file.writeAsBytes(zipData);
  print('Umfangreiches Backup erfolgreich erstellt unter: ${file.path}');
}
