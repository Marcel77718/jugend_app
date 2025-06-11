// Datei: lib/presentation/widgets/player_tile.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/core/performance_monitor.dart';

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

    return PerformanceWidget(
      name: 'PlayerTile_${player['name']}',
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
            userData.when(
              data:
                  (data) =>
                      data?['photoUrl'] ??
                      player['photoUrl'] ??
                      'https://ui-avatars.com/api/?name=${player['name']}',
              loading:
                  () =>
                      player['photoUrl'] ??
                      'https://ui-avatars.com/api/?name=${player['name']}',
              error:
                  (_, _) =>
                      'https://ui-avatars.com/api/?name=${player['name']}',
            ),
          ),
        ),
        title: Text(
          userData.when(
            data: (data) => data?['displayName'] ?? player['name'],
            loading: () => player['name'],
            error: (_, _) => player['name'],
          ),
        ),
        subtitle: Text(
          userData.when(
            data: (data) => data?['tag'] ?? '',
            loading: () => '',
            error: (_, _) => '',
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isHost && !isOwnPlayer && onKick != null)
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: onKick,
                tooltip: 'Spieler entfernen',
              ),
            if (isHost && !isOwnPlayer && onHostTransfer != null)
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: onHostTransfer,
                tooltip: 'Host-Rechte übertragen',
              ),
            if (showAddFriend && onAddFriend != null)
              IconButton(
                icon: const Icon(Icons.person_add_outlined),
                onPressed: onAddFriend,
                tooltip: 'Als Freund hinzufügen',
              ),
          ],
        ),
      ),
    );
  }
}
