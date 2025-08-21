import 'package:flutter/material.dart';
import 'package:jugend_app/data/models/friend.dart';
import 'package:jugend_app/data/models/friend_request.dart';
import 'package:jugend_app/data/services/friend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';
import 'package:jugend_app/data/repositories/lobby_repository.dart';

class FriendViewModel extends ChangeNotifier {
  final FriendService _service;
  final String myUid;
  final String myName;
  final String myTag;

  FriendViewModel({
    required this.myUid,
    required this.myName,
    required this.myTag,
    FriendService? service,
  }) : _service = service ?? FriendService();

  Stream<List<Friend>> get friendsStream => _service.friendsStream(myUid);
  Stream<List<FriendRequest>> get requestsStream =>
      _service.requestsStream(myUid);

  // Neue Methode, um die Anzahl der Anfragen als Stream bereitzustellen
  Stream<int> get pendingRequestCountStream =>
      _service.requestsStream(myUid).map((list) {
        return list.length;
      });

  // Stream für den Status eines Freundes
  Stream<Map<String, dynamic>> getFriendStatusStream(String friendUid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(friendUid)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            return {'status': 'offline', 'currentLobbyId': null};
          }
          final data = doc.data()!;
          return {
            'status': data['status'] ?? 'offline',
            'currentLobbyId': data['currentLobbyId'],
          };
        });
  }

  // Prüfe ob eine Lobby existiert
  Future<bool> checkLobbyExists(String lobbyId) async {
    return await LobbyRepository().lobbyExists(lobbyId);
  }

  // Suche nach User per Name#Tag
  Future<Map<String, dynamic>?> searchUser(String name, String tag) async {
    final query =
        await FirebaseFirestore.instance
            .collection('users')
            .where('displayName', isEqualTo: name)
            .where('tag', isEqualTo: tag)
            .limit(1)
            .get();
    if (query.docs.isEmpty) return null;
    final data = query.docs.first.data();
    return {'uid': query.docs.first.id, ...data};
  }

  // Anfrage senden
  Future<String?> sendFriendRequest(String toName, String toTag) async {
    final user = await searchUser(toName, toTag);
    if (user == null) return 'Nutzer nicht gefunden';
    if (user['uid'] == myUid) return 'Du kannst dich nicht selbst adden!';
    await _service.sendRequest(
      fromUid: myUid,
      fromName: myName,
      fromTag: myTag,
      toUid: user['uid'],
    );
    return null;
  }

  // Anfrage annehmen
  Future<void> acceptRequest(
    FriendRequest req,
    String myName,
    String myTag,
  ) async {
    await _service.acceptRequest(
      myUid: myUid,
      requesterUid: req.fromUid,
      requesterName: req.fromName,
      requesterTag: req.fromTag,
      myName: myName,
      myTag: myTag,
    );
  }

  // Anfrage ablehnen
  Future<void> declineRequest(FriendRequest req) async {
    await _service.declineRequest(myUid: myUid, requesterUid: req.fromUid);
  }

  // Freund entfernen
  Future<void> removeFriend(Friend friend) async {
    await _service.removeFriend(myUid: myUid, friendUid: friend.friendUid);
  }
}

// Ändere den Provider, damit er auf den AuthState reagiert
final friendViewModelProvider = Provider<FriendViewModel>((ref) {
  final authState = ref.watch(authViewModelProvider);

  // Liefere einen ViewModel mit korrekten Daten, wenn der User eingeloggt ist
  if (authState.status == AuthStatus.signedIn && authState.profile != null) {
    return FriendViewModel(
      myUid: authState.profile!.uid,
      myName: authState.profile!.displayName ?? '',
      myTag: authState.profile!.tag,
      // Füge hier ggf. weitere benötigte Repos/Services hinzu, falls nötig
    );
  } else {
    // Liefere eine Dummy-Instanz oder null, wenn der User nicht eingeloggt ist
    // Eine Dummy-Instanz ist besser, da sie keine null-Checks erfordert
    return FriendViewModel(
      myUid: '', // Leere UID, Streams werden in diesem Fall keine Daten liefern
      myName: '',
      myTag: '',
    );
  }
});
