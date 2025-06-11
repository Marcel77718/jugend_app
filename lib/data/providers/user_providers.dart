import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final userDataProvider = StreamProvider.family<Map<String, dynamic>?, String>(
  (ref, uid) => FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .snapshots()
      .map((snap) => snap.data()),
);
