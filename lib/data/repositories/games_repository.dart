// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class GamesRepository {
  List<GameInfo>? _cache;

  Future<List<GameInfo>> loadGames() async {
    if (_cache != null) return _cache!;
    try {
      final jsonStr = await rootBundle.loadString('assets/games/catalog.json');
      final List<dynamic> data = json.decode(jsonStr);
      _cache = data.map((e) => GameInfo.fromJson(e)).toList();
      return _cache!;
    } catch (e) {
      // Fehler robust behandeln
      throw Exception('Fehler beim Laden des Spiele-Katalogs: $e');
    }
  }

  Future<GameInfo?> getGameById(String id) async {
    final games = await loadGames();
    try {
      return games.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}

final gamesRepositoryProvider = Provider<GamesRepository>(
  (ref) => GamesRepository(),
);
