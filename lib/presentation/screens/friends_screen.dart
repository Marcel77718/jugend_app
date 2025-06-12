import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/friends_view_model.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FriendsViewModel(),
      child: const FriendsScreenContent(),
    );
  }
}

class FriendsScreenContent extends StatelessWidget {
  const FriendsScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FriendsViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Freunde'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => _showAddFriendDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<List<FriendViewModel>>(
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
              return ListTile(
                leading: CircleAvatar(backgroundColor: friend.statusColor),
                title: Text(friend.name),
                subtitle: Text('@${friend.tag} - ${friend.statusText}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (friend.status == 'in_lobby' && friend.lobbyId != null)
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed:
                            () => viewModel.joinFriendLobby(
                              friend.lobbyId!,
                              context,
                            ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => viewModel.removeFriend(friend.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context) {
    final viewModel = context.read<FriendsViewModel>();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Freund hinzufügen'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Freund-Tag',
                hintText: 'z.B. #1234',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await viewModel.addFriend(controller.text);
                    if (context.mounted) Navigator.pop(context);
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
