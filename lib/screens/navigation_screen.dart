import 'package:buddy/providers/global_sync_provider.dart';
import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/screens/events_screen.dart';
import 'package:buddy/screens/notes_screen.dart';
import 'package:buddy/screens/tasks_screen.dart';
import 'package:buddy/utils/reschedule_notifs.dart';
import 'package:buddy/widgets/custom_nav_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/calendar_event_provider.dart';
import '../providers/deleted_notes_provider.dart';
import '../services/shortcut_handler.dart';
import 'home_screen.dart';

final GlobalKey<NavigationScreenState> navigationScreenKey =
    GlobalKey<NavigationScreenState>();

class NavigationScreen extends ConsumerStatefulWidget {
  NavigationScreen() : super(key: navigationScreenKey);

  @override
  ConsumerState<NavigationScreen> createState() => NavigationScreenState();

  //  helper for HomeScreen to switch tabs
  static void switchToTab(int index) {
    navigationScreenKey.currentState?.switchTab(index);
  }

  static Future<void> openShortcut(
    int index,
    Future<void> Function() afterSwitch,
  ) async {
    navigationScreenKey.currentState?.switchTab(index);

    await Future.delayed(const Duration(milliseconds: 100));
    await afterSwitch();
  }
}

class NavigationScreenState extends ConsumerState<NavigationScreen> {
  @override
  void initState() {
    super.initState();

    // Initialize sync after the screen has rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSync();
      if (mounted) {
        ShortcutHandler.init();
      }
    });
  }

  @override
  void dispose() {
    ShortcutHandler.dispose();
    super.dispose();
  }

  Future<void> _initializeSync() async {
    // Check internet first

    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return;
    }
    final syncManager = ref.read(globalSyncManagerProvider);

    if (syncManager != null) {
      syncManager.listenForConnectivityAndSync();

      Future.delayed(const Duration(milliseconds: 500), () async {
        // Run sync in background
        syncManager.syncAll().catchError((error) {});

        // Cleanup expired items
        ref.read(eventsProvider.notifier).cleanupExpiredEvents();
        ref.read(tasksProvider.notifier).cleanupCompletedTasks();
        ref.read(deletedNotesProvider.notifier).cleanupExpiredNotes();

        //reschedule notifications
        await RescheduleNotifs(ref).run().catchError((error) {});
      });
    }
  }

  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    NotesScreen(),
    TasksScreen(),
    EventsScreen(),
  ];

  void switchTab(int index) {
    _onTabTapped(index);
  }

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
