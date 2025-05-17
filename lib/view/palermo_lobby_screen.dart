// Datei: lib/view/palermo_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:jugend_app/view/lobby_screen.dart';

class PalermoLobbyScreen extends StatelessWidget {
  const PalermoLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LobbyScreen(
      lobbyId: 'auto-gen-palermo',
      playerName: 'Player',
      isHost: true,
      gameType: 'Palermo',
    );
  }
}
