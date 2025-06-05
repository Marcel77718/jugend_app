// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Friend _$FriendFromJson(Map<String, dynamic> json) => Friend(
  friendUid: json['friendUid'] as String,
  friendName: json['friendName'] as String,
  friendTag: json['friendTag'] as String,
  status: json['status'] as String,
  hinzugefuegtAm: DateTime.parse(json['hinzugefuegtAm'] as String),
);

Map<String, dynamic> _$FriendToJson(Friend instance) => <String, dynamic>{
  'friendUid': instance.friendUid,
  'friendName': instance.friendName,
  'friendTag': instance.friendTag,
  'status': instance.status,
  'hinzugefuegtAm': instance.hinzugefuegtAm.toIso8601String(),
};
