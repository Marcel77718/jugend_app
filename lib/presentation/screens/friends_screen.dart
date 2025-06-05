import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/domain/viewmodels/friend_view_model.dart';
import 'package:jugend_app/data/models/friend.dart';
import 'package:jugend_app/data/models/friend_request.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';
import 'dart:async';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String? _searchError;
  bool _isSearching = false;
  String? _searchResult;
  String? _searchResultTag;
  String? _searchResultName;
  bool _requestSent = false;
  Timer? _uiUpdateTimer;
  bool _joinCooldown = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = ref.read(friendViewModelProvider);
      viewModel.listenToFriendProfiles();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _uiUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _searchAndSendRequest(FriendViewModel viewModel) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
      _searchResult = null;
      _requestSent = false;
    });
    final input = _searchController.text.trim();
    final parts = input.split('#');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      setState(() {
        _searchError = 'Bitte Name#Tag eingeben (z.B. Kevin#1234)';
        _isSearching = false;
      });
      return;
    }
    final name = parts[0];
    final tag = parts[1];
    final user = await viewModel.searchUser(name, tag);
    if (user == null) {
      setState(() {
        _searchError = 'Nutzer nicht gefunden';
        _isSearching = false;
      });
      return;
    }
    setState(() {
      _searchResult = '$name#$tag';
      _searchResultName = name;
      _searchResultTag = tag;
      _isSearching = false;
    });
  }

  Future<void> _sendRequest(FriendViewModel viewModel) async {
    if (_searchResultName == null || _searchResultTag == null) return;
    final error = await viewModel.sendFriendRequest(
      _searchResultName!,
      _searchResultTag!,
    );
    if (error != null) {
      setState(() {
        _searchError = error;
        _requestSent = false;
      });
    } else {
      setState(() {
        _requestSent = true;
      });
    }
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

  void _startJoinCooldown() {
    setState(() {
      _joinCooldown = true;
    });
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          _joinCooldown = false;
        });
      }
    });
  }

  Future<void> _refreshFriends(FriendViewModel viewModel) async {
    viewModel.listenToFriendProfiles();
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
                          right: -8,
                          top: -8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              requestCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
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
          // --- Freunde-Liste ---
          RefreshIndicator(
            onRefresh: () => _refreshFriends(viewModel),
            child: StreamBuilder<Map<String, Map<String, dynamic>>>(
              stream: viewModel.friendProfilesStream,
              builder: (context, snapshot) {
                if (viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (viewModel.error != null) {
                  return Center(child: Text('Fehler: ${viewModel.error}'));
                }
                final profiles = snapshot.data ?? viewModel.friendProfiles;
                final friends = profiles.entries.toList();
                if (friends.isEmpty) {
                  return const Center(child: Text('Noch keine Freunde.'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: friends.length + 1,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, i) {
                    if (i == 0) {
                      // Suchfeld immer anzeigen
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Freund hinzufügen'),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      decoration: InputDecoration(
                                        hintText: 'Name#Tag',
                                        errorText: _searchError,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed:
                                        _isSearching
                                            ? null
                                            : () => _searchAndSendRequest(
                                              viewModel,
                                            ),
                                    child:
                                        _isSearching
                                            ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                            : const Icon(Icons.search),
                                  ),
                                ],
                              ),
                              if (_searchResult != null && !_requestSent)
                                Row(
                                  children: [
                                    Text('Gefunden: $_searchResult'),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _sendRequest(viewModel),
                                      child: const Text('Anfrage senden'),
                                    ),
                                  ],
                                ),
                              if (_requestSent)
                                const Text(
                                  'Anfrage gesendet!',
                                  style: TextStyle(color: Colors.green),
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                    final entry = friends[i - 1];
                    final userData = entry.value;
                    final displayName = userData['displayName'] ?? '';
                    final tag = userData['tag'] ?? '';
                    final status = userData['status'] as String?;
                    final lobbyId = userData['currentLobbyId'] as String?;
                    final photoUrl = userData['photoUrl'] as String?;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            photoUrl != null ? NetworkImage(photoUrl) : null,
                        child:
                            photoUrl == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text('$displayName#$tag'),
                      subtitle: Text(_statusText(status, lobbyId, userData)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _statusColor(status, userData),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (status == 'lobby' && !_joinCooldown)
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              tooltip: 'Lobby beitreten',
                              onPressed: () {
                                _startJoinCooldown();
                                context.go(
                                  '/lobby',
                                  extra: ReconnectData(
                                    lobbyId: lobbyId ?? '',
                                    playerName: user.displayName ?? 'Unbekannt',
                                    isHost: false,
                                    gameType:
                                        userData['gameType'] ?? 'Impostor',
                                  ),
                                );
                              },
                            ),
                          if (status != 'game')
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Freund entfernen',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text('Freund entfernen?'),
                                        content: Text(
                                          'Möchtest du $displayName wirklich entfernen?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                            child: const Text('Abbrechen'),
                                          ),
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                            child: const Text('Entfernen'),
                                          ),
                                        ],
                                      ),
                                );
                                if (confirm == true) {
                                  await viewModel.removeFriend(
                                    Friend(
                                      friendUid: entry.key,
                                      friendName: displayName,
                                      friendTag: tag,
                                      status: status ?? '',
                                      hinzugefuegtAm: DateTime.now(),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // --- Anfragen ---
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
                separatorBuilder: (_, __) => const Divider(),
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
