import 'package:flutter_test/flutter_test.dart';
import 'package:jugend_app/core/logging_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LoggingService loggingService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    loggingService = LoggingService.instance;
  });

  group('LoggingService Tests', () {
    test('should log info message', () async {
      // Arrange
      const message = 'Test info message';

      // Act
      await loggingService.log(message, level: LogLevel.info);

      // Assert
      final logs = await loggingService.getLogs();
      expect(logs.length, 1);
      expect(logs[0], contains(message));
    });

    test('should log error with stack trace', () async {
      // Arrange
      const message = 'Test error message';
      final error = Exception('Test exception');
      final stackTrace = StackTrace.current;

      // Act
      await loggingService.log(
        message,
        level: LogLevel.error,
        error: error,
        stackTrace: stackTrace,
      );

      // Assert
      final logs = await loggingService.getLogs();
      expect(logs.length, 1);
      expect(logs[0], contains(message));
      expect(logs[0], contains(error.toString()));
      expect(logs[0], contains(stackTrace.toString()));
    });

    test('should maintain max log limit', () async {
      // Arrange
      const maxLogs = 1000;

      // Act
      for (var i = 0; i < maxLogs + 10; i++) {
        await loggingService.log('Log $i');
      }

      // Assert
      final logs = await loggingService.getLogs();
      expect(logs.length, maxLogs);
    });

    test('should clear logs', () async {
      // Arrange
      await loggingService.log('Test log');

      // Act
      await loggingService.clearLogs();

      // Assert
      final logs = await loggingService.getLogs();
      expect(logs.length, 0);
    });

    test('should get logs', () async {
      // Arrange
      const message1 = 'Log 1';
      const message2 = 'Log 2';
      await loggingService.log(message1);
      await loggingService.log(message2);

      // Act
      final logs = await loggingService.getLogs();

      // Assert
      expect(logs.length, 2);
      expect(logs[0], contains(message1));
      expect(logs[1], contains(message2));
    });
  });
}
