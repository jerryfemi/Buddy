import 'package:buddy/providers/global_sync_provider.dart';
import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/screens/notes_screen.dart';
import 'package:buddy/screens/reminders_screen.dart';
import 'package:buddy/screens/tasks_screen.dart';
import 'package:buddy/services/events_notifications_repository.dart';
import 'package:buddy/services/task_notifications_repository.dart';
import 'package:buddy/utils/reschedule_notifs.dart';
import 'package:buddy/widgets/custom_nav_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_event_provider.dart';
import '../providers/deleted_notes_provider.dart';
import 'home_screen.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key});

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();

  //  helper for HomeScreen to switch tabs
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_NavigationScreenState>();
    state?._onTabTapped(index);
  }
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize sync after the screen has rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSync();
    });
  }

  Future<void> _initializeSync() async {
    // Check internet first

    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      // No internet - skip sync but still show UI
      print('No internet connection - skipping initial sync');
      return;
    }
    final syncManager = ref.read(globalSyncManagerProvider);

    if (syncManager != null) {
      syncManager.listenForConnectivityAndSync();

      Future.delayed(const Duration(milliseconds: 500), () async {
        // Run sync in background
        await syncManager.syncAll();

        // Cleanup expired items
        ref.read(eventsProvider.notifier).cleanupExpiredEvents();
        ref.read(tasksProvider.notifier).cleanupCompletedTasks();
        ref.read(deletedNotesProvider.notifier).cleanupExpiredNotes();

        //reschedule notifications
        await RescheduleNotifs(ref).run();
      });
    }
  }


  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    NotesScreen(),
    TasksScreen(),
    RemindersScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: CustomNavBar(
          selectedIndex: _currentIndex,
          onTabChanged: _onTabTapped,
        ),
      ),
    );
  }
}
