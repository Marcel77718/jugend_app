class Friend {
  final String friendUid;
  final String friendName;
  final String friendTag;
  final String status; // accepted
  final DateTime hinzugefuegtAm;

  Friend({
    required this.friendUid,
    required this.friendName,
    required this.friendTag,
    required this.status,
    required this.hinzugefuegtAm,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      friendUid: json['friendUid'] as String,
      friendName: json['friendName'] as String,
      friendTag: json['friendTag'] as String,
      status: json['status'] as String,
      hinzugefuegtAm: DateTime.parse(json['hinzugefuegtAm'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'friendUid': friendUid,
    'friendName': friendName,
    'friendTag': friendTag,
    'status': status,
    'hinzugefuegtAm': hinzugefuegtAm.toIso8601String(),
  };
}
