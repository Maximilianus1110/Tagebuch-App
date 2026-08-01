# App Features & Bedienung

Die **Tagebuch App** bietet ein übersichtliches Dashboard-Menü (`HomeScreen`), das als Einstiegspunkt zu allen drei Hauptkategorien der App führt: **Gym**, **Tagebuch** und **Küche/Rezepte**. Zusätzlich gibt es einen globalen Einstellungsbereich.

---

## 1. Gym (Fitness-Tracking)

Der Gym-Bereich (`GymScreen`) dient als zentrale Verwaltung für das Krafttraining.

*   **Übungen (`GymExercise`):**
    *   Verwaltung aller verfügbaren Übungen (Name, Beschreibung).
    *   Neue Übungen können sowohl in den Stammdaten als auch während eines aktiven Trainings dynamisch neu erstellt werden.
*   **Trainingspläne (`GymPlan`):**
    *   Erstellung, Bearbeitung und Sortierung eigener Trainingspläne.
    *   Hinzufügen von Übungen, Festlegen der Reihenfolge (`sortOrder`), Ziel-Satzanzahl (`setCount`), Ziel-Wiederholungen (`targetReps` als Text, z. B. "8-12" oder "5") und Markierung von Aufwärmsätzen (`isWarmup`).
*   **Training (`GymTraining` & `GymSet`):**
    *   **Aktives Training:** Startet ein Training basierend auf einem Plan. Während des Trainings läuft ein Rest-Timer für die Satzpausen. Nach Ablauf vibriert das Smartphone kurz.
    *   **Automatisches Ausfüllen (Progressive Overload):** Die Sätze, Wiederholungen und Gewichte werden intelligent basierend auf dem letzten Training dieses Plans oder dem letzten globalen Ausführen einer spezifischen Übung vorausgefüllt.
    *   **Nachtragen:** Vergangene Trainings können manuell ergänzt werden (Datum frei wählbar).
    *   Bewertung der Trainings (1-5 Sterne) und optionale Trainingsnotizen.
*   **Statistiken (`StatisticsScreen`):**
    *   Visualisierung von Trainingsfrequenz (Trainings pro Woche), Volumen (Sätze/Wiederholungen) und Maximalgewichten über die Zeit mittels `fl_chart`.

---

## 2. Tagebuch (Notizen & Gedanken)

Der Tagebuch-Bereich (`DiaryScreen`) dient dem Festhalten von Ereignissen und Notizen in einer chronologischen Liste.

*   **Einträge (`DiaryEntry`):**
    *   Jeder Eintrag besteht aus Datum (stets im Format `dd.MM.yyyy` formatiert), einem optionalen Titel und dem Haupttext.
*   **Kalender-Picker & Navigation:**
    *   Ein interaktiver Kalender (über `table_calendar`) ermöglicht das schnelle Auffinden von Einträgen. Bei Auswahl eines Datums im Kalender scrollt die Tagebuchliste automatisch zum entsprechenden Eintrag.
*   **Papierkorb (Soft-Delete & Cleanup):**
    *   Gelöschte Einträge werden nicht sofort gelöscht, sondern landen im Papierkorb (`TrashScreen`). Sie können dort manuell wiederhergestellt oder endgültig gelöscht werden.
    *   **Automatischer Cleanup-Job:** Bei jedem Start der App löscht die Datenbank im Hintergrund alle Einträge endgültig, die länger als 30 Tage im Papierkorb liegen.

---

## 3. Küche & Vorrat (`KitchenScreen`)

Die Küchenfunktion bietet eine umfangreiche Vorrats- und Bestandsverwaltung.

*   **Vorrat (`KitchenItem`):**
    *   Verwaltung von Lebensmitteln (Name, Basis-Produkt, Menge, Einheit, Marke, Mindesthaltbarkeitsdatum (MHD) und Tags).
    *   *Mengenverwaltung:* Intern werden alle Mengen in den Basis-Einheiten `g`, `ml` oder `Stück` gespeichert. Größere Einheiten wie `kg` oder `l` werden automatisch umgerechnet.
    *   Die UI gruppiert Artikel primär nach ihrem `basis_produkt` und summiert die Gesamtmengen dieser Gruppe für die Anzeige.
