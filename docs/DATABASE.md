# Datenbank & Modelle

Die **Tagebuch App** verwendet `sqflite` (SQLite für Flutter), um alle Daten lokal auf dem Android-Gerät zu speichern. Die Initialisierung, Tabellenerstellung und Migration (Upgrades) werden zentral im `DatabaseHelper` (`lib/db/database_helper.dart`) verwaltet.

## Versionierung (Aktuell: Version 10)

Die Datenbankversion wird stetig erhöht, wenn neue Features hinzukommen.
*   **Version 1-3:** Diary-Einträge und Soft-Delete.
*   **Version 4-7:** Gym-Features (Übungen, Pläne, Trainings, Sätze, Dauer, Bewertung).
*   **Version 8-9:** Küchen-Features (Vorrat, Tags, Historie).
*   **Version 10:** Rezept-Features (Rezepte, Zutaten).

## Modelle & Tabellen

Jedes Modell (`lib/models/`) besitzt eine entsprechende Klasse (z.B. `DiaryEntryFields`), die die Konstanten für die Tabellen- und Spaltennamen bereitstellt.
Alle Primärschlüssel heißen `_id` (`idType = 'INTEGER PRIMARY KEY AUTOINCREMENT'`).
Datumsangaben werden stets als `TEXT` (`toIso8601String()`) gespeichert, um Kompatibilität mit SQLite sicherzustellen.

### 1. Diary (Tagebuch)
*   **`diary_entries` (`DiaryEntry`)**: Speichert alle Tagebucheinträge.
    *   Felder: `date`, `content`, `title`, `deletedAt` (für Soft-Delete).

### 2. Gym (Fitness)
*   **`gym_exercises` (`GymExercise`)**: Liste der Übungen (z. B. Bankdrücken).
*   **`gym_plans` (`GymPlan`)**: Namen der Trainingspläne.
*   **`gym_plan_exercises` (`GymPlanExercise`)**: Verknüpfung von Übungen mit Plänen inkl. Zielvorgaben (`setCount`, `sortOrder`, `targetReps`, `isWarmup`).
*   **`gym_trainings` (`GymTraining`)**: Durchgeführte Trainings (`planId`, `date`, `durationSeconds`, `rating`, `note`).
*   **`gym_sets` (`GymSet`)**: Einzelne Sätze eines Trainings (`trainingId`, `exerciseId`, `setNumber`, `reps`, `weight`, `isDone`, `durationSeconds`, `isWarmup`).

### 3. Kitchen (Küche)
*   **`kitchen_items` (`KitchenItem`)**: Vorratseinträge. Mengen werden als `REAL` gespeichert, immer in der zugehörigen Basiseinheit (z.B. `g`, `ml`, `Stück`). Einheiten wie `kg` oder `l` werden vor dem Speichern konvertiert.
*   **`kitchen_tags` (`KitchenTag`)**: Kategorisierungen von Artikeln.
*   **`kitchen_item_tags`**: Many-to-Many-Verknüpfungstabelle zwischen Artikeln und Tags.
*   **`kitchen_history` (`KitchenHistory`)**: Log-Tabelle für alle Konsum- oder Wegwerf-Ereignisse zur statistischen Auswertung.

### 4. Recipes (Rezepte)
*   **`recipes` (`Recipe`)**: Kochrezepte (Name, Beschreibung, Zubereitungszeit, Erstellungsdatum).
*   **`recipe_ingredients` (`RecipeIngredient`)**: Die benötigten Zutaten für ein Rezept (`recipeId`, `basisProdukt`, `menge`, `einheit`, `sortOrder`). Das `basisProdukt` fungiert hierbei als Suchbegriff (Name oder Tag) für den Abgleich mit dem `kitchen_items`-Bestand.

## Performance-Optimierung

*   **Batch-Operationen:** Beim Speichern großer Datenmengen (z.B. JSON-Import in der Küche oder Speichern eines Trainingsplans mit vielen Übungen) nutzt die App die `Batch`-API (`txn.batch()` bzw. `txn.insert`), um N+1-Query-Probleme zu vermeiden und die MethodChannel-Aufrufe zwischen Dart und SQLite zu reduzieren.
*   **Joins:** Wo möglich, werden SQL-Joins (`INNER JOIN`) verwendet, um verknüpfte Daten abzurufen (z.B. Tags zu Artikeln oder der letzte Trainingssatz einer bestimmten Übung).

## Datenexport und Sicherung

*   Der Datenexport erfolgt über den `ExportService`. Die App unterstützt den Export aller Daten oder speziell ausgewählter Bereiche (z. B. nur Gym-Daten) im Klartext, welche per `share_plus` geteilt werden können. Da keine Cloud existiert, ist dies die einzige Backup-Möglichkeit.
