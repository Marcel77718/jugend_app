import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/friend_view_model.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModel = ref.watch(friendViewModelProvider);
    return Scaffold(
      appBar: AppBar(
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
            return Center(child: Text('Fehler: snapshot.error}'));
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
                leading: const CircleAvatar(),
                title: Text(friend.friendName),
                subtitle: Text('@friend.friendTag'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => viewModel.removeFriend(friend),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddFriendDialog(BuildContext context, FriendViewModel viewModel) {
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
                    final error = await viewModel.sendFriendRequest(
                      controller.text,
                      '',
                    );
                    if (context.mounted && error == null) {
                      Navigator.pop(context);
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
