// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jugend_app/services/image_service.dart';
import 'package:jugend_app/data/models/game_info.dart';

class GamesRepository {
  List<GameInfo>? _cache;
  bool _isLoading = false;
  String? _lastError;

  Future<List<GameInfo>> loadGames() async {
    if (_cache != null) return _cache!;
    if (_isLoading) {
      // Warte auf laufenden Ladevorgang
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      if (_cache != null) return _cache!;
      if (_lastError != null) throw Exception(_lastError);
    }

    _isLoading = true;
    _lastError = null;

    try {
      final jsonStr = await rootBundle.loadString('assets/games/catalog.json');
      final List<dynamic> data = json.decode(jsonStr);
      _cache = data.map((e) => GameInfo.fromJson(e)).toList();

      // Vorladen der Spiel-Icons
      final imageUrls =
          _cache!
              .where((game) => game.iconName != null)
              .map((game) => 'assets/images/games/${game.iconName}')
              .toList();
      await ImageService.instance.preloadImages(imageUrls);

      return _cache!;
    } catch (e) {
      _lastError = 'Fehler beim Laden des Spiele-Katalogs: $e';
      throw Exception(_lastError);
    } finally {
      _isLoading = false;
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

  void clearCache() {
    _cache = null;
    _lastError = null;
  }
}

final gamesRepositoryProvider = Provider<GamesRepository>(
  (ref) => GamesRepository(),
);
