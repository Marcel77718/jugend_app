// Datei: lib/presentation/widgets/player_tile.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/services/image_service.dart';

class PlayerTile extends StatelessWidget {
  final Map<String, dynamic> player;
  final bool isHost;
  final bool isOwnPlayer;
  final String? hostId;
  final VoidCallback? onKick;
  final VoidCallback? onNameChange;
  final VoidCallback? onHostTransfer;
  final bool showAddFriend;
  final VoidCallback? onAddFriend;

  const PlayerTile({
    super.key,
    required this.player,
    required this.isHost,
    required this.isOwnPlayer,
    required this.hostId,
    this.onKick,
    this.onNameChange,
    this.onHostTransfer,
    this.showAddFriend = false,
    this.onAddFriend,
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

    final addFriendButton =
        showAddFriend && onAddFriend != null
            ? IconButton(
              icon: const Icon(Icons.person_add, color: Colors.teal, size: 18),
              tooltip: 'Als Freund hinzufügen',
              onPressed: onAddFriend,
            )
            : const SizedBox.shrink();

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              final imageUrl =
                  (player['photoUrl'] != null &&
                          player['photoUrl'].toString().isNotEmpty)
                      ? player['photoUrl']
                      : 'https://ui-avatars.com/api/?name=User';
              showDialog(
                context: context,
                builder:
                    (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: InteractiveViewer(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ImageService.instance
                                .getOptimizedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                  errorWidget: const Icon(
                                    Icons.account_circle,
                                    size: 120,
                                  ),
                                ),
                          ),
                        ),
                      ),
                    ),
              );
            },
            child: CircleAvatar(
              radius: 16,
              backgroundImage:
                  (player['photoUrl'] != null &&
                          player['photoUrl'].toString().isNotEmpty)
                      ? NetworkImage(player['photoUrl'])
                      : const NetworkImage(
                        'https://ui-avatars.com/api/?name=User',
                      ),
              child: null,
            ),
          ),
          const SizedBox(width: 6),
          point,
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child:
                player['userUid'] != null &&
                        (player['userUid'] as String).isNotEmpty
                    ? StreamBuilder(
                      stream:
                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(player['userUid'])
                              .snapshots(),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data?.data() == null) {
                          return const Text('...');
                        }
                        final userData =
                            snap.data!.data() as Map<String, dynamic>;
                        final displayName = userData['displayName'] ?? '';
                        final tag = userData['tag'] ?? '';
                        return Text(
                          '$displayName${tag.isNotEmpty ? '#$tag' : ''}',
                          style: TextStyle(
                            fontWeight:
                                isOwnPlayer
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                          ),
                        );
                      },
                    )
                    : Text(
                      player['name'] ?? 'Unbenannt',
                      style: TextStyle(
                        fontWeight:
                            isOwnPlayer ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
          ),
          crown,
          nameEdit,
          hostTransferButton,
          kickButton,
          addFriendButton,
        ],
      ),
    );
  }
}
