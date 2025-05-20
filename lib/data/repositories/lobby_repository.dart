import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/data/models/reconnect_data.dart';

abstract class ILobbyRepository {
  Future<bool> lobbyExists(String lobbyId);
  Future<void> createLobby(String lobbyId, String gameType);
  Future<void> addPlayer({
    required String lobbyId,
    required String name,
    required String deviceId,
    required bool isHost,
  });
  Future<bool> isNameTaken(String lobbyId, String name);
  Future<void> updateLobbyActivity(String lobbyId);
  Future<void> updatePlayerActivity(String lobbyId, String deviceId);
  Future<void> updatePlayerName(
    String lobbyId,
    String deviceId,
    String newName,
  );
  Future<void> deleteLobby(String lobbyId);
  Future<ReconnectData?> getReconnectData(String deviceId);
  Future<void> saveReconnectData(String deviceId, ReconnectData data);
  Future<void> clearReconnectData(String deviceId);
}

class LobbyRepository implements ILobbyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration lobbyTimeout = Duration(hours: 24);

  DocumentReference lobbyRef(String lobbyId) =>
      _firestore.collection('lobbies').doc(lobbyId);

  CollectionReference playersRef(String lobbyId) =>
      lobbyRef(lobbyId).collection('players');

  @override
  Future<bool> lobbyExists(String lobbyId) async {
    final doc = await lobbyRef(lobbyId).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      final lastActivity = data['lastActivity'] as Timestamp?;
      if (lastActivity != null) {
        final timeSinceLastActivity = DateTime.now().difference(
          lastActivity.toDate(),
        );
        if (timeSinceLastActivity > lobbyTimeout) {
          await deleteLobby(lobbyId);
          return false;
        }
      }
    }
    return true;
  }

  @override
  Future<void> createLobby(String lobbyId, String gameType) async {
    await lobbyRef(lobbyId).set({
      'gameType': gameType,
      'status': 'waiting',
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'playerCount': 0,
      'metadata': {'totalGamesPlayed': 0, 'lastGameFinished': null},
    });
  }

  @override
  Future<void> addPlayer({
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
      'lastActive': FieldValue.serverTimestamp(),
      'id': deviceId,
      'metadata': {'gamesPlayed': 0, 'wins': 0, 'totalPlayTime': 0},
    });
    await lobbyRef(lobbyId).update({
      'playerCount': FieldValue.increment(1),
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<bool> isNameTaken(String lobbyId, String name) async {
    final snapshot =
        await playersRef(lobbyId).where('name', isEqualTo: name).get();
    return snapshot.docs.isNotEmpty;
  }

  @override
  Future<void> updateLobbyActivity(String lobbyId) async {
    await lobbyRef(
      lobbyId,
    ).update({'lastActivity': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> updatePlayerActivity(String lobbyId, String deviceId) async {
    await playersRef(
      lobbyId,
    ).doc(deviceId).update({'lastActive': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> updatePlayerName(
    String lobbyId,
    String deviceId,
    String newName,
  ) async {
    await playersRef(lobbyId).doc(deviceId).update({
      'name': newName,
      'lastActive': FieldValue.serverTimestamp(),
    });
    await updateLobbyActivity(lobbyId);
  }

  @override
  Future<void> deleteLobby(String lobbyId) async {
    final players = await playersRef(lobbyId).get();
    for (var player in players.docs) {
      await player.reference.delete();
    }
    await lobbyRef(lobbyId).delete();
    final reconnectDocs =
        await _firestore
            .collection('reconnect')
            .where('lobbyId', isEqualTo: lobbyId)
            .get();
    for (var doc in reconnectDocs.docs) {
      await doc.reference.delete();
    }
  }

  // Reconnect-Logik
  @override
  Future<ReconnectData?> getReconnectData(String deviceId) async {
    final doc = await _firestore.collection('reconnect').doc(deviceId).get();
    if (doc.exists && doc.data() != null) {
      final data = ReconnectData.fromMap(doc.data()!);
      final exists = await lobbyExists(data.lobbyId);
      if (!exists) {
        await clearReconnectData(deviceId);
        return null;
      }
      return data;
    }
    return null;
  }

  @override
  Future<void> saveReconnectData(String deviceId, ReconnectData data) async {
    await _firestore.collection('reconnect').doc(deviceId).set(data.toMap());
  }

  @override
  Future<void> clearReconnectData(String deviceId) async {
    await _firestore.collection('reconnect').doc(deviceId).delete();
  }
}
