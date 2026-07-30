import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_bootstrap.dart';

class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  User? user;
  String? errorMessage;
  bool busy = false;
  bool googleReady = false;

  bool get available => FirebaseBootstrap.available;
  bool get signedIn => user != null;

  Future<void> initialize() async {
    if (!available) return;

    user = FirebaseAuth.instance.currentUser;
    FirebaseAuth.instance.authStateChanges().listen((value) {
      user = value;
      notifyListeners();
    });

    try {
      await GoogleSignIn.instance.initialize();
      googleReady = true;
    } catch (error) {
      debugPrint('Google Sign-In initialization deferred: $error');
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (!available) return false;
    return _run(
      () => FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> register(String email, String password) async {
    if (!available) return false;
    return _run(
      () => FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      ),
    );
  }

  Future<bool> signInWithGoogle() async {
    if (!available) return false;
    busy = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (!googleReady) {
        await GoogleSignIn.instance.initialize();
        googleReady = true;
      }

      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      return true;
    } on GoogleSignInException catch (error) {
      errorMessage = error.description ?? error.code.name;
      return false;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message ?? error.code;
      return false;
    } catch (error) {
      errorMessage = '$error';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    if (!available) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: email.trim(),
    );
  }

  Future<bool> deleteAccount(String password) async {
    if (!available || user == null) return false;

    busy = true;
    errorMessage = null;
    notifyListeners();

    try {
      final current = FirebaseAuth.instance.currentUser;
      final email = current?.email;
      if (current == null || email == null) {
        throw FirebaseAuthException(
          code: 'no-email-account',
          message:
              'This account cannot be deleted with password reauthentication.',
        );
      }

      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await current.reauthenticateWithCredential(credential);
      await current.delete();
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message ?? error.code;
      return false;
    } catch (error) {
      errorMessage = '$error';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    if (!available) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // The current account may use email/password.
    }
    await FirebaseAuth.instance.signOut();
  }

  Future<bool> _run(Future<UserCredential> Function() action) async {
    busy = true;
    errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on FirebaseAuthException catch (error) {
      errorMessage = error.message ?? error.code;
      return false;
    } catch (error) {
      errorMessage = '$error';
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
