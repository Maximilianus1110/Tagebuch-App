# Tagebuch-App Dokumentation

## 1. Übersicht
Die Tagebuch-App ist eine minimalistische Android-Anwendung, die es Benutzern ermöglicht, ihre Gedanken in Textform festzuhalten. Der Fokus liegt auf Einfachheit und Datensicherheit. Alle Daten werden ausschließlich lokal auf dem Gerät gespeichert.

## 2. Funktionen

### 2.1 Startseite (Übersicht)
- **Liste der Einträge:** Zeigt alle gespeicherten Tagebucheinträge chronologisch sortiert an (neueste zuerst).
- **Datum:** Jeder Eintrag zeigt deutlich das Erstellungsdatum.
- **Vorschau:** Der Text des Eintrags wird direkt in der Liste angezeigt.
- **Neuer Eintrag:** Ein Plus-Button (+) unten rechts ermöglicht das Erstellen eines neuen Eintrags.
- **Exportieren:** Über das Teilen-Icon oben rechts können alle Einträge exportiert werden.

### 2.2 Neuer Eintrag
- **Datumswahl:** Standardmäßig ist das aktuelle Datum vorausgewählt. Durch Antippen des Datumsfeldes kann ein anderes Datum gewählt werden.
- **Textfeld:** Ein großes Eingabefeld bietet Platz für ausführliche Texte.
- **Speichern:** Der "SPEICHERN"-Button sichert den Eintrag in der lokalen Datenbank und kehrt zur Übersicht zurück.

### 2.3 Datenexport
- **Funktion:** Fasst alle Einträge in einer Textdatei (`tagebuch_export.txt`) zusammen.
- **Format:**
  ```text
  Datum: YYYY-MM-DD
  [Inhalt des Eintrags]

  Datum: YYYY-MM-DD
  [Inhalt des nächsten Eintrags]
  ```
- **Teilen:** Öffnet den nativen Android-Dialog zum Speichern oder Versenden der Datei (z.B. per E-Mail, Messenger oder Cloud-Speicher).

## 3. Datenschutz & Sicherheit
- **Lokale Speicherung:** Es findet keine Übertragung an externe Server statt. Die Datenbank (`diary.db`) liegt geschützt im privaten Speicher der App.
- **Keine Berechtigungen:** Die App fordert im Release-Build keine Internet-Berechtigung an.
- **Offline-First:** Die App funktioniert vollständig ohne Internetverbindung.

## 4. Technologie
- **Framework:** Flutter (Google)
- **Sprache:** Dart
- **Datenbank:** SQLite (via `sqflite`)
