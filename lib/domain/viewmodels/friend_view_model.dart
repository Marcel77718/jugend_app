import 'package:flutter/material.dart';
import 'package:jugend_app/data/models/friend.dart';
import 'package:jugend_app/data/models/friend_request.dart';
import 'package:jugend_app/data/services/friend_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:jugend_app/domain/viewmodels/auth_view_model.dart';

class FriendViewModel extends ChangeNotifier {
  final FriendService _service;
  final String myUid;
  final String myName;
  final String myTag;

  // Map für alle Freund-Profile
  Map<String, Map<String, dynamic>> _friendProfiles = {};
  Map<String, Map<String, dynamic>> get friendProfiles => _friendProfiles;

  // Lade- und Fehlerzustand
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  String? _error;
  String? get error => _error;

  // Stream für Profile-Updates
  Stream<Map<String, Map<String, dynamic>>>? _friendProfilesStream;
  Stream<Map<String, Map<String, dynamic>>>? get friendProfilesStream =>
      _friendProfilesStream;
  StreamSubscription? _profilesSubscription;

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

  // Lade alle Freund-Profile auf einmal
  Future<void> fetchAllFriendProfiles() async {
    final friends = await _service.friendsStream(myUid).first;
    final uids = friends.map((f) => f.friendUid).toList();
    _friendProfiles = await _service.loadUserProfiles(uids);
    notifyListeners();
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

  void listenToFriendProfiles() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final friends = await _service.friendsStream(myUid).first;
      final uids = friends.map((f) => f.friendUid).toList();
      if (uids.isEmpty) {
        _friendProfiles = {};
        _isLoading = false;
        notifyListeners();
        return;
      }
      _profilesSubscription?.cancel();
      _friendProfilesStream = _service.userProfilesStream(uids);
      _profilesSubscription = _friendProfilesStream!.listen(
        (profiles) {
          _friendProfiles = profiles;
          _isLoading = false;
          notifyListeners();
        },
        onError: (e) {
          _error = e.toString();
          _isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _profilesSubscription?.cancel();
    super.dispose();
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
