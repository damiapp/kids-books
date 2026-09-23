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

  /// Whoever is signed in, real or demo — for display only.
  String? get currentEmail => currentUser?.email ?? _mockEmail;

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
      return _friendlyMessage(e, fallback: 'Sign in failed. Please try again.');
    }
  }

  /// Returns null on success, or a human-readable error message.
  Future<String?> signUp(String email, String password) async {
    try {
      await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return _friendlyMessage(e,
          fallback: 'Account creation failed. Please try again.');
    }
  }

  /// Firebase's own `message` is written for developers ("The supplied auth
  /// credential is incorrect, malformed or has expired"), which is not
  /// something to show a parent at 7am.
  ///
  /// `invalid-credential` is the one that matters: with email enumeration
  /// protection — on by default for projects created after Sept 2023 —
  /// a wrong password and an unknown account both return it, precisely so
  /// nobody can probe which emails have accounts. The message below keeps
  /// that property: it never says which half was wrong. `user-not-found`
  /// and `wrong-password` are kept for projects with protection turned
  /// off, where they can still appear.
  String _friendlyMessage(FirebaseAuthException e, {required String fallback}) {
    return switch (e.code) {
      'invalid-credential' ||
      'user-not-found' ||
      'wrong-password' =>
        'That email and password don\'t match. Check both and try again.',
      'invalid-email' => 'That doesn\'t look like an email address.',
      'user-disabled' => 'This account has been turned off.',
      'email-already-in-use' =>
        'There\'s already an account with that email. Try signing in.',
      'weak-password' => 'Pick a longer password — at least 6 characters.',
      'too-many-requests' =>
        'Too many tries. Wait a minute, then have another go.',
      'network-request-failed' =>
        'No connection. Check your internet and try again.',
      // Shows up when Email/Password hasn't been switched on in the
      // Firebase console — worth naming rather than hiding.
      'operation-not-allowed' =>
        'Email sign-in isn\'t switched on for this app yet.',
      _ => e.message ?? fallback,
    };
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
