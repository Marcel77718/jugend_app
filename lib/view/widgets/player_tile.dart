// Datei: lib/view/widgets/player_tile.dart

import 'package:flutter/material.dart';

class PlayerTile extends StatelessWidget {
  final Map<String, dynamic> player;
  final bool isHost;
  final bool isOwnPlayer;
  final VoidCallback? onKick;
  final VoidCallback? onNameChange;

  const PlayerTile({
    super.key,
    required this.player,
    required this.isHost,
    required this.isOwnPlayer,
    this.onKick,
    this.onNameChange,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = player['isReady'] == true;

    final point = Icon(
      isHost ? (isReady ? Icons.circle : Icons.circle_outlined) : Icons.circle,
      color:
          isHost
              ? Colors.blue
              : isReady
              ? Colors.green
              : Colors.red,
      size: 12,
    );

    final crown =
        isHost
            ? const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.workspace_premium,
                size: 16,
                color: Colors.amber,
              ),
            )
            : const SizedBox.shrink();

    final kickButton =
        onKick != null
            ? IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: onKick,
            )
            : const SizedBox.shrink();

    final nameEdit =
        onNameChange != null
            ? IconButton(
              icon: const Icon(Icons.edit, size: 16),
              onPressed: onNameChange,
            )
            : const SizedBox.shrink();

    return ListTile(
      leading: point,
      title: Row(
        children: [
          Expanded(
            child: Text(
              player['name'] ?? 'Unbenannt',
              style: TextStyle(
                fontWeight: isOwnPlayer ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          crown,
          nameEdit,
          kickButton,
        ],
      ),
    );
  }
}
