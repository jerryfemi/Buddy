import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../firebase/firestore/user_firestore_services.dart';

/// Provider for UserFirestoreService
final userFirestoreProvider = Provider<UserFirestoreService>((ref) {
  return UserFirestoreService();
});

/// Provider for current user that reacts to auth state changes
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// --- REFACTORED: Notifier for user profile data
class UserProfileNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref ref;
  StreamSubscription<Map<String, dynamic>?>? _subscription;

  UserProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Watch auth state and react to user changes
    final userAsync = ref.watch(currentUserProvider);

    userAsync.whenData((user) {
      // Cancel any previous subscription to avoid leaks or permission errors
      _subscription?.cancel();
      _subscription = null;

      if (user == null) {
        // User logged out -> clear profile state
        state = const AsyncValue.data(null);
        return;
      }

      // Start listening to the Firestore user profile stream
      _subscription = ref
          .read(userFirestoreProvider)
          .userProfileStream(user.uid)
          .listen((profile) {
        if (mounted) {
          state = AsyncValue.data(profile);
        }
      });
    });
  }

  /// Allows us to manually override the profile state in memory
  void updateProfile(Map<String, dynamic> newProfile) {
    state = AsyncValue.data(newProfile);
  }

  @override
  void dispose() {
    // Cancel Firestore listener when notifier is disposed
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for user profile data
final userProfileProvider =
StateNotifierProvider<UserProfileNotifier, AsyncValue<Map<String, dynamic>?>>(
      (ref) => UserProfileNotifier(ref),
);
