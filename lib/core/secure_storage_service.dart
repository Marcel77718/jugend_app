import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jugend_app/core/logging_service.dart';

class SecureStorageService {
  static final SecureStorageService _instance =
      SecureStorageService._internal();
  static SecureStorageService get instance => _instance;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SecureStorageService._internal();

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
      LoggingService.instance.log(
        'Sicherer Speicher: Daten geschrieben für Key: $key',
        level: LogLevel.debug,
      );
    } catch (e, stackTrace) {
      LoggingService.instance.log(
        'Fehler beim Schreiben in sicheren Speicher',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<String?> read(String key) async {
    try {
      final value = await _storage.read(key: key);
      LoggingService.instance.log(
        'Sicherer Speicher: Daten gelesen für Key: $key',
        level: LogLevel.debug,
      );
      return value;
    } catch (e, stackTrace) {
      LoggingService.instance.log(
        'Fehler beim Lesen aus sicherem Speicher',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
      LoggingService.instance.log(
        'Sicherer Speicher: Daten gelöscht für Key: $key',
        level: LogLevel.debug,
      );
    } catch (e, stackTrace) {
      LoggingService.instance.log(
        'Fehler beim Löschen aus sicherem Speicher',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      LoggingService.instance.log(
        'Sicherer Speicher: Alle Daten gelöscht',
        level: LogLevel.debug,
      );
    } catch (e, stackTrace) {
      LoggingService.instance.log(
        'Fehler beim Löschen aller Daten aus sicherem Speicher',
        level: LogLevel.error,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
