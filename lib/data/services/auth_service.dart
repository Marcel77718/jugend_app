import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // E-Mail/Passwort Registrierung
  Future<UserCredential> signUpWithEmail(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // E-Mail/Passwort Login
  Future<UserCredential> signInWithEmail(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Google Sign-In
  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      return await _auth.signInWithPopup(googleProvider);
    } else {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    }
  }

  // Abmelden
  Future<void> signOut() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
  }

  // Aktueller User
  User? get currentUser => _auth.currentUser;

  // Auth-Status Stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Passwort zurücksetzen
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // E-Mail-Verifizierung erneut senden
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Passwort ändern
  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }
}
