# GatherUp – Flutter App

## Projektüberblick

GatherUp ist eine moderne Flutter-App mit klarer Trennung von UI, Logik und Datenzugriff. Die Architektur ist so gestaltet, dass sie leicht wartbar, testbar und erweiterbar ist.

---

## Ordnerstruktur

```
lib/
  main.dart                  # App-Startpunkt
  router.dart                # Zentrales Routing
  firebase_options.dart      # Firebase-Konfiguration
  core/                      # Farben, Texte, ErrorService, Utils
    app_texts.dart
    snackbar_helper.dart
    error_service.dart
  data/
    models/                  # Datenmodelle (Player, ReconnectData, ...)
    services/                # Firestore, SharedPreferences, etc.
    repositories/            # Kapselt alle Datenzugriffe (Repository-Pattern)
  domain/
    viewmodels/              # State-Management & Logik für die UI
  presentation/
    screens/                 # Alle Screens/Seiten
    widgets/                 # Wiederverwendbare UI-Bausteine
    dialogs/                 # Dialoge
```

---

## Architektur

- **UI (presentation/):** Nur Darstellung und User-Interaktion. Kein direkter Datenzugriff.
- **ViewModels (domain/):** Vermitteln zwischen UI und Repository, enthalten State und UI-Logik.
- **Repository (data/repositories/):** Kapselt alle Datenzugriffe (Firestore, lokale DB, etc.).
- **Services (data/services/):** Einzelne Datenquellen (z.B. Firestore, SharedPreferences).
- **Core:** Farben, Texte, Fehlerbehandlung, Utilities.

---

## Firestore-Struktur

Die wichtigsten Collections und Felder:

- **users**
  - `uid` (Doc-ID): User-Dokument
    - `displayName`: Anzeigename
    - `email`: E-Mail-Adresse
    - `photoUrl`: Profilbild-URL
    - `tag`: 4-stelliger Tag (z.B. 1234)
    - `status`: online, lobby, game, offline
    - `currentLobbyId`: aktuelle Lobby (optional)
    - `lastActive`: Zeitstempel
- **lobbies**
  - `lobbyId` (Doc-ID): Lobby-Dokument
    - `hostId`: Device-ID des Hosts
    - `gameType`: Spieltyp
    - `status`: waiting, started, etc.
    - `lobbyStage`: lobby, settings, game
    - `createdAt`, `lastActivity`: Zeitstempel
    - **Subcollection:** `players`
      - `deviceId` (Doc-ID):
        - `name`, `isHost`, `isReady`, `photoUrl`, `tag`, `userUid`
- **reconnect**
  - `deviceId` (Doc-ID):
    - `lobbyId`, `playerName`, `isHost`, `gameType`
- **feedback**
  - `feedbackId` (Doc-ID):
    - `userId`, `userName`, `message`, `rating`, `createdAt`, ...

---

## Setup & Umgebung

- **Firebase:**
  - Die Datei `lib/firebase_options.dart` enthält die Konfiguration für verschiedene Plattformen.
  - Stelle sicher, dass dein Firebase-Projekt korrekt eingerichtet ist (Firestore, Auth, ggf. Storage).
  - Für lokale Entwicklung ggf. Emulatoren nutzen (`firebase emulators:start`).
- **Abhängigkeiten installieren:**
  - `flutter pub get`
- **Starten:**
  - `flutter run`
- **Linting:**
  - `dart format .`
  - `dart analyze`

---

## Erweiterung & Wartung

- **Neue Features:** Einfach neue ViewModels, Screens oder Repositories anlegen.
- **Datenzugriff:** Immer über das Repository, nie direkt aus der UI.
- **Fehlerbehandlung:** Über den ErrorService (`core/error_service.dart`).
- **Konstanten & Styles:** Zentral in `core/app_texts.dart` und `core/app_colors.dart`.
- **State-Management:** ViewModels bieten Loading- und Error-States für die UI.

---

## Hinweise

- Die App ist vorbereitet für weitere Features, Lokalisierung und Tests.
- Linting und Formatierung: Nutze `dart format .` und halte dich an die Linting-Regeln.
- Für Fragen oder Erweiterungen: Siehe Kommentare im Code oder frage im Team!
