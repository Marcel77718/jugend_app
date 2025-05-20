// 📁 Datei: lib/data/models/player.dart

class Player {
  final String name;
  final bool isHost;
  final bool isReady;
  final String deviceId;

  Player({
    required this.name,
    required this.isReady,
    required this.isHost,
    required this.deviceId,
  });

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      name: json['name'] ?? '',
      isReady: json['isReady'] ?? false,
      isHost: json['isHost'] ?? false,
      deviceId: json['deviceId'] ?? '',
    );
  }

  factory Player.empty() {
    return Player(name: '', deviceId: '', isHost: false, isReady: false);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'isHost': isHost,
    'isReady': isReady,
    'deviceId': deviceId,
  };
}
