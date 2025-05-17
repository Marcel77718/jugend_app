// Datei: lib/view/widgets/player_tile.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:jugend_app/view/lobby_view_model.dart';

class PlayerTile extends StatelessWidget {
  final String playerId;
  final String playerName;
  final bool isHost;
  final bool isCurrentUser;

  const PlayerTile({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.isHost,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<LobbyViewModel>(context);

    return ListTile(
      leading: Icon(
        isHost
            ? Icons.emoji_events
            : isCurrentUser
            ? Icons.account_circle
            : Icons.person,
      ),
      title: Text(playerName),
      trailing:
          isHost && !isCurrentUser
              ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => viewModel.kickPlayer(playerId),
              )
              : null,
      onTap:
          isCurrentUser
              ? () async {
                final newName = await _showChangeNameDialog(
                  context,
                  playerName,
                );
                if (newName != null && newName.isNotEmpty) {
                  viewModel.confirmNameChangeDialog(newName);
                }
              }
              : null,
    );
  }

  Future<String?> _showChangeNameDialog(
    BuildContext context,
    String currentName,
  ) {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Namen ändern'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(labelText: 'Neuer Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Ändern'),
              ),
            ],
          ),
    );
  }
}
