import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jugend_app/data/services/auth_service.dart';
import 'package:jugend_app/data/models/user_profile.dart';
import 'package:firebase_storage/firebase_storage.dart';

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

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      state = AuthState(status: AuthStatus.signedOut);
      return;
    }
    // Lade oder erstelle UserProfile
    final doc = await _firestore.collection('users').doc(user.uid).get();
    UserProfile profile;
    if (doc.exists) {
      profile = UserProfile.fromJson(doc.data()!);
    } else {
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
      );
      await _firestore.collection('users').doc(user.uid).set(profile.toJson());
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
      // Debug-Log für Fehler
      // ignore: avoid_print
      print('AUTH-LOGIN-ERROR: ${e.toString()}');
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
      } catch (_) {}
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
}

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>(
  (ref) => AuthViewModel(),
);
