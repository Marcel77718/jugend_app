// Datei: lib/view/impostor_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:jugend_app/view/lobby_screen.dart';

class ImpostorLobbyScreen extends StatelessWidget {
  const ImpostorLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LobbyScreen(
      lobbyId: 'auto-gen-impostor',
      playerName: 'Player',
      isHost: true,
      gameType: 'Impostor',
    );
  }
}
