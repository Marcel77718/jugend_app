import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/domain/viewmodels/friend_view_model.dart';
import 'package:jugend_app/data/models/friend.dart';
import 'package:jugend_app/data/models/friend_request.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String? _searchResultUid;
  String? _searchResultTag;
  String? _searchResultName;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
      _searchResultUid = user['uid'];
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
    // Definiere einen Timeout, nach dem ein User als offline gilt
    const int offlineTimeoutMinutes = 5;

    if (status == null)
      return Colors.red; // Standardmäßig offline, wenn kein Status gesetzt

    switch (status) {
      case 'online':
        // Prüfe lastActive für echten Online-Status
        final lastActive = userData?['lastActive'] as Timestamp?;
        if (lastActive != null &&
            DateTime.now().difference(lastActive.toDate()).inMinutes <=
                offlineTimeoutMinutes) {
          return Colors.green; // Online
        } else {
          return Colors.red; // Offline nach Timeout
        }
      case 'lobby':
        return Colors.blue;
      case 'game':
        return Colors.orange;
      default:
        return Colors.red; // Standardmäßig offline
    }
  }

  String _statusText(
    String? status,
    String? lobbyId,
    Map<String, dynamic>? userData,
  ) {
    // Definiere einen Timeout, nach dem ein User als offline gilt
    const int offlineTimeoutMinutes = 5;

    if (status == null)
      return 'Offline'; // Standardmäßig offline, wenn kein Status gesetzt

    // Wenn Status online ist, prüfen wir lastActive
    if (status == 'online') {
      final lastActive = userData?['lastActive'] as Timestamp?;
      if (lastActive != null &&
          DateTime.now().difference(lastActive.toDate()).inMinutes <=
              offlineTimeoutMinutes) {
        return 'Online'; // Online
      } else {
        return 'Offline'; // Offline nach Timeout
      }
    }

    switch (status) {
      case 'online':
        // Dieser Fall sollte durch die obige Prüfung abgedeckt sein, aber zur Sicherheit:
        return 'Online';
      case 'lobby':
        return 'In Lobby';
      case 'game':
        return 'Im Spiel';
      default:
        return 'Offline'; // Standardmäßig offline
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
            // Tab für Anfragen mit Badge
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
                          right: -15, // Passe die Position an
                          top: -5, // Passe die Position an
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
          // --- Freunde-Liste ---
          StreamBuilder<List<Friend>>(
            stream: viewModel.friendsStream,
            builder: (context, snapshot) {
              final friends = snapshot.data ?? [];
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: (friends.isEmpty ? 1 : friends.length + 1),
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
                                          : () =>
                                              _searchAndSendRequest(viewModel),
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
                  if (friends.isEmpty) {
                    return const Center(child: Text('Noch keine Freunde.'));
                  }
                  final friend = friends[i - 1];
                  return StreamBuilder<DocumentSnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(friend.friendUid)
                            .snapshots(),
                    builder: (context, snap) {
                      final data = snap.data?.data() as Map<String, dynamic>?;
                      final status = data?['status'] as String?;
                      final lobbyId = data?['currentLobbyId'] as String?;
                      final photoUrl = data?['photoUrl'] as String?;
                      return ListTile(
                        leading: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              backgroundImage:
                                  (photoUrl != null && photoUrl.isNotEmpty)
                                      ? NetworkImage(photoUrl)
                                      : const NetworkImage(
                                        'https://ui-avatars.com/api/?name=User',
                                      ),
                            ),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _statusColor(status, data),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                        title: Text('${friend.friendName}#${friend.friendTag}'),
                        subtitle: Text(_statusText(status, lobbyId, data)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (status == 'lobby' &&
                                lobbyId != null &&
                                lobbyId.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.login),
                                tooltip: 'Lobby beitreten',
                                onPressed: () {
                                  // Join-Logik: zur Lobby des Freundes gehen
                                  context.go(
                                    '/lobby',
                                    extra: {
                                      'lobbyId': lobbyId,
                                      'playerName':
                                          user.displayName ?? 'Unbekannt',
                                      'isHost': false,
                                      'gameType': 'Impostor', // TODO: auslesen
                                    },
                                  );
                                },
                              ),
                            if (status != 'game')
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                tooltip: 'Freund entfernen',
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text(
                                            'Freund entfernen?',
                                          ),
                                          content: Text(
                                            'Möchtest du ${friend.friendName} wirklich entfernen?',
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
                                    await viewModel.removeFriend(friend);
                                  }
                                },
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
