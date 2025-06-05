import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/data/models/friend.dart';
import 'package:jugend_app/data/models/friend_request.dart';
import 'package:async/async.dart';

class FriendService {
  final FirebaseFirestore _firestore;
  FriendService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference getUserFriendsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('friends');
  CollectionReference getUserRequestsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('friendRequests');

  // Freunde laden
  Stream<List<Friend>> friendsStream(String uid) {
    return getUserFriendsRef(uid)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) =>
                        Friend.fromJson(doc.data() as Map<String, dynamic>),
                  )
                  .toList(),
        );
  }

  // Freundschaftsanfragen laden
  Stream<List<FriendRequest>> requestsStream(String uid) {
    return getUserRequestsRef(
      uid,
    ).where('status', isEqualTo: 'pending').snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => FriendRequest.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    });
  }

  // Anfrage senden
  Future<void> sendRequest({
    required String fromUid,
    required String fromName,
    required String fromTag,
    required String toUid,
  }) async {
    final request = FriendRequest(
      fromUid: fromUid,
      fromName: fromName,
      fromTag: fromTag,
      status: 'pending',
      timestamp: DateTime.now(),
    );
    await getUserRequestsRef(toUid).doc(fromUid).set(request.toJson());
  }

  // Anfrage annehmen
  Future<void> acceptRequest({
    required String myUid,
    required String requesterUid,
    required String requesterName,
    required String requesterTag,
    required String myName,
    required String myTag,
  }) async {
    // Setze Anfrage auf "accepted"
    await getUserRequestsRef(
      myUid,
    ).doc(requesterUid).update({'status': 'accepted'});
    // Füge Freund bei beiden hinzu
    final now = DateTime.now();
    await getUserFriendsRef(myUid)
        .doc(requesterUid)
        .set(
          Friend(
            friendUid: requesterUid,
            friendName: requesterName,
            friendTag: requesterTag,
            status: 'accepted',
            hinzugefuegtAm: now,
          ).toJson(),
        );
    await getUserFriendsRef(requesterUid)
        .doc(myUid)
        .set(
          Friend(
            friendUid: myUid,
            friendName: myName,
            friendTag: myTag,
            status: 'accepted',
            hinzugefuegtAm: now,
          ).toJson(),
        );
  }

  // Anfrage ablehnen
  Future<void> declineRequest({
    required String myUid,
    required String requesterUid,
  }) async {
    await getUserRequestsRef(
      myUid,
    ).doc(requesterUid).update({'status': 'declined'});
  }

  // Freund entfernen
  Future<void> removeFriend({
    required String myUid,
    required String friendUid,
  }) async {
    await getUserFriendsRef(myUid).doc(friendUid).delete();
    await getUserFriendsRef(friendUid).doc(myUid).delete();
  }

  // Lade mehrere User-Profile auf einmal
  Future<Map<String, Map<String, dynamic>>> loadUserProfiles(
    List<String> uids,
  ) async {
    final Map<String, Map<String, dynamic>> profiles = {};

    // Teile die UIDs in Chunks von maximal 10 auf
    for (var i = 0; i < uids.length; i += 10) {
      final end = (i + 10 < uids.length) ? i + 10 : uids.length;
      final chunk = uids.sublist(i, end);

      final query =
          await _firestore
              .collection('users')
              .where(FieldPath.documentId, whereIn: chunk)
              .get();

      for (var doc in query.docs) {
        profiles[doc.id] = doc.data();
      }
    }

    return profiles;
  }

  // Stream-Variante: Gebündelte User-Profile als Stream
  Stream<Map<String, Map<String, dynamic>>> userProfilesStream(
    List<String> uids,
  ) async* {
    // Teile die UIDs in Chunks von maximal 10 auf
    final List<Stream<QuerySnapshot>> streams = [];
    for (var i = 0; i < uids.length; i += 10) {
      final end = (i + 10 < uids.length) ? i + 10 : uids.length;
      final chunk = uids.sublist(i, end);
      streams.add(
        _firestore
            .collection('users')
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots(),
      );
    }
    await for (final snapshots in StreamZip(streams)) {
      final Map<String, Map<String, dynamic>> profiles = {};
      for (final snap in snapshots) {
        for (final doc in snap.docs) {
          profiles[doc.id] = doc.data() as Map<String, dynamic>;
        }
      }
      yield profiles;
    }
  }
}
