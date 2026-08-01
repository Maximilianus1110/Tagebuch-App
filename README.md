# Tagebuch App

Willkommen im Repository der **Tagebuch App**. 

Diese App ist eine moderne, datenschutzfreundliche Offline-First-Anwendung für Android und iOS. Sie speichert alle Daten ausschließlich lokal in einer SQLite-Datenbank auf dem Endgerät. Sie bietet eine multifunktionale Umgebung, die über das klassische Festhalten von Gedanken hinausgeht und drei eng miteinander verknüpfte Kernbereiche bereitstellt.

## Die drei Kernbereiche

1. **Tagebuch:** 
   * Chronologisches Festhalten von Gedanken und Notizen.
   * Intuitive Navigation über einen Kalender.
   * Sicherer Soft-Delete (Papierkorb) mit automatischer Bereinigung nach 30 Tagen.

2. **Gym (Fitness-Tracker):**
   * Verwaltung von Trainingsplänen und Übungen.
   * Aktives Trainingstracking mit Satz-Timer und Vibrationsfeedback bei Satzpausen.
   * Progressive Overload-Unterstützung durch intelligentes Vorbefüllen von Gewichten/Wiederholungen aus der Historie.
   * Visualisierung von Frequenz, Volumen und Maximalgewichten über grafische Statistiken.

3. **Küche & Rezepte:**
   * Detaillierte Vorratsverwaltung mit Mindesthaltbarkeitsdatum (MHD) und Status-Ampel.
   * Autocomplete und Stammdatenpflege für schnelles Eintragen.
   * Rezept-Management mit intelligentem Abgleich des vorhandenen Vorrats (Cookability-Sortierung).
   * „Jetzt kochen“-Funktion mit automatischem Abzug der benötigten Mengen nach dem First-In, First-Out-Prinzip (bezüglich MHD).

---

## Dokumentation

Die vollständige technische und funktionale Dokumentation befindet sich im Ordner [docs/](file:///c:/woorkspace/Tagebuch-App/docs/INDEX.md):

* **[Features & Bedienung](file:///c:/woorkspace/Tagebuch-App/docs/FEATURES.md):** Detaillierte Beschreibung aller Funktionen.
* **[Architektur & Struktur](file:///c:/woorkspace/Tagebuch-App/docs/ARCHITECTURE.md):** Informationen zum Tech-Stack, den Schichten und der Verzeichnisstruktur des Projekts.
* **[Datenbank & Modelle](file:///c:/woorkspace/Tagebuch-App/docs/DATABASE.md):** Dokumentation der SQLite-Tabellen, Modelle und der Versionierung (aktuell Version 11).
* **[Setup & Installation](file:///c:/woorkspace/Tagebuch-App/docs/SETUP.md):** Anleitung zur Einrichtung, Ausführung und dem Build der App.

---

## Projektstruktur
Das eigentliche Flutter-Projekt befindet sich im Unterverzeichnis [diary_app/](file:///c:/woorkspace/Tagebuch-App/diary_app).

*Sprache der Dokumentation: Deutsch*
*Sprache im Code (Variablen, Klassen): Englisch*
