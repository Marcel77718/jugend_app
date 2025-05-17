// Datei: lib/view/werwolf_lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:jugend_app/view/lobby_screen.dart';

class WerwolfLobbyScreen extends StatelessWidget {
  const WerwolfLobbyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LobbyScreen(
      lobbyId: 'auto-gen-werwolf',
      playerName: 'Player',
      isHost: true,
      gameType: 'Werwolf',
    );
  }
}
