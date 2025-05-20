// Datei: lib/data/models/reconnect_data.dart

class ReconnectData {
  final String lobbyId;
  final String playerName;
  final bool isHost;
  final String gameType;

  ReconnectData({
    required this.lobbyId,
    required this.playerName,
    required this.isHost,
    required this.gameType,
  });

  factory ReconnectData.fromMap(Map<String, dynamic> map) {
    return ReconnectData(
      lobbyId: map['lobbyId'] as String,
      playerName: map['playerName'] as String,
      isHost: map['isHost'] as bool,
      gameType: map['gameType'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'lobbyId': lobbyId,
      'playerName': playerName,
      'isHost': isHost,
      'gameType': gameType,
    };
  }
}
