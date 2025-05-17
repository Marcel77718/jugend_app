// 📁 Datei: lib/helpers/app_constants.dart

import 'package:flutter/material.dart';

class AppConstants {
  static const String labelPlayers = 'Spieler in der Lobby:';
  static const String dialogLeaveLobby =
      'Willst du die Lobby wirklich verlassen?';
  static const String titleLeaveLobby = 'Lobby verlassen?';
}

class AppColors {
  static const primary = Colors.teal;
  static const error = Colors.red;
  static const success = Colors.green;
  static const infoBoxBackground = Color(
    0xFF14796E,
  ); // Fix: 8-stelliger Hex-Wert
}

class AppText {
  static const errorNameTaken = 'Name ist bereits vergeben.';
  static const errorLobbyInvalid = '❌ Ungültige Lobby-ID';
  static const labelLobbyId = 'Lobby-ID';
  static const labelYourName = 'Du heißt';
  static const labelPlayers = 'Spieler in der Lobby:';
  static const dialogLeaveLobby = 'Willst du die Lobby wirklich verlassen?';
  static const titleLeaveLobby = 'Lobby verlassen?';
  static const labelReady = 'Bereit';
  static const labelNotReady = 'Nicht bereit';
  static const labelStartGame = 'Spiel starten';
  static const labelNameChange = 'Neuen Namen eingeben';
  static const hintNameInput = 'z. B. Simon';
  static const labelSave = 'Speichern';
  static const labelCancel = 'Abbrechen';
}
