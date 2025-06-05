// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserProfile _$UserProfileFromJson(Map<String, dynamic> json) => UserProfile(
  uid: json['uid'] as String,
  email: json['email'] as String?,
  displayName: json['displayName'] as String?,
  photoUrl: json['photoUrl'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  provider: json['provider'] as String?,
  tag: json['tag'] as String,
  status: json['status'] as String?,
  currentLobbyId: json['currentLobbyId'] as String?,
  lastActive:
      json['lastActive'] == null
          ? null
          : DateTime.parse(json['lastActive'] as String),
);

Map<String, dynamic> _$UserProfileToJson(UserProfile instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'provider': instance.provider,
      'tag': instance.tag,
      'status': instance.status,
      'currentLobbyId': instance.currentLobbyId,
      'lastActive': instance.lastActive?.toIso8601String(),
    };
