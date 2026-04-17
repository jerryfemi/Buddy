import 'package:buddy/providers/global_sync_provider.dart';
import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/utils/reschedule_notifs.dart';
import 'package:buddy/widgets/custom_nav_bar.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/calendar_event_provider.dart';
import '../providers/deleted_notes_provider.dart';
import '../services/shortcut_handler.dart';

class NavigationScreen extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationScreen({super.key, required this.navigationShell});

  @override
  ConsumerState<NavigationScreen> createState() => NavigationScreenState();
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
    ref.read(globalSyncManagerProvider)?.stopConnectivityListener();
    ShortcutHandler.dispose();
    super.dispose();
  }

  Future<void> _initializeSync() async {
    // Check internet first

    final connectivityResults = await Connectivity().checkConnectivity();

    if (connectivityResults.contains(ConnectivityResult.none)) {
      return;
    }
    final syncManager = ref.read(globalSyncManagerProvider);

    if (syncManager != null) {
      syncManager.listenForConnectivityAndSync();

      Future.delayed(const Duration(milliseconds: 300), () async {
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

  void _onTabTapped(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  int get _selectedIndex => widget.navigationShell.currentIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: widget.navigationShell,
      bottomNavigationBar: CustomNavBar(
        selectedIndex: _selectedIndex,
        onTabChanged: _onTabTapped,
      ),

    );
  }
}
