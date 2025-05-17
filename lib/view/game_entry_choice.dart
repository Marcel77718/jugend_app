// Datei: lib/view/game_entry_choice.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/services/reconnect_service.dart';
import 'package:jugend_app/model/reconnect_data.dart';

class GameEntryChoiceScreen extends StatelessWidget {
  const GameEntryChoiceScreen({super.key});

  Future<void> _handleJoin(BuildContext context, String gameType) async {
    final reconnectService = ReconnectService();
    // final deviceId = await DeviceIdHelper.getOrCreateDeviceId(); // nicht benötigt

    const playerName = 'Player';
    const isHost = true;
    final lobbyId = 'lobby-${DateTime.now().millisecondsSinceEpoch}';

    final data = ReconnectData(
      lobbyId: lobbyId,
      playerName: playerName,
      isHost: isHost,
      gameType: gameType,
    );

    await reconnectService.registerReconnectData(data);

    if (!context.mounted) return;

    context.go('/lobby', extra: data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spiel auswählen')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Impostor'),
            onTap: () => _handleJoin(context, 'Impostor'),
          ),
          ListTile(
            title: const Text('Werwolf'),
            onTap: () => _handleJoin(context, 'Werwolf'),
          ),
          ListTile(
            title: const Text('Palermo'),
            onTap: () => _handleJoin(context, 'Palermo'),
          ),
        ],
      ),
    );
  }
}
