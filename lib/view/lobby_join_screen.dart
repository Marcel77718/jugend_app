// Datei: lib/view/lobby_join_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/model/reconnect_data.dart';
import 'package:jugend_app/services/reconnect_service.dart';

class LobbyJoinScreen extends StatefulWidget {
  const LobbyJoinScreen({super.key});

  @override
  State<LobbyJoinScreen> createState() => _LobbyJoinScreenState();
}

class _LobbyJoinScreenState extends State<LobbyJoinScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lobbyIdController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _lobbyIdController.dispose();
    super.dispose();
  }

  void _joinLobby() async {
    final name = _nameController.text.trim();
    final lobbyId = _lobbyIdController.text.trim();
    if (name.isEmpty || lobbyId.isEmpty) return;

    const gameType = 'Impostor'; // später auswählbar machen

    final reconnectService = ReconnectService();
    final reconnectData = ReconnectData(
      lobbyId: lobbyId,
      playerName: name,
      isHost: false,
      gameType: gameType,
    );

    await reconnectService.registerReconnectData(reconnectData);

    if (!mounted) return;
    context.go('/lobby', extra: reconnectData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spiel beitreten')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Dein Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lobbyIdController,
              decoration: const InputDecoration(
                labelText: 'Lobby-ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _joinLobby,
              child: const Text('Beitreten'),
            ),
          ],
        ),
      ),
    );
  }
}
