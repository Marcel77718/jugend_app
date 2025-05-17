// Datei: lib/view/lobby_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jugend_app/view/lobby_view_model.dart';

class LobbyScreen extends StatelessWidget {
  final String lobbyId;
  final String playerName;
  final bool isHost;
  final String gameType;

  const LobbyScreen({
    super.key,
    required this.lobbyId,
    required this.playerName,
    required this.isHost,
    required this.gameType,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (_) =>
              LobbyViewModel()..initialize(
                lobbyId: lobbyId,
                playerName: playerName,
                isHost: isHost,
                gameType: gameType,
              ),
      child: Consumer<LobbyViewModel>(
        builder: (context, viewModel, _) {
          if (!viewModel.viewModelInitialized) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: AppBar(
              title: Text('${viewModel.gameType} Lobby'),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Center(
                    child: Text(
                      'ID: ${viewModel.lobbyId}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            body: Column(
              children: [
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: viewModel.players.length,
                    itemBuilder: (context, index) {
                      final player = viewModel.players[index];
                      final isReady = player['isReady'] == true;
                      final isCurrent = player['id'] == viewModel.deviceId;
                      final isHostPlayer = player['id'] == viewModel.hostId;

                      return ListTile(
                        leading: Icon(
                          isHostPlayer
                              ? Icons.emoji_events
                              : isReady
                              ? Icons.circle
                              : Icons.circle_outlined,
                          color:
                              isHostPlayer
                                  ? Colors.blue
                                  : isReady
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        title: Text(
                          player['name'] ?? 'Unbekannt',
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => viewModel.toggleReadyStatus(),
                      child: Text(
                        viewModel.isReady ? 'Nicht bereit' : 'Bereit',
                      ),
                    ),
                    if (viewModel.isHost && viewModel.everyoneReady)
                      ElevatedButton(
                        onPressed: viewModel.updateStatusStarted,
                        child: const Text('Spiel starten'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}
