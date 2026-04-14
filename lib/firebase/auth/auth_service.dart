import 'package:buddy/firebase/firestore/user_firestore_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Google Sign In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInClientAuthorization? authorization = await googleUser
          .authorizationClient
          .authorizationForScopes(['email', 'profile']);

      final googleAuth = googleUser.authentication;
      final accessToken = authorization?.accessToken;

      if (accessToken == null && googleAuth.idToken == null) {
        throw 'Google sign-in failed. No OAuth token returned.';
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        await _userFirestoreService.createUserProfileIfNotExists(user);
      }
      return user;
    } on PlatformException catch (e) {
      debugPrint(
        'AuthService Google PlatformException: ${e.code} ${e.message}',
      );
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService Google FirebaseAuthException: ${e.code} ${e.message}',
      );
      throw (_handleFirebaseAuthError(e));
    } catch (e) {
      debugPrint('AuthService Google unknown error: $e');
      throw 'Google sign-in failed. Please try again.';
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
      debugPrint(
        'AuthService Email SignIn PlatformException: ${e.code} ${e.message}',
      );
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService Email SignIn FirebaseAuthException: ${e.code} ${e.message}',
      );
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
      debugPrint(
        'AuthService Email SignUp PlatformException: ${e.code} ${e.message}',
      );
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService Email SignUp FirebaseAuthException: ${e.code} ${e.message}',
      );
      throw (_handleFirebaseAuthError(e));
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on PlatformException catch (e) {
      debugPrint(
        'AuthService ResetPassword PlatformException: ${e.code} ${e.message}',
      );
      throw (_handlePlatformError(e));
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'AuthService ResetPassword FirebaseAuthException: ${e.code} ${e.message}',
      );
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
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Authentication.';
      case 'unauthorized-domain':
        return 'This domain is not authorized in Firebase Authentication settings.';
      case 'invalid-api-key':
      case 'api-key-not-valid-please-pass-a-valid-api-key':
        return 'Firebase API key is invalid or restricted for this platform/domain.';
      case 'app-not-authorized':
        return 'This app/domain is not authorized for your Firebase project.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect password or email.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return e.message ?? 'Authentication failed. Please try again.';
    }
  }
}
