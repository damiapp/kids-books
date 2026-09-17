import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/demo_accounts.dart';

/// Wraps Firebase Authentication (email/password) so screens never touch
/// the Firebase SDK directly — they only ask this whether someone is
/// signed in, and call [signIn]/[signUp]/[signOut].
///
/// Also recognizes the built-in [demoAccounts]: signing in with one of
/// those credentials never touches Firebase, so it works with the
/// placeholder config this app ships with.
class AuthService extends ChangeNotifier {
  static const _mockEmailKey = 'mock_signed_in_email';

  String? _mockEmail;

  AuthService() {
    FirebaseAuth.instance.authStateChanges().listen((_) => notifyListeners());
    _restoreMockSession();
  }

  Future<void> _restoreMockSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_mockEmailKey);
    if (email != null && demoAccountByEmail(email) != null) {
      _mockEmail = email;
      notifyListeners();
    }
  }

  User? get currentUser => FirebaseAuth.instance.currentUser;

  /// The demo account currently "signed in" via mock credentials, if any.
  DemoAccount? get activeDemoAccount =>
      _mockEmail == null ? null : demoAccountByEmail(_mockEmail!);

  bool get isSignedIn => currentUser != null || _mockEmail != null;

  /// Returns null on success, or a human-readable error message.
  Future<String?> signIn(String email, String password) async {
    final demo = matchDemoAccount(email, password);
    if (demo != null) {
      _mockEmail = demo.email;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_mockEmailKey, demo.email);
      notifyListeners();
      return null;
    }

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

  Future<void> signOut() async {
    if (_mockEmail != null) {
      _mockEmail = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_mockEmailKey);
      notifyListeners();
    }
    await FirebaseAuth.instance.signOut();
  }
}
