import 'package:json_annotation/json_annotation.dart';
part 'user_profile.g.dart';

@JsonSerializable()
class UserProfile {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final DateTime createdAt;
  final String? provider;
  final String tag;
  final String? status; // online, lobby, game, offline
  final String? currentLobbyId;
  final DateTime? lastActive;

  UserProfile({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.createdAt,
    this.provider,
    required this.tag,
    this.status,
    this.currentLobbyId,
    this.lastActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) =>
      _$UserProfileFromJson(json);
  Map<String, dynamic> toJson() => _$UserProfileToJson(this);

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    String? provider,
    String? tag,
    String? status,
    String? currentLobbyId,
    DateTime? lastActive,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      provider: provider ?? this.provider,
      tag: tag ?? this.tag,
      status: status ?? this.status,
      currentLobbyId: currentLobbyId ?? this.currentLobbyId,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
