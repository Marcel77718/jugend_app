import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Stream für das Profil
  Stream<ProfileData> get profileStream {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value(ProfileData.empty());

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) => ProfileData.fromFirestore(doc));
  }

  // Name aktualisieren
  Future<void> updateName(String newName) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    await _firestore.collection('users').doc(currentUserId).update({
      'name': newName,
    });
  }

  // Profilbild aktualisieren
  Future<void> updateProfilePicture(File imageFile) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Altes Bild löschen
    final oldImageUrl = _auth.currentUser?.photoURL;
    if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(oldImageUrl).delete();
      } catch (e) {
        // Ignoriere Fehler beim Löschen des alten Bildes
      }
    }

    // Neues Bild hochladen
    final ref = _storage.ref().child('profile_pictures/$currentUserId.jpg');
    await ref.putFile(imageFile);
    final newImageUrl = await ref.getDownloadURL();

    // Profilbild-URL aktualisieren
    await _auth.currentUser?.updatePhotoURL(newImageUrl);
    await _firestore.collection('users').doc(currentUserId).update({
      'photoUrl': newImageUrl,
    });
  }

  // Account löschen
  Future<void> deleteAccount() async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    // Profilbild löschen
    final photoUrl = _auth.currentUser?.photoURL;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(photoUrl).delete();
      } catch (e) {
        // Ignoriere Fehler beim Löschen des Profilbildes
      }
    }

    // User-Dokument löschen
    await _firestore.collection('users').doc(currentUserId).delete();

    // Account löschen
    await _auth.currentUser?.delete();
  }

  // Ausloggen
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class ProfileData {
  final String id;
  final String name;
  final String tag;
  final String photoUrl;
  final String email;

  ProfileData({
    required this.id,
    required this.name,
    required this.tag,
    required this.photoUrl,
    required this.email,
  });

  factory ProfileData.empty() {
    return ProfileData(id: '', name: '', tag: '', photoUrl: '', email: '');
  }

  factory ProfileData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProfileData(
      id: doc.id,
      name: data['name'] ?? '',
      tag: data['tag'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      email: data['email'] ?? '',
    );
  }
}
