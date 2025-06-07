class GameInfo {
  final String id;
  final String name;
  final String description;
  final String rules;
  final List<String> roles;
  final String? iconName;

  GameInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.rules,
    required this.roles,
    this.iconName,
  });

  factory GameInfo.fromJson(Map<String, dynamic> json) {
    return GameInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      rules: json['rules'] as String? ?? '',
      roles: List<String>.from(json['roles'] ?? []),
      iconName: json['iconName'] as String?,
    );
  }
}
