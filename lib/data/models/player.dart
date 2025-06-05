// 📁 Datei: lib/data/models/player.dart

import 'package:json_annotation/json_annotation.dart';
part 'player.g.dart';

@JsonSerializable()
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

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  factory Player.empty() {
    return Player(name: '', deviceId: '', isHost: false, isReady: false);
  }
}
