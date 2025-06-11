import 'dart:async';
import 'package:jugend_app/core/logging_service.dart';

class NetworkOptimizer {
  static final NetworkOptimizer _instance = NetworkOptimizer._internal();
  static NetworkOptimizer get instance => _instance;

  final _pendingRequests = <String, Completer<dynamic>>{};
  final _retryDelays = [1, 2, 4, 8, 16]; // Sekunden
  final _maxRetries = 3;
  final _requestTimeout = const Duration(seconds: 30);
  final _deduplicationWindow = const Duration(seconds: 5);
  bool _isInitialized = false;

  NetworkOptimizer._internal();

  /// Initialisiert den NetworkOptimizer
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Starte Network-Monitoring
    _startNetworkMonitoring();

    _isInitialized = true;
    LoggingService.instance.log(
      'NetworkOptimizer initialisiert',
      level: LogLevel.info,
    );
  }

  void _startNetworkMonitoring() {
    // Implementiere Network-Monitoring
  }

  /// Optimierte Netzwerk-Anfrage mit Deduplication und Retry-Logik
  Future<T> optimizedRequest<T>({
    required String requestId,
    required Future<T> Function() request,
    bool enableDeduplication = true,
    bool enableRetry = true,
    Duration? timeout,
  }) async {
    if (enableDeduplication) {
      final existingRequest = _pendingRequests[requestId];
      if (existingRequest != null) {
        return existingRequest.future as Future<T>;
      }
    }

    final completer = Completer<T>();
    if (enableDeduplication) {
      _pendingRequests[requestId] = completer;
    }

    try {
      final result = await _executeWithRetry(
        request: request,
        enableRetry: enableRetry,
        timeout: timeout ?? _requestTimeout,
      );

      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return result;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      if (enableDeduplication) {
        _pendingRequests.remove(requestId);
      }
    }
  }

  Future<T> _executeWithRetry<T>({
    required Future<T> Function() request,
    required bool enableRetry,
    required Duration timeout,
  }) async {
    var attempt = 0;
    while (true) {
      try {
        return await request().timeout(timeout);
      } catch (e) {
        attempt++;
        if (!enableRetry || attempt > _maxRetries) {
          rethrow;
        }

        final delay = _retryDelays[attempt - 1];
        LoggingService.instance.log(
          'Netzwerk-Fehler, Wiederholungsversuch $attempt nach ${delay}s: $e',
          level: LogLevel.warning,
        );

        await Future.delayed(Duration(seconds: delay));
      }
    }
  }

  /// Batch-Request für mehrere Anfragen
  Future<List<T>> batchRequest<T>({
    required List<Future<T> Function()> requests,
    bool parallel = true,
    bool enableRetry = true,
  }) async {
    if (parallel) {
      return Future.wait(
        requests.map(
          (request) => _executeWithRetry(
            request: request,
            enableRetry: enableRetry,
            timeout: _requestTimeout,
          ),
        ),
      );
    } else {
      final results = <T>[];
      for (final request in requests) {
        results.add(
          await _executeWithRetry(
            request: request,
            enableRetry: enableRetry,
            timeout: _requestTimeout,
          ),
        );
      }
      return results;
    }
  }

  /// Abbrechen einer laufenden Anfrage
  void cancelRequest(String requestId) {
    final completer = _pendingRequests[requestId];
    if (completer != null && !completer.isCompleted) {
      completer.completeError('Anfrage abgebrochen');
      _pendingRequests.remove(requestId);
    }
  }

  /// Abbrechen aller laufenden Anfragen
  void cancelAllRequests() {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError('Alle Anfragen abgebrochen');
      }
    }
    _pendingRequests.clear();
  }

  /// Statistiken über die Netzwerk-Performance
  Map<String, dynamic> getNetworkStats() {
    return {
      'pendingRequests': _pendingRequests.length,
      'maxRetries': _maxRetries,
      'requestTimeout': _requestTimeout.inSeconds,
      'deduplicationWindow': _deduplicationWindow.inSeconds,
    };
  }
}
