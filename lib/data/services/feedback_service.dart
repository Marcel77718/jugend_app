import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/data/models/feedback_entry.dart';

class FeedbackService {
  final FirebaseFirestore _firestore;
  FeedbackService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference get _feedbackRef => _firestore.collection('feedback');

  Future<void> submitFeedback(FeedbackEntry entry) async {
    await _feedbackRef.doc(entry.id).set(entry.toJson());
  }

  Future<List<FeedbackEntry>> fetchFeedbackEntries({int limit = 50}) async {
    final snapshot =
        await _feedbackRef
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get();
    return snapshot.docs
        .map(
          (doc) => FeedbackEntry.fromJson(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Stream<List<FeedbackEntry>> feedbackStream({int limit = 50}) {
    return _feedbackRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map(
                    (doc) => FeedbackEntry.fromJson(
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList(),
        );
  }
}
