// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendRequest _$FriendRequestFromJson(Map<String, dynamic> json) =>
    FriendRequest(
      fromUid: json['fromUid'] as String,
      fromName: json['fromName'] as String,
      fromTag: json['fromTag'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$FriendRequestToJson(FriendRequest instance) =>
    <String, dynamic>{
      'fromUid': instance.fromUid,
      'fromName': instance.fromName,
      'fromTag': instance.fromTag,
      'status': instance.status,
      'timestamp': instance.timestamp.toIso8601String(),
    };
