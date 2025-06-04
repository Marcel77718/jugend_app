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

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      fromUid: json['fromUid'] as String,
      fromName: json['fromName'] as String,
      fromTag: json['fromTag'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'fromUid': fromUid,
    'fromName': fromName,
    'fromTag': fromTag,
    'status': status,
    'timestamp': timestamp.toIso8601String(),
  };
}
