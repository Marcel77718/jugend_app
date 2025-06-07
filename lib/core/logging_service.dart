import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class LoggingService {
  static final LoggingService _instance = LoggingService._internal();
  static LoggingService get instance => _instance;

  LoggingService._internal();

  static const String _logKey = 'app_logs';
  static const int _maxLogs = 1000;

  Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final timestamp = DateTime.now().toIso8601String();
    final logEntry = {
      'timestamp': timestamp,
      'level': level.toString(),
      'message': message,
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
    };

    // Log to console in debug mode
    if (kDebugMode) {
      developer.log(
        message,
        error: error,
        stackTrace: stackTrace,
        name: 'JugendApp',
        level: level.toInt(),
      );
    }

    // Store log in SharedPreferences
    await _storeLog(logEntry);

    // If it's an error, report it to Firebase Crashlytics
    if (level == LogLevel.error || level == LogLevel.fatal) {
      await _reportError(logEntry);
    }
  }

  Future<void> _storeLog(Map<String, dynamic> logEntry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList(_logKey) ?? [];

      logs.add(logEntry.toString());

      // Keep only the last _maxLogs entries
      if (logs.length > _maxLogs) {
        logs.removeRange(0, logs.length - _maxLogs);
      }

      await prefs.setStringList(_logKey, logs);
    } catch (e) {
      developer.log('Failed to store log: $e', level: 900);
    }
  }

  Future<void> _reportError(Map<String, dynamic> logEntry) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;

      // Set custom keys for better error tracking
      await crashlytics.setCustomKey('error_level', logEntry['level']);
      await crashlytics.setCustomKey('error_timestamp', logEntry['timestamp']);

      // Log the error message
      await crashlytics.log(logEntry['message']);

      // If we have an error object and stack trace, record the exception
      if (logEntry['error'] != null && logEntry['stackTrace'] != null) {
        await crashlytics.recordError(
          logEntry['error'],
          StackTrace.fromString(logEntry['stackTrace']),
          reason: logEntry['message'],
        );
      }
    } catch (e) {
      developer.log('Failed to report error to Crashlytics: $e', level: 900);
    }
  }

  Future<List<String>> getLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_logKey) ?? [];
    } catch (e) {
      developer.log('Failed to get logs: $e', level: 900);
      return [];
    }
  }

  Future<void> clearLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_logKey);
    } catch (e) {
      developer.log('Failed to clear logs: $e', level: 900);
    }
  }

  void logWarning(String message) {
    log(message, level: LogLevel.warning);
  }

  void logError(String message) {
    log(message, level: LogLevel.error);
  }

  void logDebug(String message) {
    log(message, level: LogLevel.debug);
  }

  void logInfo(String message) {
    log(message, level: LogLevel.info);
  }
}

enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal;

  int toInt() {
    switch (this) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
      case LogLevel.fatal:
        return 1200;
    }
  }
}
