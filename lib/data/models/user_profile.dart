import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      createdAt:
          (json['createdAt'] is Timestamp)
              ? (json['createdAt'] as Timestamp).toDate()
              : DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      provider: json['provider'] as String?,
      tag: json['tag'] as String? ?? '',
      status: json['status'] as String?,
      currentLobbyId: json['currentLobbyId'] as String?,
      lastActive:
          json['lastActive'] is Timestamp
              ? (json['lastActive'] as Timestamp).toDate()
              : (json['lastActive'] != null
                  ? DateTime.tryParse(json['lastActive'])
                  : null),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'email': email,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'createdAt': createdAt.toIso8601String(),
    'provider': provider,
    'tag': tag,
    'status': status,
    'currentLobbyId': currentLobbyId,
    'lastActive': lastActive?.toIso8601String(),
  };

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
