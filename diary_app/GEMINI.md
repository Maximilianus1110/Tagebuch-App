# GEMINI.md - Tagebuch-App Projektkontext

## 1. WICHTIGER HINWEIS ZUR SPRACHE
**Der Benutzer ist deutschsprachig.**
*   Alle Interaktionen, Fragen und Antworten müssen auf **Deutsch** erfolgen.
*   Die Dokumentation (DOKUMENTATION.md, SETUP.md) und Kommentare in Code-Bereichen, die für den Endnutzer relevant sind, sollten bevorzugt auf Deutsch verfasst werden oder zumindest verständlich sein.
*   Code-Variable und Klassennamen bleiben in Englisch (Standard-Konvention), aber die Erklärung dazu erfolgt auf Deutsch.

## 2. Projektübersicht
Minimalistisches, rein textbasiertes Android-Tagebuch mit Fokus auf Datensicherheit und Einfachheit.
Nutzt Flutter für UI und Business Logic, SQLite für lokale Datenhaltung.

## 3. Tech Stack
- **Framework:** Flutter (Stable)
- **Sprache:** Dart (>=3.0.0)
- **Datenbank:** `sqflite` (SQLite Wrapper für Flutter)
- **State Management:** `setState` (Lokal in Widgets für einfache Logik)
- **Export:** `share_plus` (Teilen-Dialog), `path_provider` (Dateizugriff), `intl` (Datumsformatierung)

## 4. Dateistruktur (Wichtigste Dateien)
```
diary_app/
├── lib/
│   ├── main.dart               # App-Einstiegspunkt, Theme-Setup
│   ├── models/
│   │   └── diary_entry.dart    # Datenmodell für Tagebucheinträge (JSON serialization)
│   ├── db/
│   │   └── database_helper.dart # Singleton für SQLite-Interaktion (CRUD)
│   ├── screens/
│   │   ├── home_screen.dart    # Liste aller Einträge + Export-Button
│   │   └── add_entry_screen.dart # Formular für neue Einträge
│   └── services/
│       └── export_service.dart # Logik für Textdatei-Export und Teilen
├── test/
│   ├── widget_test.dart        # Integrationstests für UI und Navigation
│   └── models/
│       └── diary_entry_test.dart # Unit-Tests für Model-Logik
├── pubspec.yaml                # Abhängigkeiten und Projektkonfiguration
├── android/                    # Native Android-Konfigurationen
│   └── app/src/main/AndroidManifest.xml # App-Label, Berechtigungen (Internet disabled for release)
├── DOKUMENTATION.md            # Benutzerhandbuch (DE)
└── SETUP.md                    # Installationsanleitung (DE)
```

## 5. Wichtige Implementierungsdetails
- **Datenbank:** `DatabaseHelper` implementiert Singleton-Pattern. `_createDB` erstellt Tabelle `entries` mit `_id`, `date`, `content`.
- **Export:** `ExportService.exportEntries()` liest alle Daten, formatiert sie (`Datum: ...\nInhalt\n\n`), schreibt temporäre Datei und nutzt `Share.shareXFiles`.
- **Sicherheit:** Release-Build hat keine Internet-Permission (`android.permission.INTERNET` nur im Debug-Manifest).

## 6. Status
- [x] Initialisierung (Flutter Project)
- [x] Datenbank-Implementierung
- [x] UI-Entwicklung (Liste, Hinzufügen)
- [x] Export-Funktion
- [x] Tests (Unit & Widget)
- [x] Dokumentation (DE)
