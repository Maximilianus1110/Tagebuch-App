# Setup & Installation (Android)

Diese Anleitung beschreibt, wie du die Tagebuch-App auf deinem Computer einrichtest, baust und auf deinem Android-Smartphone installierst.

## 1. Voraussetzungen

Bevor du beginnst, benötigst du folgende Tools:
1.  **Flutter SDK:** Die aktuelle Version (Stable) herunterladen und installieren (siehe [flutter.dev/docs/get-started/install](https://docs.flutter.dev/get-started/install)).
2.  **Android Studio:** Für die Android-SDK-Tools und den Emulator (optional). Stelle sicher, dass das Android SDK installiert ist.
3.  **Git:** Um das Repository zu klonen.
4.  **Java JDK:** Für den Build-Prozess (oft in Android Studio enthalten).

Überprüfe die Installation mit:
```bash
flutter doctor
```

## 2. Projekt klonen & Abhängigkeiten installieren

1.  Öffne ein Terminal (oder die Eingabeaufforderung).
2.  Navigiere in den Ordner, in dem du das Projekt speichern möchtest.
3.  Klone das Repository:
    ```bash
    git clone https://github.com/username/repository.git
    cd diary_app
    ```
4.  Lade die benötigten Pakete herunter:
    ```bash
    flutter pub get
    ```

## 3. App ausführen (Debug-Modus)

Um die App im Emulator oder auf einem angeschlossenen Gerät zu testen:

1.  Starte einen Android-Emulator über Android Studio oder schließe dein Smartphone per USB an (USB-Debugging aktivieren!).
2.  Führe folgenden Befehl aus:
    ```bash
    flutter run
    ```

## 4. App bauen (Release APK)

Um eine installationsfähige APK-Datei für dein Smartphone zu erstellen:

1.  Führe den Build-Befehl aus:
    ```bash
    flutter build apk --release
    ```
2.  Die fertige Datei findest du unter:
    `build/app/outputs/flutter-apk/app-release.apk`

## 5. Installation auf dem Smartphone

1.  Kopiere die `app-release.apk` auf dein Smartphone (per USB, Google Drive, E-Mail etc.).
2.  Öffne die Datei auf dem Smartphone.
3.  Bestätige die Installation (ggf. musst du die Installation aus unbekannten Quellen zulassen).

## 6. Datenbank zurücksetzen (Optional)

Da die Datenbank lokal gespeichert wird, bleiben Daten auch nach einem App-Neustart erhalten. Um alle Daten zu löschen, deinstalliere die App einfach und installiere sie neu. Alternativ kannst du in den Android-Einstellungen unter "Apps" -> "Tagebuch App" -> "Speicher" -> "Daten löschen" wählen.
