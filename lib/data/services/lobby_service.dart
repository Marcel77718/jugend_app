// 📁 Datei: lib/data/services/lobby_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum LobbyStatus {
  waiting, // Lobby wartet auf Spieler
  inGame, // Spiel läuft
  paused, // Spiel pausiert
  finished, // Spiel beendet
}

class LobbyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Duration lobbyTimeout = Duration(hours: 24);

  static DocumentReference lobbyRef(String lobbyId) =>
      _firestore.collection('lobbies').doc(lobbyId);

  static CollectionReference playersRef(String lobbyId) =>
      lobbyRef(lobbyId).collection('players');

  static Future<bool> lobbyExists(String lobbyId) async {
    final doc = await lobbyRef(lobbyId).get();
    if (!doc.exists) return false;

    // Prüfe Timeout
    final data = doc.data() as Map<String, dynamic>?;
    if (data != null) {
      final lastActivity = data['lastActivity'] as Timestamp?;
      if (lastActivity != null) {
        final timeSinceLastActivity = DateTime.now().difference(
          lastActivity.toDate(),
        );
        if (timeSinceLastActivity > lobbyTimeout) {
          // Lösche die Lobby, wenn sie zu alt ist
          await deleteLobby(lobbyId);
          return false;
        }
      }
    }
    return true;
  }

  static Future<void> updateLobbyActivity(String lobbyId) async {
    await lobbyRef(
      lobbyId,
    ).update({'lastActivity': FieldValue.serverTimestamp()});
  }

  static Future<void> deleteLobby(String lobbyId) async {
    // Lösche alle Spieler
    final players = await playersRef(lobbyId).get();
    for (var player in players.docs) {
      await player.reference.delete();
    }

    // Lösche die Lobby selbst
    await lobbyRef(lobbyId).delete();

    // Lösche zugehörige Reconnect-Daten
    final reconnectDocs =
        await _firestore
            .collection('reconnect')
            .where('lobbyId', isEqualTo: lobbyId)
            .get();

    for (var doc in reconnectDocs.docs) {
      await doc.reference.delete();
    }
  }

  static Future<bool> isNameTaken(String lobbyId, String name) async {
    final snapshot =
        await playersRef(lobbyId).where('name', isEqualTo: name).get();
    return snapshot.docs.isNotEmpty;
  }

  static Future<void> createLobby(String lobbyId, String gameType) async {
    await lobbyRef(lobbyId).set({
      'gameType': gameType,
      'status': LobbyStatus.waiting.name,
      'createdAt': FieldValue.serverTimestamp(),
      'lastActivity': FieldValue.serverTimestamp(),
      'playerCount': 0,
      'metadata': {'totalGamesPlayed': 0, 'lastGameFinished': null},
    });
  }

  static Future<void> updateLobbyStatus(
    String lobbyId,
    LobbyStatus status,
  ) async {
    await lobbyRef(lobbyId).update({
      'status': status.name,
      'lastActivity': FieldValue.serverTimestamp(),
    });
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
      'lastActive': FieldValue.serverTimestamp(),
      'id': deviceId,
      'metadata': {'gamesPlayed': 0, 'wins': 0, 'totalPlayTime': 0},
    });

    // Aktualisiere Spielerzahl
    await lobbyRef(lobbyId).update({
      'playerCount': FieldValue.increment(1),
      'lastActivity': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updatePlayerActivity(
    String lobbyId,
    String deviceId,
  ) async {
    await playersRef(
      lobbyId,
    ).doc(deviceId).update({'lastActive': FieldValue.serverTimestamp()});
  }

  static Future<void> updatePlayerName(
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

  static Future<DocumentSnapshot> getLobbySnapshot(String lobbyId) async {
    return await lobbyRef(lobbyId).get();
  }
}
