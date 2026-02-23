# Tagebuch-App
Projekt-Spezifikation: Minimalistisches Text-Tagebuch (Android)
1. Übersicht & Ziel
Entwicklung einer extrem simplen, rein textbasierten Tagebuch-App für Android. Die App soll so minimalistisch wie möglich sein (vergleichbar mit einer sehr einfachen Notizen-App). Sie dient ausschließlich dem Festhalten von Gedanken in Textform.
2. Plattform & Technologie
 * Zielplattform: Android App
 * Technologie-Vorschlag: Flutter, React Native oder natives Kotlin (bitte das Framework nutzen, das am schnellsten zu einer stabilen Android-App führt).
3. Kernfunktionen & UI-Screens
Screen 1: Startseite (Übersicht)
 * Zeigt eine chronologische Liste aller bisherigen Tagebucheinträge (die neuesten Einträge ganz oben).
 * Jeder Listeneintrag zeigt das Datum (hervorgehoben) und den dazugehörigen Text.
 * Ein gut sichtbarer Button (z.B. ein Floating Action Button mit "+") zum Erstellen eines neuen Eintrags.
 * Ein "Export"-Button (z.B. ein Icon in der oberen App-Leiste).
Screen 2: Neuer Eintrag / Eingabe-Screen
 * Datum: Ein Eingabefeld für das Datum. Standardmäßig ist das aktuelle Tagesdatum (heute) vorausgewählt. Das Datum muss durch den Nutzer manuell änderbar sein.
 * Textfeld: Ein großes, mehrzeiliges Textfeld für den eigentlichen Tagebucheintrag.
 * Speichern: Ein "Speichern"-Button. Nach erfolgreichem Speichern wird der Nutzer automatisch zur aktualisierten Startseite zurückgeleitet.
4. Datenhaltung (Speicherung)
 * Ausschließlich Lokal: Alle Einträge werden lokal auf dem Smartphone des Nutzers gespeichert (z.B. via SQLite, Room Database oder SharedPreferences/lokaler JSON).
 * Es gibt keine Cloud-Anbindung, keine Server und keine Benutzerkonten.
5. Export-Funktion
 * Bei Klick auf den Export-Button auf der Startseite fasst die App alle bisherigen Einträge in einer einzigen .txt-Datei zusammen.
 * Formatierung innerhalb der .txt-Datei:
   Datum: [Datum des Eintrags]
   [Text des Eintrags]
   (Dieser Block wiederholt sich für jeden Eintrag)
 * Aktion nach Generierung: Die App öffnet nach dem Erstellen der Datei den nativen Android-Teilen-Dialog (Share Sheet). So kann der Nutzer die .txt-Datei direkt auf dem Handy speichern, per E-Mail senden oder in eine Cloud hochladen.
6. Explizite Anti-Features (Was NICHT entwickelt werden soll)
Um den minimalistischen Charakter strikt beizubehalten, sind folgende Features ausdrücklich verboten:
 * KEINE Bilder, Videos oder sonstige Datei-Anhänge.
 * KEINE Tags, Labels oder Ordnerstrukturen.
 * KEINE Textformatierungen (kein Fett, Kursiv, Unterstrichen etc., nur Plain Text).
 * KEINE Suchfunktion (außer sie ist mit 2 Zeilen Code gratis dabei).
 * KEINE Cloud-Synchronisation oder Logins.
 * 
