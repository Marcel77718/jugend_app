import 'package:json_annotation/json_annotation.dart';

part 'feedback_entry.g.dart';

@JsonSerializable()
class FeedbackEntry {
  final String id;
  final String userId;
  final String? userName;
  final String message;
  final int rating; // 1-5 Sterne
  final DateTime createdAt;
  final String? appVersion;
  final String? platform;

  FeedbackEntry({
    required this.id,
    required this.userId,
    this.userName,
    required this.message,
    required this.rating,
    required this.createdAt,
    this.appVersion,
    this.platform,
  });

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) =>
      _$FeedbackEntryFromJson(json);
  Map<String, dynamic> toJson() => _$FeedbackEntryToJson(this);
}
