import 'package:json_annotation/json_annotation.dart';
part 'friend.g.dart';

@JsonSerializable()
class Friend {
  final String friendUid;
  final String friendName;
  final String friendTag;
  final String status; // accepted
  final DateTime hinzugefuegtAm;

  Friend({
    required this.friendUid,
    required this.friendName,
    required this.friendTag,
    required this.status,
    required this.hinzugefuegtAm,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => _$FriendFromJson(json);
  Map<String, dynamic> toJson() => _$FriendToJson(this);
}
