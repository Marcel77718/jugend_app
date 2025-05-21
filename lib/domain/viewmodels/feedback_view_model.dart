import 'package:flutter/material.dart';
import 'package:jugend_app/data/models/feedback_entry.dart';
import 'package:jugend_app/data/services/feedback_service.dart';
import 'package:uuid/uuid.dart';

class FeedbackViewModel extends ChangeNotifier {
  final FeedbackService _service;
  List<FeedbackEntry> _entries = [];
  bool _isLoading = false;
  String? _error;
  bool _isSubmitting = false;
  String? _submitError;
  bool _submitSuccess = false;

  FeedbackViewModel({FeedbackService? service})
    : _service = service ?? FeedbackService();

  List<FeedbackEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  bool get submitSuccess => _submitSuccess;

  Future<void> loadFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _service.fetchFeedbackEntries();
    } catch (e) {
      _error = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> submitFeedback({
    required String userId,
    String? userName,
    required String message,
    required int rating,
    String? appVersion,
    String? platform,
  }) async {
    _isSubmitting = true;
    _submitError = null;
    _submitSuccess = false;
    notifyListeners();
    try {
      final entry = FeedbackEntry(
        id: const Uuid().v4(),
        userId: userId,
        userName: userName,
        message: message,
        rating: rating,
        createdAt: DateTime.now(),
        appVersion: appVersion,
        platform: platform,
      );
      await _service.submitFeedback(entry);
      _submitSuccess = true;
      await loadFeedback();
    } catch (e) {
      _submitError = e.toString();
    }
    _isSubmitting = false;
    notifyListeners();
  }

  void resetSubmitState() {
    _isSubmitting = false;
    _submitError = null;
    _submitSuccess = false;
    notifyListeners();
  }
}
