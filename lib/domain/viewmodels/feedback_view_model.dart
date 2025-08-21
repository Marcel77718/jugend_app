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
  int _rating = 0;
  final Map<String, Set<String>> _likeUserIds = {};
  final Map<String, String> _userVotes = {};

  FeedbackViewModel({FeedbackService? service})
    : _service = service ?? FeedbackService();

  List<FeedbackEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSubmitting => _isSubmitting;
  String? get submitError => _submitError;
  bool get submitSuccess => _submitSuccess;
  int get rating => _rating;
  Map<String, Set<String>> get likeUserIds => _likeUserIds;
  Map<String, String> get userVotes => _userVotes;

  void setRating(int rating) {
    _rating = rating;
    notifyListeners();
  }

  void likeFeedback(String feedbackId, String userId) {
    final currentVote = _userVotes[feedbackId];
    _likeUserIds.putIfAbsent(feedbackId, () => <String>{});
    if (currentVote == 'like') {
      _userVotes.remove(feedbackId);
      _likeUserIds[feedbackId]?.remove(userId);
    } else {
      _userVotes[feedbackId] = 'like';
      _likeUserIds[feedbackId]?.add(userId);
    }
    notifyListeners();
  }

  void dislikeFeedback(String feedbackId, String userId) {
    final currentVote = _userVotes[feedbackId];
    _likeUserIds.putIfAbsent(feedbackId, () => <String>{});
    if (currentVote == 'dislike') {
      _userVotes.remove(feedbackId);
    } else {
      _userVotes[feedbackId] = 'dislike';
      _likeUserIds[feedbackId]?.remove(userId);
    }
    notifyListeners();
  }

  String? getUserVote(String feedbackId) {
    return _userVotes[feedbackId];
  }

  Future<void> loadFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _entries = await _service.fetchFeedbackEntries();
      for (final entry in _entries) {
        _likeUserIds.putIfAbsent(entry.id, () => <String>{});
      }
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
    _rating = 0;
    notifyListeners();
  }
}
