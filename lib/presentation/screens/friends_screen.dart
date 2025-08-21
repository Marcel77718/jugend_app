import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/friend_view_model.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';
import 'package:jugend_app/data/services/reconnect_service.dart';
import 'package:jugend_app/core/app_routes.dart';
import 'package:jugend_app/data/providers/user_providers.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(friendViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/')),
        title: const Text('Freunde'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(context, viewModel),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: viewModel.friendsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fehler: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final friends = snapshot.data!;
          if (friends.isEmpty) {
            return const Center(child: Text('Keine Freunde gefunden'));
          }
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return _FriendTile(friend: friend, viewModel: viewModel);
            },
          );
        },
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, FriendViewModel viewModel) {
    final nameController = TextEditingController();
    final tagController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Freund hinzufügen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'z.B. Max',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagController,
                  decoration: const InputDecoration(
                    labelText: 'Tag',
                    hintText: 'z.B. 1234',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final error = await viewModel.sendFriendRequest(
                      nameController.text.trim(),
                      tagController.text.trim(),
                    );
                    if (context.mounted && error == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Freundschaftsanfrage gesendet'),
                        ),
                      );
                    }
                    if (context.mounted && error != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(error)));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(e.toString())));
                    }
                  }
                },
                child: const Text('Hinzufügen'),
              ),
            ],
          ),
    );
  }
}

class _FriendTile extends ConsumerWidget {
  final dynamic friend;
  final FriendViewModel viewModel;

  const _FriendTile({required this.friend, required this.viewModel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: viewModel.getFriendStatusStream(friend.friendUid),
      builder: (context, statusSnapshot) {
        final statusData =
            statusSnapshot.data ??
            {'status': 'offline', 'currentLobbyId': null};
        final status = statusData['status'] as String? ?? 'offline';
        final currentLobbyId = statusData['currentLobbyId'] as String?;
        final isInGame = status == 'game';
        final isInLobby = status == 'lobby';

        return Consumer(
          builder: (context, ref, _) {
            final userData = ref.watch(userDataProvider(friend.friendUid));
            final photoUrl = userData.when(
              data: (d) => d?['photoUrl'] as String?,
              loading: () => null,
              error: (_, __) => null,
            );
            return ListTile(
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundImage: NetworkImage(
                      photoUrl ??
                          'https://ui-avatars.com/api/?name=${friend.friendName}',
                    ),
                    radius: 25,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(friend.friendName),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('@${friend.friendTag}'),
                  Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isInLobby && currentLobbyId != null)
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.blue),
                      onPressed:
                          () => _joinFriendLobby(
                            context,
                            ref,
                            currentLobbyId,
                            friend.friendName,
                          ),
                      tooltip: 'Lobby beitreten',
                    ),
                  if (isInGame)
                    const Icon(Icons.sports_esports, color: Colors.orange),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showRemoveFriendDialog(context, friend),
                    tooltip: 'Freund entfernen',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'offline':
        return Colors.red;
      case 'lobby':
        return Colors.blue;
      case 'game':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'lobby':
        return 'In Lobby';
      case 'game':
        return 'Im Spiel';
      default:
        return 'Unbekannt';
    }
  }

  Future<void> _joinFriendLobby(
    BuildContext context,
    WidgetRef ref,
    String lobbyId,
    String friendName,
  ) async {
    try {
      // Prüfe ob Lobby existiert
      final exists = await viewModel.checkLobbyExists(lobbyId);
      if (!exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lobby existiert nicht mehr')),
          );
        }
        return;
      }

      // Hole User-Info für Lobby-Join
      final authState = ref.read(authViewModelProvider);
      final userName = authState.profile?.displayName ?? 'Unbekannt';

      final reconnectData = ReconnectData(
        lobbyId: lobbyId,
        playerName: userName,
        isHost: false,
        gameType: 'Impostor', // Standard, könnte später dynamisch sein
      );

      final reconnectService = ReconnectService();
      await reconnectService.registerReconnectData(reconnectData);

      if (context.mounted) {
        context.go(AppRoutes.lobby, extra: reconnectData);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Beitreten: ${e.toString()}')),
        );
      }
    }
  }

  void _showRemoveFriendDialog(BuildContext context, dynamic friend) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Freund entfernen'),
            content: Text(
              'Möchtest du ${friend.friendName} wirklich aus deiner Freundesliste entfernen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await viewModel.removeFriend(friend);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Freund entfernt')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler: ${e.toString()}')),
                      );
                    }
                  }
                },
                child: const Text('Entfernen'),
              ),
            ],
          ),
    );
  }
}