*   **Produkte & Autocomplete (`KitchenProduct`):**
    *   Die App lernt automatisch: Beim Erstellen eines Vorratselements werden die Produktdaten (Name, Basis-Produkt, Marke, Standard-Einheit, durchschnittliche Haltbarkeit) als Stammdaten gespeichert.
    *   Bei zukünftigen Eingaben schlägt das Autocomplete-Feld bekannte Produkte vor und füllt alle Felder (inklusive des berechneten MHDs anhand der Standard-Haltbarkeit) automatisch aus.
    *   *Haltbarkeits-Schnelleingabe:* Im MHD-Datumsfeld kann statt eines Datums auch einfach eine Zahl (z.B. `14`) eingegeben werden, was die App sofort als „heute + 14 Tage“ interpretiert.
*   **Status-Ampel (MHD):**
    *   Visuelle Markierung des Ablaufdatums: Rot (< 4 Tage), Gelb (< 10 Tage), Grün (>= 10 Tage).
*   **Massen-JSON-Import:**
    *   Über das JSON-Import-Menü (`KitchenImportScreen`) können Vorräte im Batch-Verfahren importiert werden.
    *   **Format des JSON-Imports:**
        ```json
        [
          {
            "name": "Frischmilch 1,5%",
            "basis_produkt": "Milch",
            "menge": 1,
            "einheit": "l",
            "marke": "Weihenstephan",
            "haltbar_tage": 10,
            "tags": ["Kühlschrank", "Frühstück"],
            "packungen": 2
          }
        ]
        ```
    *   *Mengenkonvertierung:* Einheiten wie `l` und `kg` werden beim Import automatisch in `ml` und `g` konvertiert.
    *   *Dynamisches MHD:* Das Feld `haltbar_tage` (Tage ab heute) oder `haltbar_bis` (ISO-Datum `YYYY-MM-DD`) legt das Ablaufdatum fest.
    *   *Multiplikator:* Über `packungen` oder `anzahl` wird der Eintrag entsprechend oft in die Datenbank geschrieben.
*   **Verbrauch & Entsorgung:**
    *   Vorräte können verbraucht (Menge wird reduziert, z. B. 200 ml Milch) oder weggeschmissen werden.
    *   Alle Aktionen werden im `kitchen_history`-Log festgehalten.
*   **Statistiken:**
    *   Grafische Auswertungen über konsumierte vs. entsorgte Lebensmittelmengen.

---

## 4. Rezepte (`RecipesScreen`)

Der Rezept-Bereich baut auf dem Küchenvorrat auf.

*   **Rezeptverwaltung (`Recipe`):**
    *   Name, Beschreibung der Zubereitung, Zubereitungszeit und eine Liste der Zutaten (`RecipeIngredient`).
    *   Zutaten verweisen auf `basis_produkt`-Kategorien oder Tags der Küche.
*   **Kochbarkeit (Cookability-Algorithmus):**
    *   Die App vergleicht die Zutatenliste jedes Rezepts mit den aktuell vorhandenen Beständen in der Küche.
    *   Rezepte werden automatisch nach ihrer „Kochbarkeit“ sortiert: Rezepte, für die alle Zutaten da sind, stehen ganz oben; Rezepte mit fehlenden Zutaten stehen weiter unten. Die genaue Anzahl fehlender Zutaten wird angezeigt.
*   **"Jetzt kochen" (Bestandsabzug):**
    *   Beim Ausführen eines Rezepts listet ein Dialog die passenden Vorratsartikel auf.
    *   **FIFO-Prinzip (First-In, First-Out):** Die App schlägt automatisch den Verbrauch der Artikel vor, die das kürzeste MHD haben, um Lebensmittelverschwendung zu minimieren.
    *   Nach der Bestätigung zieht die App die verbrauchten Mengen vom Küchenbestand ab und protokolliert dies im Historien-Log.

---

## 5. Einstellungen & Datenverwaltung

In den globalen Einstellungen (`SettingsScreen`) können folgende Optionen vorgenommen werden:

*   **Darstellung:** Umschalten des Farbschemas (Hell, Dunkel oder automatische Systemanpassung).
*   **Pausen-Timer (Gym):** Die Dauer des Rest-Timers zwischen den Sätzen kann in 10-Sekunden-Schritten konfiguriert werden.
*   **Daten exportieren:** Erstellt eine strukturierte Textdatei (`tagebuch_export.txt` / `gym_export.txt`) zum schnellen Lesen außerhalb der App.
*   **Backup erstellen:** Ermöglicht die Selektion von Datenbereichen (Tagebuch, Gym, Küche, Rezepte), packt diese in eine `.zip`-Datei mit JSON-Inhalten und öffnet den Teilen-Dialog.
*   **Backup wiederherstellen:** Ermöglicht den Import einer über die App erstellten Backup-ZIP-Datei. *Achtung: Dies überschreibt die aktuellen Daten der entsprechenden Kategorien.*
