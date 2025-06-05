import 'package:flutter_test/flutter_test.dart';
import 'package:jugend_app/core/secure_storage_service.dart';

void main() {
  late SecureStorageService secureStorageService;

  setUp(() {
    secureStorageService = SecureStorageService.instance;
  });

  group('SecureStorageService Tests', () {
    test('should write and read data', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';

      // Act
      await secureStorageService.write(key, value);
      final result = await secureStorageService.read(key);

      // Assert
      expect(result, equals(value));
    });

    test('should delete data', () async {
      // Arrange
      const key = 'test_key';
      const value = 'test_value';
      await secureStorageService.write(key, value);

      // Act
      await secureStorageService.delete(key);
      final result = await secureStorageService.read(key);

      // Assert
      expect(result, isNull);
    });

    test('should delete all data', () async {
      // Arrange
      const key1 = 'test_key1';
      const key2 = 'test_key2';
      const value1 = 'test_value1';
      const value2 = 'test_value2';
      await secureStorageService.write(key1, value1);
      await secureStorageService.write(key2, value2);

      // Act
      await secureStorageService.deleteAll();
      final result1 = await secureStorageService.read(key1);
      final result2 = await secureStorageService.read(key2);

      // Assert
      expect(result1, isNull);
      expect(result2, isNull);
    });

    test('should handle non-existent key', () async {
      // Act
      final result = await secureStorageService.read('non_existent_key');

      // Assert
      expect(result, isNull);
    });
  });
}
