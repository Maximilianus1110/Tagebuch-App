# App Features & Bedienung

Die **Tagebuch App** bietet ein Dashboard-Menü (`HomeScreen`), das als Einstiegspunkt zu allen drei Hauptkategorien der App führt: **Gym**, **Tagebuch** und **Küche/Rezepte**.

## 1. Gym (Fitness-Tracking)

Der Gym-Bereich (`GymScreen`) dient als zentrale Verwaltung für das Krafttraining.

*   **Übungen (`GymExercise`):**
    *   Verwaltung aller verfügbaren Übungen (Name, Beschreibung).
    *   Können während des Trainings dynamisch neu erstellt werden.
*   **Trainingspläne (`GymPlan`):**
    *   Erstellung und Bearbeitung eigener Trainingspläne.
    *   Hinzufügen von Übungen, Festlegen der Reihenfolge (`sortOrder`), Ziel-Wiederholungen (`targetReps`) und Markierung von Aufwärmsätzen (`isWarmup`).
*   **Training (`GymTraining` & `GymSet`):**
    *   **Aktives Training:** Startet einen Timer für Sätze. Der Rest-Timer signalisiert durch Vibration das Ende der Pause (Standard: 2:30 Min).
    *   **Automatisches Ausfüllen:** Sätze und Gewichte werden intelligent basierend auf dem letzten Training oder dem letzten Ausführen einer spezifischen Übung vorausgefüllt (Progressive Overload).
    *   **Nachtragen:** Vergangene Trainings können manuell ergänzt werden.
    *   Bewertung der Trainings (1-5 Sterne) und Notizen.
*   **Statistiken (`StatisticsScreen`):**
    *   Visualisierung von Trainingsfrequenz, Volumen (Sätze/Wiederholungen) und Maximalgewichten über die Zeit mittels `fl_chart`.

## 2. Tagebuch (Notizen & Gedanken)

Der Tagebuch-Bereich (`DiaryScreen`) dient dem Festhalten von Ereignissen und Notizen in einer chronologischen Liste.

*   **Einträge (`DiaryEntry`):**
    *   Datum, Titel und Inhalt (Text).
    *   Datumsformat ist stets `dd.MM.yyyy`.
*   **Kalender:**
    *   Ein Kalender-Picker (über `table_calendar`) ermöglicht die Navigation zu bestimmten Tagen. Bei Auswahl scrollt die Liste automatisch zum jeweiligen Eintrag.
*   **Papierkorb (Soft-Delete):**
    *   Gelöschte Einträge landen im Papierkorb.
    *   Ein automatischer Bereinigungsjob (`DatabaseHelper._cleanupTrash`) löscht endgültig alle Einträge, die älter als 30 Tage sind, beim Starten der App.

## 3. Küche & Vorrat (`KitchenScreen`)

Die Küchenfunktion bietet eine umfangreiche Vorrats- und Bestandsverwaltung.

*   **Vorrat (`KitchenItem`):**
    *   Verwaltung von Lebensmitteln (Name, Basis-Produkt, Menge, Einheit, Marke, Mindesthaltbarkeitsdatum (MHD), Tags).
    *   *Mengenverwaltung:* Intern werden alle Mengen in Basis-Einheiten gespeichert (`g`, `ml`, `Stück`), um Berechnungen stabil zu halten.
    *   Die UI gruppiert Artikel primär nach ihrem `basis_produkt` und summiert die Gesamtmengen dieser Gruppe für die Anzeige.
*   **Status-Ampel (MHD):**
    *   Visuelle Indikatoren (Rot < 4 Tage, Gelb < 10 Tage, Grün >= 10 Tage) warnen vor ablaufenden Produkten.
*   **JSON-Import:**
    *   Massenimport von Vorräten aus JSON-Dateien, inklusive dynamischer MHD-Berechnung (`haltbar_tage` oder `haltbar_bis`) und Multiplikation von Einträgen (`packungen`).
*   **Verbrauch & Entsorgung:**
    *   Produkte können ganz ("wegschmeißen") oder teilweise ("verbrauchen") aus dem Vorrat entfernt werden.
    *   Alle Aktionen werden im `kitchen_history`-Log festgehalten.
*   **Statistiken:**
    *   Analysen über den Lebensmittelverbrauch, verknüpft mit den Log-Einträgen.

## 4. Rezepte (`RecipesScreen`)

Der Rezept-Bereich baut auf dem Vorrat der Küche auf und verknüpft diese.

*   **Rezeptverwaltung (`Recipe`):**
    *   Name, Zubereitungsbeschreibung und Dauer.
    *   Liste an Zutaten (`RecipeIngredient`), basierend auf den `basis_produkt`-Kategorien oder Tags des Vorrats.
*   **Kochbarkeit (Cookability):**
    *   Der Algorithmus prüft automatisch den Vorrat und berechnet, welche Zutaten für ein Rezept vorhanden sind oder fehlen.
    *   Rezepte werden automatisch so sortiert, dass die am einfachsten zu kochenden (die wenigsten fehlenden Zutaten) oben stehen.
*   **"Jetzt kochen" Funktion:**
    *   Das Kochen eines Rezepts öffnet einen Modal-Dialog, der die im Vorrat vorhandenen, passenden Artikel auflistet.
    *   Die App schlägt automatisch die Entnahme der Produkte mit dem kürzesten MHD (First-In, First-Out bezüglich MHD) vor.
    *   Durch Bestätigung werden die exakten Mengen vom Küchenbestand abgezogen und automatisch im Historien-Log verbucht.
