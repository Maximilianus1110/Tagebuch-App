# Architektur & Struktur

Die **Tagebuch App** ist als Flutter Applikation für mobile Endgeräte (Android/iOS) konzipiert. Der Fokus liegt auf einer **lokalen Speicherung (Offline-First)** ohne jegliche Cloud-Anbindung, was maximalen Datenschutz und Unabhängigkeit gewährleistet.

## Tech Stack

*   **Framework:** Flutter
*   **Programmiersprache:** Dart
*   **Datenbank:** SQLite (via `sqflite` und `sqflite_common_ffi` für Tests)
*   **State Management / Dependency Injection:** Provider (`provider`)
*   **Lokale Speicherung (Preferences):** Shared Preferences (`shared_preferences`)
*   **Diagramme & Statistiken:** fl_chart
*   **Datei-Import/Export:** `file_picker`, `archive` (für ZIP-Backups) und `share_plus`
*   **UI/Design System:** Material Design 3 (Material 3)

## Architektur-Muster

Die App folgt weitgehend einer klassischen dreischichtigen Architektur (Schichtenarchitektur):

1.  **UI-Layer (Screens & Widgets):**
    *   Verantwortlich für die Darstellung und Benutzerinteraktion.
    *   Zustandsverwaltung über `StatefulWidget` oder `Provider`.
    *   Enthält Logik für Navigation und UI-Updates.
2.  **Service-Layer (Services):**
    *   Enthält die Geschäftslogik der App (`GymService`, `KitchenService`, `RecipeService`, `BackupService`, `ExportService`).
    *   Kapselt den Zugriff auf die Datenbank und bereitet Daten für die UI auf.
    *   Sorgt für die Trennung von UI und Datenbank.
3.  **Data-Layer (Database & Models):**
    *   `DatabaseHelper` agiert als Singleton und verwaltet die SQLite-Verbindung und das Schema.
    *   `Models` repräsentieren die Entitäten der Datenbank (z. B. `DiaryEntry`, `KitchenItem`, `Recipe`) in Dart und enthalten Logik für JSON-Serialisierung/Deserialisierung (`toJson`, `fromJson`).

## Verzeichnisstruktur (`diary_app/lib/`)

Die Dateistruktur ist domänengetrieben aufgebaut, wobei jeder Hauptbereich (Gym, Kitchen, Diary) seine eigenen Modelle und Screens hat. Das eigentliche Flutter-Projekt befindet sich im Ordner `diary_app`.

```text
diary_app/lib/
├── db/                     # Datenbankverwaltung
│   └── database_helper.dart
├── models/                 # Dart Modelle
│   ├── diary_entry.dart
│   ├── gym/                # Gym-bezogene Modelle
│   └── kitchen/            # Küchen- und Rezept-bezogene Modelle
├── screens/                # UI Screens (Ansichten)
│   ├── gym_screen.dart
│   ├── diary_screen.dart
│   ├── home_screen.dart    # Hauptmenü-Dashboard
│   ├── gym/                # Gym-spezifische Screens
│   ├── kitchen/            # Küchen- und Rezept-spezifische Screens
│   └── settings/           # Einstellungen
├── services/               # Geschäftslogik und Datenzugriff
│   ├── backup_service.dart # ZIP-Backup- & Wiederherstellungslogik
│   ├── export_service.dart # Textbasierter Export
│   ├── gym_service.dart
│   ├── kitchen_service.dart
│   ├── recipe_service.dart
│   └── settings_service.dart
├── widgets/                # Wiederverwendbare UI-Komponenten
│   └── app_drawer.dart
└── main.dart               # App-Einstiegspunkt
```

## Theming & UI

Die App nutzt **Material Design 3**. Ein zentraler `ThemeProvider` verwaltet die Umschaltung zwischen Dark Mode, Light Mode oder der Übernahme der Systemeinstellungen. Die Hauptfarbe (Primary Color) ist `Cyan` (`Color(0xFF00B4D8)`). Alle primären UI-Elemente wie Buttons, Icons und Auswahlanzeigen greifen auf `Theme.of(context).colorScheme.primary` zu, um in allen Modi ausreichend Kontrast zu gewährleisten.
