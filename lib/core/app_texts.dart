// 📁 Datei: lib/core/app_texts.dart

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Colors.teal;
  static const error = Colors.red;
  static const success = Colors.green;
  static const neutral = Colors.grey;
  static const infoBoxBackground = Color(0xFF14796E);
}

class AppText {
  static const String labelPlayers = 'Spieler in der Lobby:';
  static const String dialogLeaveLobby =
      'Willst du die Lobby wirklich verlassen?';
  static const String titleLeaveLobby = 'Lobby verlassen?';
  static const String errorNameTaken = 'Name ist bereits vergeben.';
  static const String errorLobbyInvalid = '❌ Ungültige Lobby-ID';
  static const String labelLobbyId = 'Lobby-ID';
  static const String labelYourName = 'Du heißt';
  static const String labelReady = 'Bereit';
  static const String labelNotReady = 'Nicht bereit';
  static const String labelStartGame = 'Spiel starten';
  static const String labelNameChange = 'Neuen Namen eingeben';
  static const String hintNameInput = 'z. B. Simon';
  static const String labelSave = 'Speichern';
  static const String labelCancel = 'Abbrechen';
}
