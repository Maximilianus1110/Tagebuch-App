# GEMINI.md - Tagebuch & Gym-App Projektkontext

## 1. WICHTIGER HINWEIS ZUR SPRACHE
**Der Benutzer ist deutschsprachig.**
*   Alle Interaktionen, Fragen und Antworten müssen auf **Deutsch** erfolgen.
*   Die Dokumentation und Kommentare in Code-Bereichen, die für den Endnutzer relevant sind, sollten bevorzugt auf Deutsch verfasst werden.
*   Code-Variable und Klassennamen bleiben in Englisch (Standard-Konvention), aber die Erklärung dazu erfolgt auf Deutsch.

## 2. Projektübersicht
Eine kombinierte App für ein minimalistisches Tagebuch und einen funktionsreichen Gym-Tracker. Fokus auf Datensicherheit (lokale Speicherung) und Einfachheit.
Nutzt Flutter für UI und Business Logic, SQLite für lokale Datenhaltung.

## 3. Tech Stack
- **Framework:** Flutter (Stable)
- **Sprache:** Dart (>=3.0.0)
- **Datenbank:** `sqflite` (SQLite Wrapper für Flutter)
- **State Management:** `setState` (Lokal in Widgets für einfache Logik)
- **Export:** `share_plus` (Teilen-Dialog), `path_provider` (Dateizugriff), `intl` (Datumsformatierung)

## 4. Dateistruktur (Kernkomponenten)
```
diary_app/
├── lib/
│   ├── main.dart               # App-Einstiegspunkt, Theme-Setup
│   ├── db/
│   │   └── database_helper.dart # Singleton für SQLite (Tagebuch & Gym CRUD)
│   ├── models/
│   │   ├── diary_entry.dart    # Tagebuchmodell (inkl. Soft-Delete & Titel)
│   │   └── gym/                # Gym-Modelle (Equipment, Plans, Trainings, Sets)
│   ├── screens/
│   │   ├── home_screen.dart    # Hauptmenü (Auswahl: Gym / Tagebuch)
│   │   ├── diary_screen.dart   # Liste der aktiven Tagebucheinträge
│   │   ├── add_entry_screen.dart # Editor für neue/bestehende Einträge
│   │   ├── trash_screen.dart   # Papierkorb für Tagebucheinträge (Auto-Delete nach 30 Tagen)
│   │   ├── gym_screen.dart     # Übersicht der Trainingspläne
│   │   └── gym/                # Gym-Detail-Screens (Planerstellung, Übungsverwaltung, Training)
│   ├── services/
│   │   ├── export_service.dart # Export von Tagebucheinträgen
│   │   └── gym_service.dart    # Geschäftslogik für den Gym-Bereich
│   └── widgets/
│       └── app_drawer.dart     # App-Navigation (falls verwendet)
├── test/                       # Unit- und Widget-Tests
├── pubspec.yaml                # Abhängigkeiten
├── DOKUMENTATION.md            # Benutzerhandbuch (DE)
└── SETUP.md                    # Installationsanleitung (DE)
```

## 5. Kernfunktionen & Implementierung
### Tagebuch (Diary)
- **CRUD:** Erstellen, Lesen, Aktualisieren, Löschen.
- **Soft-Delete:** Gelöschte Einträge landen im `trash_screen.dart`.
- **Auto-Cleanup:** Einträge im Papierkorb werden nach 30 Tagen automatisch endgültig gelöscht (`DatabaseHelper._cleanupTrash`).
- **Export:** Alle aktiven Einträge können als Textdatei geteilt werden.

### Gym-Tracker
- **Übungsverwaltung:** Definition von Equipment/Übungen.
- **Trainingspläne:** Zusammenstellung von Übungen zu individuellen Plänen.
- **Trainingseinheiten:** Protokollierung von Sätzen (Gewicht, Wiederholungen) pro Training.
- **Historie:** Einsehen vergangener Trainingseinheiten eines Plans.

## 6. Datenbank-Schema (Version 4)
- `entries`: Tagebuchdaten (`_id`, `date`, `content`, `title`, `deletedAt`).
- `gym_equipment`: Liste der Übungen.
- `gym_plans`: Kopfdaten der Trainingspläne.
- `gym_plan_exercises`: Verknüpfung von Plänen und Übungen.
- `gym_trainings`: Kopfdaten einer Trainingseinheit.
- `gym_sets`: Einzelne Sätze pro Übung innerhalb eines Trainings.

## 7. Sicherheit
- Release-Build hat keine Internet-Berechtigung (`android.permission.INTERNET` deaktiviert).
- Alle Daten werden ausschließlich lokal in der SQLite-Datenbank (`diary.db`) gespeichert.
