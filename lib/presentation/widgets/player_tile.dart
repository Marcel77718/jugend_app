// Datei: lib/presentation/widgets/player_tile.dart

import 'package:flutter/material.dart';

class PlayerTile extends StatelessWidget {
  final Map<String, dynamic> player;
  final bool isHost;
  final bool isOwnPlayer;
  final String? hostId;
  final VoidCallback? onKick;
  final VoidCallback? onNameChange;
  final VoidCallback? onHostTransfer;

  const PlayerTile({
    super.key,
    required this.player,
    required this.isHost,
    required this.isOwnPlayer,
    required this.hostId,
    this.onKick,
    this.onNameChange,
    this.onHostTransfer,
  });

  @override
  Widget build(BuildContext context) {
    final isReady = player['isReady'] == true;
    final isPlayerHost = player['id'] == hostId;

    final point = Icon(
      isPlayerHost
          ? (isReady ? Icons.circle : Icons.circle_outlined)
          : (isReady ? Icons.circle : Icons.circle_outlined),
      color: isPlayerHost ? Colors.blue : (isReady ? Colors.green : Colors.red),
      size: 12,
    );

    final crown =
        isPlayerHost
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

    final hostTransferButton =
        onHostTransfer != null
            ? IconButton(
              icon: const Icon(
                Icons.emoji_events,
                size: 16,
                color: Colors.amber,
              ),
              tooltip: 'Host übertragen',
              onPressed: onHostTransfer,
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
          hostTransferButton,
          kickButton,
        ],
      ),
    );
  }
}
