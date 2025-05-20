import 'dart:async';

class FeedbackService {
  FeedbackService._();
  static final FeedbackService instance = FeedbackService._();

  final _snackbarController = StreamController<String>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<String> get snackbarStream => _snackbarController.stream;
  Stream<String> get errorStream => _errorController.stream;

  void showSnackbar(String message) {
    _snackbarController.add(message);
  }

  void showError(String message) {
    _errorController.add(message);
  }

  void dispose() {
    _snackbarController.close();
    _errorController.close();
  }
}
