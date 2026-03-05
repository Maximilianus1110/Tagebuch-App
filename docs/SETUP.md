# Setup & Ausführung

Diese Anleitung beschreibt, wie du die **Tagebuch App** lokal auf deinem Entwicklungsrechner einrichtest, baust und testest.

## Voraussetzungen

*   **Flutter SDK:** Version >= 3.x (aktueller Stable-Branch empfohlen).
*   **Dart SDK:** Wird automatisch mit Flutter installiert.
*   **Android Studio / Android SDK:** Notwendig für den Bau der Android-App (APK) und den Betrieb eines Emulators.
*   **Java Development Kit (JDK):** Version 17 wird für neuere Gradle-Versionen benötigt.
*   **Git:** Für Versionskontrolle und das Klonen des Repositories.

## 1. Repository klonen und Abhängigkeiten installieren

Öffne dein Terminal und klone das Projekt (falls noch nicht geschehen). Wechsle in das Verzeichnis `diary_app`:

```bash
cd diary_app
flutter pub get
```

Dies lädt alle im `pubspec.yaml` definierten Pakete (wie `sqflite`, `provider`, `fl_chart`, etc.) herunter.

## 2. App auf einem Emulator oder Gerät ausführen

Stelle sicher, dass ein Android-Emulator läuft oder ein physisches Android-Gerät über USB-Debugging verbunden ist.
Überprüfe die erkannten Geräte mit:

```bash
flutter devices
```

Starte die App im Debug-Modus:

```bash
flutter run
```

*Hinweis:* Die App ist **strikt für mobile Endgeräte konzipiert**. Der Web-Build wird nicht unterstützt, weshalb ein Starten über den Chrome-Browser (Web) zu Fehlern bei der Canvas-Darstellung oder dem SQLite-Zugriff führen kann.

## 3. Tests ausführen

Die App verfügt über eine Reihe von Unit- und Widget-Tests.
Da lokale SQLite-Tests unter Umständen Probleme beim Locking verursachen oder auf Web-Umgebungen nicht funktionieren, nutzt das Projekt `sqflite_common_ffi` (Mock-Datenbank) für Testzwecke.

Führe alle Tests aus mit:

```bash
flutter test
```

### Fehlerbehebung bei Tests (Timeouts)

*   **Timeouts (400 Sekunden):** In manchen Entwicklungsumgebungen können Tests hängen bleiben. Führe in diesem Fall Tests einzeln aus oder nutze Standalone Dart-Skripte (`dart path/to/script.dart`), um die reine Geschäftslogik (ohne Flutter-Widget-Overhead) zu verifizieren.
*   **Provider-Exceptions:** Stelle sicher, dass Widget-Tests, die `MyApp` oder bestimmte Screens laden, diese immer mit einem `ChangeNotifierProvider` (z.B. für `ThemeProvider`) umwickeln, da sonst die Dependency Injection zur Laufzeit des Tests fehlschlägt.

## 4. APK erstellen (Release Build)

Um eine installierbare APK-Datei für dein Android-Gerät zu erstellen, führe folgenden Befehl aus:

```bash
flutter build apk --release
```

Die fertige Datei findest du unter:
`build/app/outputs/flutter-apk/app-release.apk`

*Besonderheiten im Android Build:*
*   Der Namespace ist auf `de.jules.tagebuch_app` festgelegt (konfiguriert in `android/app/build.gradle.kts`).
*   Die App deaktiviert Cleartext-Traffic (HTTP) strikt (`android:usesCleartextTraffic="false"`) über die `network_security_config.xml`.
