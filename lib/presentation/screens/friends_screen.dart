import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/domain/viewmodels/friend_view_model.dart';
import 'package:jugend_app/data/models/friend.dart';
import 'package:jugend_app/data/models/friend_request.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:jugend_app/services/image_service.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _uiUpdateTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Color _statusColor(String? status, Map<String, dynamic>? userData) {
    final lastActive = userData?['lastActive'] as Timestamp?;
    if (status == 'lobby') return Colors.blue;
    if (status == 'game') return Colors.orange;
    if (status == 'online' &&
        lastActive != null &&
        DateTime.now().difference(lastActive.toDate()).inMinutes < 2) {
      return Colors.green;
    }
    return Colors.red;
  }

  String _statusText(
    String? status,
    String? lobbyId,
    Map<String, dynamic>? userData,
  ) {
    final lastActive = userData?['lastActive'] as Timestamp?;
    if (status == 'lobby') return 'In Lobby';
    if (status == 'game') return 'Im Spiel';
    if (status == 'online' &&
        lastActive != null &&
        DateTime.now().difference(lastActive.toDate()).inMinutes < 2) {
      return 'Online';
    }
    return 'Offline';
  }

  void _onDeleteTap(BuildContext context, Friend friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Freund entfernen?'),
            content: Text(
              'Möchtest du ${friend.friendUid} wirklich entfernen?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Entfernen'),
              ),
            ],
          ),
    );
    if (confirm == true) {
      final viewModel = ref.watch(friendViewModelProvider);
      viewModel.removeFriend(friend);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);
    final user = auth.profile;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final viewModel = ref.watch(friendViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Freunde'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Freunde'),
            Tab(
              child: StreamBuilder<List<FriendRequest>>(
                stream: viewModel.requestsStream,
                builder: (context, snapshot) {
                  final requestCount = snapshot.data?.length ?? 0;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Text('Anfragen'),
                      if (requestCount > 0)
                        Positioned(
                          right: -15,
                          top: -5,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$requestCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<Friend>>(
            stream: viewModel.friendsStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Fehler beim Laden: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final friends = snapshot.data!;
              if (friends.isEmpty) {
                return const Center(child: Text('Keine Freunde gefunden.'));
              }

              return ListView.builder(
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(friend.friendUid)
                            .snapshots(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData || userSnap.data?.data() == null) {
                        return const Text('...');
                      }
                      final userData =
                          userSnap.data!.data() as Map<String, dynamic>;
                      final displayName = userData['displayName'] ?? '';
                      final tag = userData['tag'] ?? '';
                      final status = userData['status'] as String?;
                      final lobbyId = userData['currentLobbyId'] as String?;
                      final photoUrl = userData['photoUrl'] as String?;
                      return ListTile(
                        leading: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            GestureDetector(
                              onTap: () {
                                final imageUrl =
                                    (photoUrl != null && photoUrl.isNotEmpty)
                                        ? photoUrl
                                        : 'https://ui-avatars.com/api/?name=User';
                                showDialog(
                                  context: context,
                                  builder:
                                      (context) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: GestureDetector(
                                          onTap:
                                              () => Navigator.of(context).pop(),
                                          child: InteractiveViewer(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
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
                                backgroundImage:
                                    (photoUrl != null && photoUrl.isNotEmpty)
                                        ? NetworkImage(photoUrl)
                                        : const NetworkImage(
                                          'https://ui-avatars.com/api/?name=User',
                                        ),
                              ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _statusColor(status, userData),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text(
                          displayName + (tag.isNotEmpty ? '#$tag' : ''),
                        ),
                        subtitle: Text(_statusText(status, lobbyId, userData)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _onDeleteTap(context, friend),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
          StreamBuilder<List<FriendRequest>>(
            stream: viewModel.requestsStream,
            builder: (context, snapshot) {
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return const Center(child: Text('Keine Anfragen.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, _) => const Divider(),
                itemBuilder: (context, i) {
                  final req = requests[i];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text('${req.fromName}#${req.fromTag}'),
                    subtitle: Text('Anfrage erhalten'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          tooltip: 'Annehmen',
                          onPressed: () async {
                            await viewModel.acceptRequest(
                              req,
                              user.displayName ?? '',
                              user.tag,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          tooltip: 'Ablehnen',
                          onPressed: () async {
                            await viewModel.declineRequest(req);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
