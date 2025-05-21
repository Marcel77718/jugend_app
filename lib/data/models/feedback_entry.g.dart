// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeedbackEntry _$FeedbackEntryFromJson(Map<String, dynamic> json) =>
    FeedbackEntry(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String?,
      message: json['message'] as String,
      rating: (json['rating'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      appVersion: json['appVersion'] as String?,
      platform: json['platform'] as String?,
    );

Map<String, dynamic> _$FeedbackEntryToJson(FeedbackEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'userName': instance.userName,
      'message': instance.message,
      'rating': instance.rating,
      'createdAt': instance.createdAt.toIso8601String(),
      'appVersion': instance.appVersion,
      'platform': instance.platform,
    };
