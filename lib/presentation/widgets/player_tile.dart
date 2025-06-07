// Datei: lib/presentation/widgets/player_tile.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/services/image_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userDataProvider = StreamProvider.family<Map<String, dynamic>?, String>(
  (ref, uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()),
);

class PlayerTile extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final userUid = player['userUid'] as String?;
    final userData =
        userUid != null
            ? ref.watch(userDataProvider(userUid))
            : const AsyncValue.data(null);

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
          if (player['isReady'] == true)
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(left: 4),
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: userData.when(
              data: (data) {
                if (data == null) return const Text('...');
                final displayName = data['displayName'] ?? '';
                final tag = data['tag'] ?? '';
                return Text(
                  '$displayName${tag.isNotEmpty ? '#$tag' : ''}',
                  style: TextStyle(
                    fontWeight:
                        isOwnPlayer ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              },
              loading: () => const Text('...'),
              error:
                  (_, __) => Text(
                    player['name'] ?? 'Unbenannt',
                    style: TextStyle(
                      fontWeight:
                          isOwnPlayer ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
            ),
          ),
          if (player['id'] == hostId)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(Icons.star, color: Colors.amber, size: 20),
            ),
          if (isHost && player['id'] != hostId)
            IconButton(
              icon: const Icon(Icons.star_outline),
              onPressed: () {
                // Host-Transfer Logik
              },
            ),
          if (isHost && player['id'] != hostId)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                // Kick-Logik
              },
            ),
          if (!isOwnPlayer && userUid != null)
            IconButton(
              icon: const Icon(Icons.person_add_outlined),
              onPressed: () {
                // Freund hinzufügen Logik
              },
            ),
        ],
      ),
    );
  }
}
