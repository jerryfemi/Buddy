import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/providers/global_sync_provider.dart';
import 'package:buddy/screens/login_or_register_screen.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/calendar_event_provider.dart';
import '../../providers/deleted_notes_provider.dart';
import '../../providers/tasks_provider.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);

    if (authState != null) {
      // user logged in
      final syncManager = ref.watch(globalSyncManagerProvider);
      if (syncManager != null) {
        syncManager.syncAll();
        syncManager.listenForConnectivityAndSync();
      }

      // clean up expired
      ref.read(eventsProvider.notifier).cleanupExpiredEvents();
      ref.read(tasksProvider.notifier).cleanupCompletedTasks();
      ref.read(deletedNotesProvider.notifier).cleanupExpiredNotes();

      return const NavigationScreen();
    } else {
      return LoginOrRegisterScreen();
    }
  }
}

