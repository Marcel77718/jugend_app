import 'dart:async';
import 'package:flutter/material.dart';
import 'logging_service.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  static PerformanceMonitor get instance => _instance;

  final _frameTimings = <int>[];
  final _buildTimes = <String, List<int>>{};
  final _operationTimes = <String, List<int>>{};
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  PerformanceMonitor._internal();

  void startMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;
    _monitoringTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _analyzePerformance();
    });
  }

  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _isMonitoring = false;
  }

  void recordFrameTime(int frameTime) {
    if (!_isMonitoring) return;
    _frameTimings.add(frameTime);
    if (_frameTimings.length > 100) {
      _frameTimings.removeAt(0);
    }
  }

  void recordBuildTime(String widgetName, int buildTime) {
    if (!_isMonitoring) return;
    _buildTimes.putIfAbsent(widgetName, () => []).add(buildTime);
    if (_buildTimes[widgetName]!.length > 50) {
      _buildTimes[widgetName]!.removeAt(0);
    }
  }

  void recordOperationTime(String operationName, int operationTime) {
    if (!_isMonitoring) return;
    _operationTimes.putIfAbsent(operationName, () => []).add(operationTime);
    if (_operationTimes[operationName]!.length > 50) {
      _operationTimes[operationName]!.removeAt(0);
    }
  }

  void _analyzePerformance() {
    if (!_isMonitoring) return;

    // Analysiere Frame-Timings
    if (_frameTimings.isNotEmpty) {
      final avgFrameTime =
          _frameTimings.reduce((a, b) => a + b) / _frameTimings.length;
      if (avgFrameTime > 16) {
        // 60 FPS = 16.67ms pro Frame
        logWarning(
          'Average frame time exceeds 16ms: ${avgFrameTime.toStringAsFixed(2)}ms',
        );
      }
    }

    // Analysiere Build-Zeiten
    for (final entry in _buildTimes.entries) {
      final avgBuildTime =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avgBuildTime > 8) {
        // Mehr als 8ms Build-Zeit
        logWarning(
          'Widget ${entry.key} build time exceeds 8ms: ${avgBuildTime.toStringAsFixed(2)}ms',
        );
      }
    }

    // Analysiere Operations-Zeiten
    for (final entry in _operationTimes.entries) {
      final avgOperationTime =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avgOperationTime > 100) {
        // Mehr als 100ms Operations-Zeit
        logWarning(
          'Operation ${entry.key} takes too long: ${avgOperationTime.toStringAsFixed(2)}ms',
        );
      }
    }
  }

  void dispose() {
    stopMonitoring();
    _frameTimings.clear();
    _buildTimes.clear();
    _operationTimes.clear();
  }

  void logWarning(String message) {
    LoggingService.instance.logWarning('Performance: $message');
  }
}

class PerformanceWidget extends StatefulWidget {
  final Widget child;
  final String name;

  const PerformanceWidget({super.key, required this.child, required this.name});

  @override
  State<PerformanceWidget> createState() => _PerformanceWidgetState();
}

class _PerformanceWidgetState extends State<PerformanceWidget> {
  Stopwatch? _buildStopwatch;

  @override
  void initState() {
    super.initState();
    _buildStopwatch = Stopwatch();
  }

  @override
  void dispose() {
    _buildStopwatch?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _buildStopwatch?.reset();
    _buildStopwatch?.start();

    final result = widget.child;

    _buildStopwatch?.stop();
    if (_buildStopwatch != null) {
      PerformanceMonitor.instance.recordBuildTime(
        widget.name,
        _buildStopwatch!.elapsedMilliseconds,
      );
    }

    return result;
  }
}

class PerformanceOperation {
  final String name;
  final Stopwatch _stopwatch = Stopwatch();

  PerformanceOperation(this.name) {
    _stopwatch.start();
  }

  void stop() {
    _stopwatch.stop();
    PerformanceMonitor.instance.recordOperationTime(
      name,
      _stopwatch.elapsedMilliseconds,
    );
  }
}
