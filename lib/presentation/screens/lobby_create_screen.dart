// Datei: lib/view/lobby_create_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';
import 'package:jugend_app/data/services/reconnect_service.dart';

class LobbyCreateScreen extends StatefulWidget {
  const LobbyCreateScreen({super.key});

  @override
  State<LobbyCreateScreen> createState() => _LobbyCreateScreenState();
}

class _LobbyCreateScreenState extends State<LobbyCreateScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _createLobby() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final lobbyId = (Random().nextInt(900000) + 100000).toString();
    const gameType = 'Impostor'; // später auswählbar machen

    final reconnectService = ReconnectService();
    final reconnectData = ReconnectData(
      lobbyId: lobbyId,
      playerName: name,
      isHost: true,
      gameType: gameType,
    );

    await reconnectService.registerReconnectData(reconnectData);

    if (!mounted) return;
    context.go('/lobby', extra: reconnectData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spiel erstellen'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/lobbies'),
        ),
      ),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createLobby,
              child: const Text('Lobby erstellen'),
            ),
          ],
        ),
      ),
    );
  }
}
