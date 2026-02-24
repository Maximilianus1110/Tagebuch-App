# Tagebuch & Gym-Tracker Dokumentation

## 1. Übersicht
Die App ist ein kombinierter Begleiter für den Alltag und das Training. Sie bietet ein minimalistisches Tagebuch zum Festhalten von Gedanken sowie einen funktionsreichen Gym-Tracker zur Dokumentation von Trainingseinheiten. Alle Daten werden ausschließlich lokal auf dem Gerät gespeichert, um maximale Datensicherheit zu gewährleisten.

## 2. Hauptmenü
Beim Start der App gelangen Sie in das Hauptmenü. Hier können Sie zwischen den beiden Hauptbereichen wählen:
- **Gym:** Verwalten Sie Ihre Übungen, Trainingspläne und protokollieren Sie Ihre Einheiten.
- **Tagebuch:** Schreiben Sie tägliche Einträge und verwalten Sie Ihre Notizen.

## 3. Tagebuch-Funktionen

### 3.1 Übersicht (Diary Screen)
- **Liste der Einträge:** Zeigt alle aktiven Tagebucheinträge chronologisch sortiert an (neueste zuerst).
- **Vorschau:** Titel und Inhalt werden direkt in der Liste angezeigt.
- **Papierkorb:** Über das Papierkorb-Icon gelangen Sie zu gelöschten Einträgen.
- **Exportieren:** Alle aktiven Einträge können über das Teilen-Icon als Textdatei (`tagebuch_export.txt`) exportiert werden.

### 3.2 Neuer Eintrag / Bearbeiten
- **Titel:** Geben Sie jedem Eintrag eine optionale Überschrift.
- **Datum:** Das Datum kann manuell angepasst werden.
- **Inhalt:** Ein großes Textfeld für Ihre Gedanken.
- **Löschen:** Über das Mülleimer-Icon können Einträge in den Papierkorb verschoben werden (Soft-Delete).

### 3.3 Papierkorb (Trash Screen)
- **Wiederherstellen:** Versehentlich gelöschte Einträge können hier reaktiviert werden.
- **Endgültiges Löschen:** Einträge können manuell endgültig entfernt werden.
- **Auto-Cleanup:** Der Papierkorb wird automatisch bereinigt. Einträge, die älter als 30 Tage sind, werden dauerhaft gelöscht.

## 4. Gym-Tracker-Funktionen

### 4.1 Übersicht (Gym Screen)
- **Trainingspläne:** Hier finden Sie eine Liste all Ihrer erstellten Pläne (z.B. "Push-Tag", "Beine").
- **Plan erstellen:** Über den Button "Neuer Plan" können Sie Übungen aus dem Katalog auswählen und zu einem Plan zusammenfassen.

### 4.2 Übungsverwaltung (Manage Exercises)
- **Katalog:** Verwalten Sie die Liste der verfügbaren Übungen.
- **Hinzufügen:** Fügen Sie neue Übungen (z.B. "Bankdrücken", "Kniebeugen") hinzu.

### 4.3 Trainingseinheit (Training Session)
- **Protokoll:** Starten Sie ein Training basierend auf einem Plan.
- **Sätze:** Pro Übung können Gewicht und Wiederholungen eingetragen werden.
- **Historie:** Vor dem Start eines Trainings können vergangene Einheiten eingesehen werden, um Fortschritte zu verfolgen.

## 5. Datenschutz & Sicherheit
- **Lokale Speicherung:** Alle Daten liegen in der verschlüsselten Datenbank (`diary.db`) im privaten Speicher der App.
- **Keine Cloud:** Es findet keine Übertragung an externe Server statt.
- **Keine Internet-Berechtigung:** Die App benötigt im Release-Build keinen Internetzugriff.
- **Offline-First:** Die App ist zu 100% offline nutzbar.

## 6. Technologie
- **Framework:** Flutter (Google)
- **Sprache:** Dart
- **Datenbank:** SQLite (via `sqflite`)
- **State Management:** Lokal via `setState` für maximale Performance und Einfachheit.
