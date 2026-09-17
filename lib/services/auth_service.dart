import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Wraps Firebase Authentication (email/password) so screens never touch
/// the Firebase SDK directly — they only ask this whether someone is
/// signed in, and call [signIn]/[signUp]/[signOut].
class AuthService extends ChangeNotifier {
  AuthService() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool get isSignedIn => currentUser != null;

  /// Returns null on success, or a human-readable error message.
  Future<String?> signIn(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Sign in failed. Please try again.';
    }
  }

  /// Returns null on success, or a human-readable error message.
  Future<String?> signUp(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Account creation failed. Please try again.';
    }
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
