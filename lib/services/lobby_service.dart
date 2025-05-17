// 📁 Datei: lib/services/lobby_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class LobbyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static DocumentReference lobbyRef(String lobbyId) =>
      _firestore.collection('lobbies').doc(lobbyId);

  static CollectionReference playersRef(String lobbyId) =>
      lobbyRef(lobbyId).collection('players');

  static Future<bool> lobbyExists(String lobbyId) async {
    final doc = await lobbyRef(lobbyId).get();
    return doc.exists;
  }

  static Future<bool> isNameTaken(String lobbyId, String name) async {
    final snapshot =
        await playersRef(lobbyId).where('name', isEqualTo: name).get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> createLobby(String lobbyId, String gameType) async {
    await lobbyRef(lobbyId).set({'gameType': gameType, 'status': 'waiting'});
  }

  static Future<void> addPlayer({
    required String lobbyId,
    required String name,
    required String deviceId,
    required bool isHost,
  }) async {
    await playersRef(lobbyId).doc(deviceId).set({
      'name': name,
      'deviceId': deviceId,
      'isHost': isHost,
      'isReady': false,
      'joinedAt': FieldValue.serverTimestamp(),
      'id': deviceId,
    });
  }

  static Future<void> updatePlayerName(
    String lobbyId,
    String deviceId,
    String newName,
  ) async {
    await playersRef(lobbyId).doc(deviceId).set({
      'name': newName,
      'id': deviceId,
    }, SetOptions(merge: true));
  }

  static Future<DocumentSnapshot> getLobbySnapshot(String lobbyId) async {
    return await lobbyRef(lobbyId).get();
  }
}
