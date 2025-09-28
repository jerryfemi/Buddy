import 'package:buddy/firebase/auth/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hive/hive.dart';

import '../models/calendar_event_model.dart';
import '../models/deleted_notes_model.dart';
import '../models/note_model.dart';
import '../models/previous_events_model.dart';
import '../models/task_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

class AuthNotifier extends StateNotifier<User?> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(_authService.currentUser) {
    // listen to changes
    _authService.authStateChanges.listen((user) {
      state = user;
    });
  }

  // SIGN IN WITH GOOGLE
  Future<void> signInWithGoogle() async {
    final user = await _authService.signInWithGoogle();
    if (user != null) state = user;
  }

  // SIGN IN WITH EMAIL
  Future<void> signInWithEmail(String email, String password) async {
    final user = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    if (user != null) state = user;
  }

  // SIGN UP WITH EMAIL
  Future<void> signUpWithEmail(String email, String password) async {
    final user = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );
    if (user != null) state = user;
  }

  // RECOVER PASSWORD
  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  //SIGN OUT
  Future<void> signOut() async {
    await clearData();
    await _authService.signOut();
    state = null;
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, User?>((ref) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

Future<void> clearData() async {

    if (Hive.isBoxOpen('notesBox')) {
      await Hive.box<Note>('notesBox').clear();
    }
    if (Hive.isBoxOpen('tasksBox')) {
      await Hive.box<Task>('tasksBox').clear();
    }
    if (Hive.isBoxOpen('eventsBox')) {
      await Hive.box<CalendarEvent>('eventsBox').clear();
    }
    if (Hive.isBoxOpen('deletedNotesBox')) {
      await Hive.box<DeletedNote>('deletedNotesBox').clear();
    }
    if (Hive.isBoxOpen('previousEventsBox')) {
      await Hive.box<PreviousEvents>('previousEventsBox').clear();
    }

}


