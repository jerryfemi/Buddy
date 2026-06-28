import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firebase/firestore/user_firestore_services.dart';
import 'auth_provider.dart';

// Provider for UserFirestoreService
final userFirestoreProvider = Provider<UserFirestoreService>((ref) {
  return UserFirestoreService();
});

//  Notifier
class UserProfileNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>?>> {
  final Ref ref;
  StreamSubscription<Map<String, dynamic>?>? _subscription;

  UserProfileNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Listen continuously to auth changes
    ref.listen<AsyncValue<User?>>(
      authStateProvider,
          (previous, next) {
        next.whenData((user) {
          _subscription?.cancel();
          _subscription = null;

          if (user == null) {
            state = const AsyncValue.data(null);
            return;
          }

          _subscription = ref
              .read(userFirestoreProvider)
              .userProfileStream(user.uid)
              .listen((profile) {
            if (mounted) {
              state = AsyncValue.data(profile);
            }
          });
        });
      },
    );
  }

  // Allows us to manually override the profile state in memory
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

// Provider for user profile data
final userProfileProvider =
StateNotifierProvider<UserProfileNotifier, AsyncValue<Map<String, dynamic>?>>(
      (ref) => UserProfileNotifier(ref),
);
