import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'performance_monitor.dart';

class ProviderPerformanceMonitor {
  static final ProviderPerformanceMonitor instance =
      ProviderPerformanceMonitor._();
  ProviderPerformanceMonitor._();

  final Map<String, int> _providerBuildTimes = {};
  final Map<String, int> _providerUpdateCounts = {};
  final Map<String, DateTime> _lastProviderUpdates = {};

  /// Überwacht die Build-Zeit eines Providers
  void monitorProviderBuild(String providerName, int buildTimeMs) {
    _providerBuildTimes[providerName] = buildTimeMs;
    _providerUpdateCounts[providerName] =
        (_providerUpdateCounts[providerName] ?? 0) + 1;
    _lastProviderUpdates[providerName] = DateTime.now();

    // Warnung bei zu langer Build-Zeit
    if (buildTimeMs > 16) {
      // 16ms = 60fps
      PerformanceMonitor.instance.logWarning(
        'Provider $providerName build time exceeds 16ms: ${buildTimeMs}ms',
      );
    }

    // Warnung bei zu häufigen Updates
    final updateCount = _providerUpdateCounts[providerName] ?? 0;
    final lastUpdate = _lastProviderUpdates[providerName];
    if (lastUpdate != null) {
      final timeSinceLastUpdate = DateTime.now().difference(lastUpdate);
      if (timeSinceLastUpdate.inMilliseconds < 100 && updateCount > 5) {
        PerformanceMonitor.instance.logWarning(
          'Provider $providerName updated too frequently: $updateCount times in ${timeSinceLastUpdate.inMilliseconds}ms',
        );
      }
    }
  }

  /// Überwacht die Update-Zeit eines Providers
  void monitorProviderUpdate(String providerName, int updateTimeMs) {
    if (updateTimeMs > 8) {
      // 8ms = halbe Frame-Zeit
      PerformanceMonitor.instance.logWarning(
        'Provider $providerName update time exceeds 8ms: ${updateTimeMs}ms',
      );
    }
  }

  /// Gibt Statistiken über die Provider-Performance zurück
  Map<String, dynamic> getProviderStats() {
    return {
      'buildTimes': _providerBuildTimes,
      'updateCounts': _providerUpdateCounts,
      'lastUpdates': _lastProviderUpdates.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
    };
  }

  /// Wrapper für Provider, der die Performance überwacht
  T Function(riverpod.Ref) wrapProvider<T>(
    String providerName,
    T Function(riverpod.Ref) create,
  ) {
    return (ref) {
      final stopwatch = Stopwatch()..start();
      final result = create(ref);
      stopwatch.stop();

      monitorProviderBuild(providerName, stopwatch.elapsedMilliseconds);
      return result;
    };
  }

  /// Wrapper für StateNotifier, der die Performance überwacht
  T Function(riverpod.Ref) wrapStateNotifier<
    T extends riverpod.StateNotifier<S>,
    S
  >(String providerName, T Function(riverpod.Ref) create) {
    return (ref) {
      final stopwatch = Stopwatch()..start();
      final notifier = create(ref);
      stopwatch.stop();

      monitorProviderBuild(providerName, stopwatch.elapsedMilliseconds);

      // Überwache State-Updates
      notifier.addListener((state) {
        final updateStopwatch = Stopwatch()..start();
        monitorProviderUpdate(
          providerName,
          updateStopwatch.elapsedMilliseconds,
        );
      });

      return notifier;
    };
  }

  /// Wrapper für FutureProvider, der die Performance überwacht
  Future<T> Function(riverpod.Ref) wrapFutureProvider<T>(
    String providerName,
    Future<T> Function(riverpod.Ref) create,
  ) {
    return (ref) async {
      final stopwatch = Stopwatch()..start();
      final result = await create(ref);
      stopwatch.stop();

      monitorProviderBuild(providerName, stopwatch.elapsedMilliseconds);
      return result;
    };
  }

  /// Wrapper für StreamProvider, der die Performance überwacht
  Stream<T> Function(riverpod.Ref) wrapStreamProvider<T>(
    String providerName,
    Stream<T> Function(riverpod.Ref) create,
  ) {
    return (ref) {
      final stopwatch = Stopwatch()..start();
      final stream = create(ref);
      stopwatch.stop();

      monitorProviderBuild(providerName, stopwatch.elapsedMilliseconds);
      return stream;
    };
  }
}
