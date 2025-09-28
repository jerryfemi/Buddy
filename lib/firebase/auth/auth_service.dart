import 'package:buddy/firebase/firestore/user_firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _userFirestoreService.createUserProfileIfNotExists(user);
      }
      return user;
    } on PlatformException catch (e) {
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      throw (_handleFirebaseAuthError(e));
    }
  }

  // Email Sign In
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _userFirestoreService.createUserProfileIfNotExists(user);
      }
      return user;
    } on PlatformException catch (e) {
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      throw (_handleFirebaseAuthError(e));
    }
  }

  // Email Sign Up
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = userCredential.user;
      if (user != null) {
        await _userFirestoreService.createUserProfileIfNotExists(user);
      }
      return user;
    } on PlatformException catch (e) {
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      throw (_handleFirebaseAuthError(e));
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on PlatformException catch (e) {
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      throw (_handleFirebaseAuthError(e));
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Handle Firebase Auth Errors (common cases only)

  String _handlePlatformError(PlatformException e) {
    if (e.code == 'network_error' || e.message?.contains('network') == true) {
      return 'No internet connection. Please check your network and try again.';
    }
    return 'Sign in failed. Please try again.';
  }

  String _handleFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
