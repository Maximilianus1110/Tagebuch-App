# Datenbank & Modelle

Die **Tagebuch App** verwendet `sqflite` (SQLite für Flutter), um alle Daten lokal auf dem Gerät zu speichern. Die Initialisierung, Tabellenerstellung und Migration (Upgrades) werden zentral im `DatabaseHelper` (`diary_app/lib/db/database_helper.dart`) verwaltet.

## Versionierung (Aktuell: Version 11)

Die Datenbankversion wird stetig erhöht, wenn neue Features hinzukommen:
*   **Version 1-3:** Diary-Einträge und Soft-Delete.
*   **Version 4-7:** Gym-Features (Übungen, Pläne, Trainings, Sätze, Dauer, Bewertung).
*   **Version 8-9:** Küchen-Features (Vorrat, Tags, Historie).
*   **Version 10:** Rezept-Features (Rezepte, Zutaten).
*   **Version 11:** Einführung der Tabelle `kitchen_products` für Produkt-Stammdaten zur Unterstützung von Autocomplete-Vorschlägen und automatische Datenmigration der bestehenden Vorräte.

## Modelle & Tabellen

Jedes Modell (`diary_app/lib/models/`) besitzt eine entsprechende Klasse (z.B. `DiaryEntryFields`), die die Konstanten für die Tabellen- und Spaltennamen bereitstellt.
Alle Primärschlüssel heißen `_id` (`idType = 'INTEGER PRIMARY KEY AUTOINCREMENT'`).
Datumsangaben werden stets als `TEXT` (`toIso8601String()`) gespeichert, um Kompatibilität mit SQLite sicherzustellen.

### 1. Diary (Tagebuch)
*   **`diary_entries` (`DiaryEntry`)**: Speichert alle Tagebucheinträge.
    *   Spalten: `_id`, `date`, `content`, `title`, `deletedAt` (für Soft-Delete).

### 2. Gym (Fitness)
*   **`gym_exercises` (`GymExercise`)**: Liste der Übungen (z. B. Bankdrücken).
    *   Spalten: `_id`, `name`, `description`.
*   **`gym_plans` (`GymPlan`)**: Namen der Trainingspläne.
    *   Spalten: `_id`, `name`.
*   **`gym_plan_exercises` (`GymPlanExercise`)**: Verknüpfung von Übungen mit Plänen inkl. Zielvorgaben.
    *   Spalten: `_id`, `planId`, `exerciseId`, `setCount`, `sortOrder`, `targetReps`, `isWarmup` (0 = Falsch, 1 = Wahr).
*   **`gym_trainings` (`GymTraining`)**: Durchgeführte Trainingssitzungen.
    *   Spalten: `_id`, `planId`, `date`, `note`, `durationSeconds`, `rating` (1-5 Sterne).
*   **`gym_sets` (`GymSet`)**: Einzelne Sätze eines Trainings.
    *   Spalten: `_id`, `trainingId`, `exerciseId`, `setNumber`, `reps`, `weight`, `isDone` (0/1), `durationSeconds`, `isWarmup` (0/1).

### 3. Kitchen (Küche)
*   **`kitchen_products` (`KitchenProduct`)**: Stammdaten für Produkte. Speichert Name, Basis-Produkt, Marke, Standard-Einheit und Standard-Haltbarkeit in Tagen (`default_haltbarkeit_tage`). Dient als Katalog für Autocomplete-Funktionen beim Hinzufügen von Vorräten oder Rezepten.
    *   Spalten: `_id`, `name` (UNIQUE), `basis_produkt`, `marke`, `einheit`, `default_haltbarkeit_tage`.
*   **`kitchen_items` (`KitchenItem`)**: Tatsächliche Vorratseinträge. Mengen werden als `REAL` gespeichert, immer in der zugehörigen Basiseinheit (z.B. `g`, `ml`, `Stück`). Einheiten wie `kg` oder `l` werden vor dem Speichern konvertiert.
    *   Spalten: `_id`, `name`, `basis_produkt`, `marke`, `menge`, `einheit`, `haltbar_bis`, `hinzugefuegt`.
*   **`kitchen_tags` (`KitchenTag`)**: Kategorisierungen von Artikeln.
    *   Spalten: `_id`, `name` (UNIQUE).
*   **`kitchen_item_tags`**: Many-to-Many-Verknüpfungstabelle zwischen Artikeln und Tags.
    *   Spalten: `itemId` (FK), `tagId` (FK).
*   **`kitchen_history` (`KitchenHistory`)**: Log-Tabelle für alle Konsum- oder Wegwerf-Ereignisse zur statistischen Auswertung.
    *   Spalten: `_id`, `itemId`, `name`, `basis_produkt`, `marke`, `menge`, `einheit`, `eventType` ('consumed' / 'trashed'), `timestamp`.

### 4. Recipes (Rezepte)
*   **`recipes` (`Recipe`)**: Kochrezepte.
    *   Spalten: `_id`, `name`, `description`, `prepTimeMinutes`, `createdAt`.
*   **`recipe_ingredients` (`RecipeIngredient`)**: Die benötigten Zutaten für ein Rezept. Das `basisProdukt` fungiert hierbei als Suchbegriff (Name oder Tag) für den Abgleich mit dem `kitchen_items`-Bestand.
    *   Spalten: `_id`, `recipeId`, `basisProdukt`, `menge`, `einheit`, `sortOrder`.

## Performance-Optimierung

*   **Batch-Operationen:** Beim Speichern großer Datenmengen (z.B. JSON-Import in der Küche, Wiederherstellung von Backups oder Speichern eines Trainingsplans) nutzt die App die `Batch`-API (`txn.batch()`), um N+1-Query-Probleme zu vermeiden und die MethodChannel-Aufrufe zwischen Dart und SQLite zu reduzieren.
*   **Joins:** SQL-Joins (`INNER JOIN`) werden verwendet, um verknüpfte Daten abzurufen (z.B. Tags zu Artikeln oder der letzte Trainingssatz einer bestimmten Übung).

## Datenexport und Sicherung

Da keine Cloud-Synchronisation existiert, bietet die App zwei lokale Möglichkeiten zur Datensicherung an, die über die Einstellungen gesteuert werden:

1. **Textbasierter Export (`ExportService`):**
   * Exportiert Tagebucheinträge und/oder den Gym-Trainingsverlauf als lesbare Textdateien (`tagebuch_export.txt` / `gym_export.txt`) und öffnet den Teilen-Dialog.

2. **ZIP-Backup & Restore (`BackupService`):**
   * Erstellt ein ZIP-Archiv, das JSON-Dateien für jede Kategorie enthält. Dieses ZIP-Backup kann über die App wieder importiert werden, um den Zustand wiederherzustellen (überschreibt bestehende Daten der im ZIP enthaltenen Bereiche).
   * **Struktur des ZIP-Archivs:**
     * `diary.json`: Enthält alle Einträge der Tabelle `diary_entries`.
     * `gym.json`: Enthält alle Übungen, Pläne, Verknüpfungen, Trainings und Sätze.
     * `kitchen.json`: Enthält den aktuellen Vorrat, Tags, Produkt-Stammdaten und die Historie.
     * `recipes.json`: Enthält alle Rezepte und deren Zutaten.
