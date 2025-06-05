import 'package:json_annotation/json_annotation.dart';
part 'friend_request.g.dart';

@JsonSerializable()
class FriendRequest {
  final String fromUid;
  final String fromName;
  final String fromTag;
  final String status; // pending, accepted, declined
  final DateTime timestamp;

  FriendRequest({
    required this.fromUid,
    required this.fromName,
    required this.fromTag,
    required this.status,
    required this.timestamp,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) =>
      _$FriendRequestFromJson(json);
  Map<String, dynamic> toJson() => _$FriendRequestToJson(this);
}
