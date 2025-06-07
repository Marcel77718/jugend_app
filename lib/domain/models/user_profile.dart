class UserProfile {
  final String? displayName;
  final String? photoUrl;
  final String tag;
  final String uid;

  const UserProfile({
    this.displayName,
    this.photoUrl,
    required this.tag,
    required this.uid,
  });

  factory UserProfile.empty() {
    return const UserProfile(
      displayName: null,
      photoUrl: null,
      tag: '0000',
      uid: '',
    );
  }

  UserProfile copyWith({
    String? displayName,
    String? photoUrl,
    String? tag,
    String? uid,
  }) {
    return UserProfile(
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      tag: tag ?? this.tag,
      uid: uid ?? this.uid,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'tag': tag,
      'uid': uid,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      tag: json['tag'] as String,
      uid: json['uid'] as String,
    );
  }
}
