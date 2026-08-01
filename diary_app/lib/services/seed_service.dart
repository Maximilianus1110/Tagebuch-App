import 'dart:math';
import 'package:diary_app/db/database_helper.dart';
import 'package:diary_app/models/diary_entry.dart';
import 'package:diary_app/models/gym/gym_exercise.dart';
import 'package:diary_app/models/gym/gym_plan.dart';
import 'package:diary_app/models/gym/gym_training.dart';
import 'package:diary_app/models/kitchen/kitchen_history.dart';
import 'package:diary_app/models/kitchen/kitchen_item.dart';
import 'package:diary_app/models/kitchen/recipe.dart';
import 'package:diary_app/models/kitchen/recipe_ingredient.dart';
import 'package:diary_app/services/kitchen_service.dart';

class SeedService {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<bool> isDatabaseEmpty() async {
    final entries = await _db.readAllEntries();
    final exercises = await _db.getAllExercises();
    final recipes = await _db.getAllRecipes();
    final kitchenItems = await KitchenService().getAllItems();

    return entries.isEmpty && exercises.isEmpty && recipes.isEmpty && kitchenItems.isEmpty;
  }

  static Future<void> seedDatabase({bool overwrite = false}) async {
    if (overwrite) {
      await _db.clearDiary();
      await _db.clearGym();
      await _db.clearKitchen();
      await _db.clearRecipes();
    }

    final random = Random(42);
    final now = DateTime.now();

    // --- 1. Diary Seed Data ---
    final titlesAndContents = [
      ('Neues Trainingsziel erreicht', 'Heute beim Bankdrücken 80kg für 8 Wiederholungen geschafft! Super Gefühl. Danach gab es leckere Pfannkuchen.'),
      ('Wochenende im Grünen', 'Ein entspannter Spaziergang im Park. Das Wetter war ideal für eine kleine Auszeit in der Natur.'),
      ('Neues Rezept ausprobiert', 'Habe heute Hähnchen mit Reis und frischem Paprika gekocht. War schnell zubereitet und sehr nahrhaft.'),
      ('Produktiver Arbeitstag', 'Einige wichtige Aufgaben abgeschlossen und den Vorratsschrank in der Küche neu organisiert.'),
      ('Beintag im Fitnessstudio', 'Kniebeugen und Beinpresse durchgezogen. Beine fühlen sich wie Wackelpudding an, aber das Training war klasse!'),
      ('Gemütlicher Sonntag', 'Den Tag mit einem leckeren Porridge begonnen. Danach ein schönes Buch gelesen.'),
      ('Einkauf & Vorräte aufgestockt', 'Frische Lebensmittel gekauft: Milch, Eier, Quark und viel Gemüse. Alles gleich richtig eingeordnet.'),
      ('Entspannung & Regeneration', 'Heute Ruhetag eingelegt, Dehnübungen gemacht und früh schlafen gegangen.'),
      ('Ganzkörper-Workout', 'Intensives Ganzkörpertraining. Alle Grundübungen absolviert.'),
      ('Rezept-Ideen gesammelt', 'Ein paar neue Rezept-Ideen notiert. Vor allem schnelles Rührei mit Tomaten für morgens.'),
    ];

    for (int i = 0; i < titlesAndContents.length; i++) {
      final date = now.subtract(Duration(days: titlesAndContents.length - 1 - i, hours: 2));
      await _db.create(DiaryEntry(
        date: date,
        title: titlesAndContents[i].$1,
        content: titlesAndContents[i].$2,
      ));
    }

    // Add 2 trash items for demo
    final trashEntry = await _db.create(DiaryEntry(
      date: now.subtract(const Duration(days: 15)),
      title: 'Veraltete Notiz',
      content: 'Diese Notiz wurde nicht mehr benötigt und gelöscht.',
    ));
    await _db.delete(trashEntry.id!);

    // --- 2. Gym Seed Data ---
    final exercises = [
      {'name': 'Bankdrücken', 'description': 'Brustübung mit der Langhantel'},
      {'name': 'Kniebeugen', 'description': 'Beinübung mit der Langhantel'},
      {'name': 'Kreuzheben', 'description': 'Rücken- und Beinübung'},
      {'name': 'Klimmzüge', 'description': 'Rückenübung am Reck'},
      {'name': 'Schulterdrücken', 'description': 'Schulterübung mit Kurzhanteln'},
      {'name': 'Bizepscurls', 'description': 'Isolationsübung für den Bizeps'},
      {'name': 'Trizepsdrücken', 'description': 'Isolationsübung für den Trizeps am Kabelzug'},
      {'name': 'Beinpresse', 'description': 'Beinübung an der Maschine'},
    ];

    final insertedExercises = <GymExercise>[];
    for (var ex in exercises) {
      final created = await _db.createExercise(GymExercise(name: ex['name']!, description: ex['description']));
      insertedExercises.add(created);
    }

    final exMap = {for (var e in insertedExercises) e.name: e.id!};

    // Create Plans with Plan Exercises
    final planOk = await _db.createPlan(
      GymPlan(name: 'Oberkörper Focus'),
      [
        GymPlanExercise(planId: 0, exerciseId: exMap['Bankdrücken']!, setCount: 3, sortOrder: 0, targetReps: '8-10'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Klimmzüge']!, setCount: 3, sortOrder: 1, targetReps: '8-10'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Schulterdrücken']!, setCount: 3, sortOrder: 2, targetReps: '10-12'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Bizepscurls']!, setCount: 2, sortOrder: 3, targetReps: '12-15'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Trizepsdrücken']!, setCount: 2, sortOrder: 4, targetReps: '12-15'),
      ],
    );

    final planUk = await _db.createPlan(
      GymPlan(name: 'Unterkörper Focus'),
      [
        GymPlanExercise(planId: 0, exerciseId: exMap['Kniebeugen']!, setCount: 4, sortOrder: 0, targetReps: '6-8'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Kreuzheben']!, setCount: 3, sortOrder: 1, targetReps: '5-8'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Beinpresse']!, setCount: 3, sortOrder: 2, targetReps: '10-12'),
      ],
    );

    await _db.createPlan(
      GymPlan(name: 'Ganzkörper Allround'),
      [
        GymPlanExercise(planId: 0, exerciseId: exMap['Kniebeugen']!, setCount: 3, sortOrder: 0, targetReps: '8-10'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Bankdrücken']!, setCount: 3, sortOrder: 1, targetReps: '8-10'),
        GymPlanExercise(planId: 0, exerciseId: exMap['Klimmzüge']!, setCount: 3, sortOrder: 2, targetReps: '8-10'),
      ],
    );

    // Create past completed training sessions
    for (int t = 1; t <= 8; t++) {
      final tDate = now.subtract(Duration(days: (8 - t) * 3 + 1));
      final selectedPlanId = t % 2 == 1 ? planOk.id! : planUk.id!;
      final targetExList = selectedPlanId == planOk.id!
          ? [exMap['Bankdrücken']!, exMap['Klimmzüge']!, exMap['Schulterdrücken']!]
          : [exMap['Kniebeugen']!, exMap['Kreuzheben']!, exMap['Beinpresse']!];

      final sets = <GymSet>[];
      for (var exId in targetExList) {
        final baseWeight = exId == exMap['Bankdrücken'] ? 70.0 : (exId == exMap['Kniebeugen'] ? 85.0 : 60.0);
        for (int s = 1; s <= 3; s++) {
          sets.add(GymSet(
            trainingId: 0,
            exerciseId: exId,
            setNumber: s,
            reps: 8 + (s == 3 ? 0 : 2),
            weight: baseWeight + (t * 2.5),
            isDone: true,
            durationSeconds: 45,
          ));
        }
      }

      await _db.createTraining(
        GymTraining(
          planId: selectedPlanId,
          date: tDate,
          note: t % 2 == 1 ? 'Starkes Oberkörpertraining' : 'Gutes Unterkörper-Workout',
          durationSeconds: 3600 + random.nextInt(900),
          rating: 4 + (t % 2),
        ),
        sets,
      );
    }

    // --- 3. Kitchen Seed Data ---
    final kitchenService = KitchenService();
    final stockItems = [
      // Red MHD (< 4 days)
      {'name': 'Frischmilch 1,5%', 'basisProdukt': 'Milch', 'marke': 'Weihenstephan', 'menge': 1000.0, 'einheit': 'ml', 'daysExp': 2, 'tag': 'Kühlregal'},
      {'name': 'Hähnchenbrust', 'basisProdukt': 'Hähnchen', 'marke': 'Wiesenhof', 'menge': 500.0, 'einheit': 'g', 'daysExp': 3, 'tag': 'Fleisch'},
      // Yellow MHD (4-9 days)
      {'name': 'Magerquark', 'basisProdukt': 'Quark', 'marke': 'Milram', 'menge': 500.0, 'einheit': 'g', 'daysExp': 6, 'tag': 'Kühlregal'},
      {'name': 'Rispentomaten', 'basisProdukt': 'Tomaten', 'marke': 'Bio', 'menge': 600.0, 'einheit': 'g', 'daysExp': 7, 'tag': 'Gemüse'},
      {'name': 'Rote Paprika', 'basisProdukt': 'Paprika', 'marke': 'Frisch', 'menge': 3.0, 'einheit': 'Stück', 'daysExp': 8, 'tag': 'Gemüse'},
      // Green MHD (>= 10 days)
      {'name': 'Eier Freiland', 'basisProdukt': 'Eier', 'marke': 'Bauernhof', 'menge': 10.0, 'einheit': 'Stück', 'daysExp': 16, 'tag': 'Kühlregal'},
      {'name': 'Weizenmehl 405', 'basisProdukt': 'Mehl', 'marke': 'Aurora', 'menge': 1000.0, 'einheit': 'g', 'daysExp': 180, 'tag': 'Trockenvorrat'},
      {'name': 'Basmati Reis', 'basisProdukt': 'Reis', 'marke': 'Uncle Bens', 'menge': 1000.0, 'einheit': 'g', 'daysExp': 200, 'tag': 'Trockenvorrat'},
      {'name': 'Haferflocken', 'basisProdukt': 'Haferflocken', 'marke': 'Kölln', 'menge': 500.0, 'einheit': 'g', 'daysExp': 120, 'tag': 'Trockenvorrat'},
      {'name': 'Äpfel', 'basisProdukt': 'Apfel', 'marke': 'Pink Lady', 'menge': 6.0, 'einheit': 'Stück', 'daysExp': 12, 'tag': 'Obst'},
    ];

    for (var item in stockItems) {
      final expDate = now.add(Duration(days: item['daysExp'] as int));
      await kitchenService.createItem(
        KitchenItem(
          name: item['name'] as String,
          basisProdukt: item['basisProdukt'] as String,
          marke: item['marke'] as String,
          menge: item['menge'] as double,
          einheit: item['einheit'] as String,
          haltbarBis: expDate,
          hinzugefuegt: now.subtract(const Duration(days: 2)),
        ),
        [item['tag'] as String],
      );
    }

    // Kitchen History Log
    final rawDb = await _db.database;
    final historyLogs = [
      {'name': 'Vollmilch 3,5%', 'basisProdukt': 'Milch', 'marke': 'Weihenstephan', 'menge': 500.0, 'einheit': 'ml', 'eventType': 'CONSUME', 'daysAgo': 1},
      {'name': 'Rispentomaten', 'basisProdukt': 'Tomaten', 'marke': 'Bio', 'menge': 200.0, 'einheit': 'g', 'eventType': 'CONSUME', 'daysAgo': 2},
      {'name': 'Hähnchenbrust', 'basisProdukt': 'Hähnchen', 'marke': 'Wiesenhof', 'menge': 250.0, 'einheit': 'g', 'eventType': 'CONSUME', 'daysAgo': 3},
      {'name': 'Salatgurke', 'basisProdukt': 'Gurke', 'marke': '', 'menge': 1.0, 'einheit': 'Stück', 'eventType': 'DISCARD', 'daysAgo': 4},
    ];

    for (var h in historyLogs) {
      await rawDb.insert(KitchenHistoryFields.tableName, {
        KitchenHistoryFields.name: h['name'],
        KitchenHistoryFields.basisProdukt: h['basisProdukt'],
        KitchenHistoryFields.marke: h['marke'],
        KitchenHistoryFields.menge: h['menge'],
        KitchenHistoryFields.einheit: h['einheit'],
        KitchenHistoryFields.eventType: h['eventType'],
        KitchenHistoryFields.timestamp: now.subtract(Duration(days: h['daysAgo'] as int)).toIso8601String(),
      });
    }

    // --- 4. Recipe Seed Data ---
    final recipes = [
      {
        'name': 'Pfannkuchen',
        'description': 'Klassische Pfannkuchen, super lecker und schnell gemacht. Mehl, Milch und Eier glattrühren und goldbraun ausbacken.',
        'prepTimeMinutes': 15,
        'ingredients': [
          {'basisProdukt': 'Mehl', 'menge': 200.0, 'einheit': 'g', 'sortOrder': 0},
          {'basisProdukt': 'Milch', 'menge': 300.0, 'einheit': 'ml', 'sortOrder': 1},
          {'basisProdukt': 'Eier', 'menge': 2.0, 'einheit': 'Stück', 'sortOrder': 2},
        ]
      },
      {
        'name': 'Hähnchen mit Reis & Paprika',
        'description': 'Fitness-Mahlzeit. Hähnchenbrust würfeln und anbraten, Reis kochen, mit Paprika servieren.',
        'prepTimeMinutes': 25,
        'ingredients': [
          {'basisProdukt': 'Hähnchen', 'menge': 250.0, 'einheit': 'g', 'sortOrder': 0},
          {'basisProdukt': 'Reis', 'menge': 100.0, 'einheit': 'g', 'sortOrder': 1},
          {'basisProdukt': 'Paprika', 'menge': 1.0, 'einheit': 'Stück', 'sortOrder': 2},
        ]
      },
      {
        'name': 'Rührei mit Tomaten',
        'description': 'Eier in die Pfanne schlagen, Tomaten dazugeben und vorsichtig stocken lassen.',
        'prepTimeMinutes': 10,
        'ingredients': [
          {'basisProdukt': 'Eier', 'menge': 3.0, 'einheit': 'Stück', 'sortOrder': 0},
          {'basisProdukt': 'Tomaten', 'menge': 200.0, 'einheit': 'g', 'sortOrder': 1},
        ]
      },
      {
        'name': 'Fitness Porridge',
        'description': 'Haferflocken mit Milch kurz aufkochen und mit frischen Apfelspalten verfeinern.',
        'prepTimeMinutes': 10,
        'ingredients': [
          {'basisProdukt': 'Haferflocken', 'menge': 100.0, 'einheit': 'g', 'sortOrder': 0},
          {'basisProdukt': 'Milch', 'menge': 200.0, 'einheit': 'ml', 'sortOrder': 1},
          {'basisProdukt': 'Apfel', 'menge': 1.0, 'einheit': 'Stück', 'sortOrder': 2},
        ]
      },
    ];

    for (var r in recipes) {
      final recipeObj = Recipe(
        name: r['name'] as String,
        description: r['description'] as String,
        prepTimeMinutes: r['prepTimeMinutes'] as int,
        createdAt: now.subtract(const Duration(days: 5)),
      );

      final rawIngredients = r['ingredients'] as List<Map<String, dynamic>>;
      final ingredientsList = rawIngredients
          .map((i) => RecipeIngredient(
                recipeId: 0,
                basisProdukt: i['basisProdukt'] as String,
                menge: i['menge'] as double,
                einheit: i['einheit'] as String,
                sortOrder: i['sortOrder'] as int,
              ))
          .toList();

      await _db.createRecipe(recipeObj, ingredientsList);
    }
  }
}
