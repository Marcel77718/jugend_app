import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:jugend_app/core/logging_service.dart';
import 'package:jugend_app/core/memory_optimizer.dart';

class AssetOptimizer {
  static final AssetOptimizer _instance = AssetOptimizer._internal();
  static AssetOptimizer get instance => _instance;

  final _assetCache = <String, Uint8List>{};
  final _preloadedAssets = <String>{};
  final _loadingQueue = <String>[];
  bool _isProcessingQueue = false;

  AssetOptimizer._internal();

  /// Lädt und cached ein Asset
  Future<Uint8List> loadAsset(String path) async {
    if (_assetCache.containsKey(path)) {
      return _assetCache[path]!;
    }

    try {
      final data = await rootBundle.load(path);
      final bytes = data.buffer.asUint8List();
      _assetCache[path] = bytes;
      MemoryOptimizer.instance.trackCacheEntry(path, bytes.length);
      return bytes;
    } catch (e) {
      LoggingService.instance.log(
        'Fehler beim Laden des Assets: $e',
        level: LogLevel.error,
        error: e,
      );
      rethrow;
    }
  }

  /// Lädt und cached mehrere Assets
  Future<void> preloadAssets(List<String> paths) async {
    for (final path in paths) {
      if (!_preloadedAssets.contains(path)) {
        _addToLoadingQueue(path);
      }
    }
  }

  void _addToLoadingQueue(String path) {
    if (_loadingQueue.contains(path)) return;
    _loadingQueue.add(path);
    _processLoadingQueue();
  }

  Future<void> _processLoadingQueue() async {
    if (_isProcessingQueue || _loadingQueue.isEmpty) return;
    _isProcessingQueue = true;

    try {
      while (_loadingQueue.isNotEmpty) {
        final path = _loadingQueue.removeAt(0);
        if (_preloadedAssets.contains(path)) continue;

        try {
          await loadAsset(path);
          _preloadedAssets.add(path);
        } catch (e) {
          LoggingService.instance.log(
            'Fehler beim Vorladen des Assets: $e',
            level: LogLevel.error,
            error: e,
          );
        }
      }
    } finally {
      _isProcessingQueue = false;
      if (_loadingQueue.isNotEmpty) {
        _processLoadingQueue();
      }
    }
  }

  /// Lädt ein Asset als String
  Future<String> loadStringAsset(String path) async {
    final bytes = await loadAsset(path);
    return String.fromCharCodes(bytes);
  }

  /// Lädt ein Asset als JSON
  Future<Map<String, dynamic>> loadJsonAsset(String path) async {
    final string = await loadStringAsset(path);
    return Future.value(
      Map<String, dynamic>.from(const JsonDecoder().convert(string)),
    );
  }

  /// Entfernt ein Asset aus dem Cache
  void removeFromCache(String path) {
    _assetCache.remove(path);
    _preloadedAssets.remove(path);
    _loadingQueue.remove(path);
    MemoryOptimizer.instance.removeCacheEntry(path);
  }

  /// Leert den Asset-Cache
  void clearCache() {
    _assetCache.clear();
    _preloadedAssets.clear();
    _loadingQueue.clear();
    _isProcessingQueue = false;
  }

  /// Gibt Statistiken über die Asset-Performance zurück
  Map<String, dynamic> getAssetStats() {
    return {
      'cachedAssets': _assetCache.length,
      'preloadedAssets': _preloadedAssets.length,
      'loadingQueue': _loadingQueue.length,
      'totalCacheSize': _assetCache.values.fold<int>(
        0,
        (sum, bytes) => sum + bytes.length,
      ),
    };
  }
}
