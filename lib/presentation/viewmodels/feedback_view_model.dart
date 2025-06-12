import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Feedback senden
  Future<void> sendFeedback({
    required String title,
    required String description,
    required String category,
    required int rating,
  }) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('feedback').add({
      'userId': currentUserId,
      'title': title,
      'description': description,
      'category': category,
      'rating': rating,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'new',
    });
  }

  // Feedback-Kategorien
  List<String> get categories => [
    'Bug',
    'Feature',
    'Verbesserung',
    'Sonstiges',
  ];

  // Validierung
  String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte gib einen Titel ein';
    }
    if (value.length < 3) {
      return 'Der Titel muss mindestens 3 Zeichen lang sein';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte gib eine Beschreibung ein';
    }
    if (value.length < 10) {
      return 'Die Beschreibung muss mindestens 10 Zeichen lang sein';
    }
    return null;
  }

  String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte wähle eine Kategorie';
    }
    return null;
  }

  String? validateRating(int? value) {
    if (value == null || value < 1 || value > 5) {
      return 'Bitte gib eine Bewertung zwischen 1 und 5 ein';
    }
    return null;
  }
}
