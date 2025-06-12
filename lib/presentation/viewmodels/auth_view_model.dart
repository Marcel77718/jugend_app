import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authViewModelProvider = StateNotifierProvider<AuthViewModel, AuthState>((
  ref,
) {
  return AuthViewModel();
});

class AuthState {
  final bool isLoading;
  final String? error;
  final bool isLogin;
  final bool showVerificationNotice;

  AuthState({
    this.isLoading = false,
    this.error,
    this.isLogin = true,
    this.showVerificationNotice = false,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    bool? isLogin,
    bool? showVerificationNotice,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLogin: isLogin ?? this.isLogin,
      showVerificationNotice:
          showVerificationNotice ?? this.showVerificationNotice,
    );
  }
}

class AuthViewModel extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthViewModel() : super(AuthState());

  // Stream für den Auth-Status
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registrieren
  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Account erstellen
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sicherstellen, dass user nicht null ist
      final user = userCredential.user;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Registrierung fehlgeschlagen: Kein Benutzerobjekt erhalten.',
        );
        return;
      }

      // User-Dokument erstellen
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'tag': _generateTag(),
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'offline',
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Einloggen
  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Status auf online setzen
      final user = _auth.currentUser;
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Login fehlgeschlagen: Kein Benutzerobjekt erhalten.',
        );
        return;
      }
      await _firestore.collection('users').doc(user.uid).update({
        'status': 'online',
        'lastSeen': FieldValue.serverTimestamp(),
      });

      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Passwort zurücksetzen
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Ausloggen
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Status auf offline setzen
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'status': 'offline',
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }

      await _auth.signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Validierung
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte gib eine E-Mail-Adresse ein';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Bitte gib eine gültige E-Mail-Adresse ein';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte gib ein Passwort ein';
    }
    if (value.length < 6) {
      return 'Das Passwort muss mindestens 6 Zeichen lang sein';
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bitte gib einen Namen ein';
    }
    if (value.length < 2) {
      return 'Der Name muss mindestens 2 Zeichen lang sein';
    }
    return null;
  }

  // Hilfsfunktionen
  String _generateTag() {
    final random = DateTime.now().millisecondsSinceEpoch % 10000;
    return random.toString().padLeft(4, '0');
  }

  void toggleLoginMode() {
    state = state.copyWith(isLogin: !state.isLogin);
  }

  void setShowVerificationNotice(bool show) {
    state = state.copyWith(showVerificationNotice: show);
  }
}
