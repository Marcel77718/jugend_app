import 'dart:async';
import 'package:jugend_app/core/logging_service.dart';

class MemoryOptimizer {
  static final MemoryOptimizer _instance = MemoryOptimizer._internal();
  static MemoryOptimizer get instance => _instance;

  final _cacheSizes = <String, int>{};
  final _maxCacheSize = 50 * 1024 * 1024; // 50MB
  final _cacheTimeout = const Duration(minutes: 30);
  final _lastAccess = <String, DateTime>{};
  Timer? _cleanupTimer;
  bool _isMonitoring = false;
  bool _isInitialized = false;

  MemoryOptimizer._internal() {
    _startMonitoring();
  }

  /// Initialisiert den MemoryOptimizer
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Starte Memory-Monitoring
    _startMemoryMonitoring();

    _isInitialized = true;
    LoggingService.instance.log(
      'MemoryOptimizer initialisiert',
      level: LogLevel.info,
    );
  }

  void _startMemoryMonitoring() {
    // Implementiere Memory-Monitoring
  }

  void _startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // Starte Cleanup-Timer
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _cleanupCache();
    });

    // Überwache Memory-Nutzung
    Timer.periodic(const Duration(seconds: 30), (_) {
      _checkMemoryUsage();
    });
  }

  void _checkMemoryUsage() {
    try {
      final totalMemory = _getTotalMemoryUsage();
      if (totalMemory > _maxCacheSize) {
        _cleanupCache();
      }
    } catch (e) {
      LoggingService.instance.log(
        'Fehler bei der Memory-Überwachung: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  int _getTotalMemoryUsage() {
    return _cacheSizes.values.fold(0, (sum, size) => sum + size);
  }

  void _cleanupCache() {
    try {
      final now = DateTime.now();
      final keysToRemove = <String>[];

      // Entferne abgelaufene Cache-Einträge
      for (final entry in _lastAccess.entries) {
        if (now.difference(entry.value) > _cacheTimeout) {
          keysToRemove.add(entry.key);
        }
      }

      // Entferne Einträge, wenn der Cache zu groß ist
      if (_getTotalMemoryUsage() > _maxCacheSize) {
        final sortedEntries =
            _lastAccess.entries.toList()
              ..sort((a, b) => a.value.compareTo(b.value));

        while (_getTotalMemoryUsage() > _maxCacheSize &&
            sortedEntries.isNotEmpty) {
          final oldestEntry = sortedEntries.removeAt(0);
          keysToRemove.add(oldestEntry.key);
        }
      }

      // Lösche die ausgewählten Einträge
      for (final key in keysToRemove) {
        _cacheSizes.remove(key);
        _lastAccess.remove(key);
      }

      if (keysToRemove.isNotEmpty) {
        LoggingService.instance.log(
          'Cache bereinigt: ${keysToRemove.length} Einträge entfernt',
          level: LogLevel.info,
        );
      }
    } catch (e) {
      LoggingService.instance.log(
        'Fehler bei der Cache-Bereinigung: $e',
        level: LogLevel.error,
        error: e,
      );
    }
  }

  void trackCacheEntry(String key, int size) {
    _cacheSizes[key] = size;
    _lastAccess[key] = DateTime.now();
  }

  void removeCacheEntry(String key) {
    _cacheSizes.remove(key);
    _lastAccess.remove(key);
  }

  void clearCache() {
    _cacheSizes.clear();
    _lastAccess.clear();
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _isMonitoring = false;
  }

  Map<String, dynamic> getMemoryStats() {
    return {
      'totalMemoryUsage': _getTotalMemoryUsage(),
      'maxCacheSize': _maxCacheSize,
      'cacheEntries': _cacheSizes.length,
      'lastCleanup':
          _lastAccess.isEmpty
              ? null
              : _lastAccess.values.reduce((a, b) => a.isBefore(b) ? a : b),
    };
  }
}
