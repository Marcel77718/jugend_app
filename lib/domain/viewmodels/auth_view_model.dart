import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/data/services/auth_service.dart';
import 'package:jugend_app/data/models/user_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jugend_app/core/logging_service.dart';

enum AuthStatus { loading, signedOut, signedIn }

class AuthState {
  final AuthStatus status;
  final UserProfile? profile;
  final String? error;

  AuthState({required this.status, this.profile, this.error});

  AuthState copyWith({
    AuthStatus? status,
    UserProfile? profile,
    String? error,
  }) {
    return AuthState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      error: error,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final AuthService _authService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(AuthState(status: AuthStatus.loading)) {
    _authService.authStateChanges.listen(_onAuthChanged);
  }

  Future<String> _generateUniqueTag(String displayName) async {
    final random = Random();
    String tag;
    bool exists = true;
    do {
      tag = (random.nextInt(9000) + 1000).toString();
      final query =
          await _firestore
              .collection('users')
              .where('displayName', isEqualTo: displayName)
              .where('tag', isEqualTo: tag)
              .get();
      exists = query.docs.isNotEmpty;
    } while (exists);
    return tag;
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      state = AuthState(status: AuthStatus.signedOut);
      return;
    }
    // Lade oder erstelle UserProfile
    final doc = await _firestore.collection('users').doc(user.uid).get();
    UserProfile profile;
    if (doc.exists) {
      final data = doc.data()!;
      // Prüfe, ob Tag fehlt
      if (data['tag'] == null || (data['tag'] as String).isEmpty) {
        final tag = await _generateUniqueTag(user.displayName ?? '');
        await _firestore.collection('users').doc(user.uid).update({'tag': tag});
        data['tag'] = tag;
      }
      profile = UserProfile.fromJson(data);
      // Setze Status auf 'online' NUR wenn nicht bereits lobby/game
      final currentStatus = data['status'] as String?;
      if (currentStatus == null ||
          currentStatus == 'offline' ||
          currentStatus == 'online') {
        await setPresenceStatus('online');
      }
    } else {
      final tag = await _generateUniqueTag(user.displayName ?? '');
      profile = UserProfile(
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoURL ?? 'https://ui-avatars.com/api/?name=User',
        createdAt: DateTime.now(),
        provider:
            user.providerData.isNotEmpty
                ? user.providerData.first.providerId
                : null,
        tag: tag,
      );
      await _firestore.collection('users').doc(user.uid).set(profile.toJson());
      await setPresenceStatus('online');
    }
    state = AuthState(status: AuthStatus.signedIn, profile: profile);
  }

  Future<void> signInWithEmail(
    String email,
    String password, {
    String? locale,
  }) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      await _authService.signInWithEmail(email, password);
      final user = _authService.currentUser;
      if (user != null && !user.emailVerified) {
        await _authService.signOut();
        state = AuthState(
          status: AuthStatus.signedOut,
          error: 'Bitte bestätige zuerst deine E-Mail-Adresse.',
        );
        return;
      }
      // Kein State setzen, Auth-Stream übernimmt
    } catch (e) {
      // Ersetze den print-Aufruf
      LoggingService.instance.log(
        'Fehler bei der Authentifizierung',
        level: LogLevel.error,
        error: e,
      );
      // Allgemeine Fehlermeldung, sprachabhängig
      String msg =
          (locale == 'en')
              ? 'Login failed. Please check your credentials.'
              : 'Login fehlgeschlagen. Bitte überprüfe deine Eingaben.';
      // Wenn es ein Netzwerkproblem ist, spezifisch anzeigen
      if (e.toString().contains('unavailable') ||
          e.toString().contains('network')) {
        msg =
            'Keine Verbindung zu Firebase Auth möglich. Prüfe Internet und Google Play-Dienste.';
      }
      state = AuthState(status: AuthStatus.signedOut, error: msg);
    }
  }

  Future<void> signUpWithEmail(String email, String password) async {
    state = AuthState(status: AuthStatus.loading);
    try {
      final cred = await _authService.signUpWithEmail(email, password);
      await cred.user?.sendEmailVerification();
      state = AuthState(status: AuthStatus.signedOut, error: 'success');
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = 'Diese E-Mail ist bereits registriert.';
          break;
        case 'invalid-email':
          msg = 'Ungültige E-Mail-Adresse.';
          break;
        case 'weak-password':
          msg = 'Das Passwort ist zu schwach.';
          break;
        default:
          msg = 'Fehler bei der Registrierung: ${e.message}';
      }
      state = AuthState(status: AuthStatus.signedOut, error: msg);
      return;
    } catch (e) {
      state = AuthState(status: AuthStatus.signedOut, error: e.toString());
      return;
    }
  }

  Future<void> signInWithGoogle() async {
    state = AuthState(status: AuthStatus.loading);
    try {
      await _authService.signInWithGoogle();
    } catch (e) {
      state = AuthState(status: AuthStatus.signedOut, error: e.toString());
    }
  }

  Future<void> signOut() async {
    state = AuthState(status: AuthStatus.loading);
    await _authService.signOut();
    state = AuthState(status: AuthStatus.signedOut);
  }

  Future<void> deleteAccountAndData() async {
    final user = _authService.currentUser;
    if (user == null) return;
    final uid = user.uid;
    try {
      // Lösche Avatar aus Storage
      final avatarRef = FirebaseStorage.instance.ref().child(
        'avatars/$uid.jpg',
      );
      try {
        await avatarRef.delete();
      } catch (e) {
        LoggingService.instance.log(
          'Fehler beim Löschen des Avatars',
          level: LogLevel.error,
          error: e,
        );
      }
      // Lösche User-Dokument
      await _firestore.collection('users').doc(uid).delete();
      // Lösche Auth-Account
      await user.delete();
    } catch (e) {
      throw Exception('Fehler beim Löschen: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _authService.sendPasswordResetEmail(email);
      state = state.copyWith(error: 'reset_success');
    } catch (e) {
      state = state.copyWith(error: 'reset_failed');
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authService.sendEmailVerification();
      state = state.copyWith(error: 'verify_success');
    } catch (e) {
      // Nur Fehler setzen, wenn wirklich ein Fehler auftritt
      state = state.copyWith(error: 'verify_failed');
    }
  }

  Future<void> changePassword(String newPassword) async {
    try {
      await _authService.changePassword(newPassword);
      state = state.copyWith(error: 'pwchange_success');
    } catch (e) {
      state = state.copyWith(error: 'pwchange_failed');
    }
  }

  // Hilfsmethoden für Fehler-Reset und Status-Reset
  void clearError() {
    state = state.copyWith(error: null);
  }

  void setSignedOut() {
    state = AuthState(status: AuthStatus.signedOut);
  }

  // Firestore-Stream für das UserProfile
  Stream<UserProfile> userProfileStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => UserProfile.fromJson(doc.data()!));
  }

  // Hilfsmethoden für Presence-Status
  Future<void> setPresenceStatus(String status) async {
    final user = _authService.currentUser;
    if (user == null) return;
    await _firestore.collection('users').doc(user.uid).update({
      'status': status,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(),
);
