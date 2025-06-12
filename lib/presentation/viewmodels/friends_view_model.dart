import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';

class FriendsViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream für die Freundesliste
  Stream<List<FriendViewModel>> get friendsStream {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
          final friends = <FriendViewModel>[];
          for (var doc in snapshot.docs) {
            final friendId = doc.id;
            final friendDoc =
                await _firestore.collection('users').doc(friendId).get();
            if (friendDoc.exists) {
              friends.add(FriendViewModel.fromFirestore(friendDoc));
            }
          }
          return friends;
        });
  }

  // Freund hinzufügen
  Future<void> addFriend(String friendTag) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Suche den Freund anhand des Tags
    final friendQuery =
        await _firestore
            .collection('users')
            .where('tag', isEqualTo: friendTag)
            .get();

    if (friendQuery.docs.isEmpty) {
      throw Exception('Freund nicht gefunden');
    }

    final friendId = friendQuery.docs.first.id;
    if (friendId == currentUserId) {
      throw Exception('Du kannst dich nicht selbst als Freund hinzufügen');
    }

    // Prüfe, ob der Freund bereits existiert
    final existingFriend =
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('friends')
            .doc(friendId)
            .get();

    if (existingFriend.exists) {
      throw Exception('Freund bereits hinzugefügt');
    }

    // Füge den Freund hinzu
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId)
        .set({'addedAt': FieldValue.serverTimestamp()});

    // Füge dich als Freund des anderen hinzu
    await _firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUserId)
        .set({'addedAt': FieldValue.serverTimestamp()});
  }

  // Freund entfernen
  Future<void> removeFriend(String friendId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Entferne den Freund
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId)
        .delete();

    // Entferne dich als Freund des anderen
    await _firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUserId)
        .delete();
  }

  // Lobby eines Freundes beitreten
  void joinFriendLobby(String lobbyId, BuildContext context) {
    context.go('/lobby/$lobbyId');
  }
}

class FriendViewModel {
  final String id;
  final String name;
  final String tag;
  final String status;
  final String? lobbyId;
  final DateTime? lastSeen;

  FriendViewModel({
    required this.id,
    required this.name,
    required this.tag,
    required this.status,
    this.lobbyId,
    this.lastSeen,
  });

  factory FriendViewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendViewModel(
      id: doc.id,
      name: data['name'] ?? '',
      tag: data['tag'] ?? '',
      status: data['status'] ?? 'offline',
      lobbyId: data['lobbyId'],
      lastSeen: data['lastSeen']?.toDate(),
    );
  }

  Color get statusColor {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'in_lobby':
        return Colors.orange;
      case 'in_game':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get statusText {
    switch (status) {
      case 'online':
        return 'Online';
      case 'in_lobby':
        return 'In Lobby';
      case 'in_game':
        return 'Im Spiel';
      default:
        return 'Offline';
    }
  }
}
