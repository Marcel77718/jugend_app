// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Player _$PlayerFromJson(Map<String, dynamic> json) => Player(
  name: json['name'] as String,
  isReady: json['isReady'] as bool,
  isHost: json['isHost'] as bool,
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$PlayerToJson(Player instance) => <String, dynamic>{
  'name': instance.name,
  'isHost': instance.isHost,
  'isReady': instance.isReady,
  'deviceId': instance.deviceId,
};
