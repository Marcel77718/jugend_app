import 'dart:async';
import 'logging_service.dart';

class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  static FeedbackService get instance => _instance;

  FeedbackService._internal();

  final _snackbarController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<String> get snackbarStream => _snackbarController.stream;
  Stream<String> get errorStream => _errorController.stream;

  void showSnackbar(String message) {
    _snackbarController.add(message);
    LoggingService.instance.log(message, level: LogLevel.info);
  }

  void showError(String error, [StackTrace? stackTrace]) {
    _errorController.add(error);
    LoggingService.instance.log(
      error,
      level: LogLevel.error,
      error: error,
      stackTrace: stackTrace,
    );
  }

  void dispose() {
    _snackbarController.close();
    _errorController.close();
  }
}
