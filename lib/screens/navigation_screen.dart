import 'package:buddy/providers/global_sync_provider.dart';
import 'package:buddy/providers/tasks_provider.dart';
import 'package:buddy/screens/notes_screen.dart';
import 'package:buddy/screens/reminders_screen.dart';
import 'package:buddy/screens/tasks_screen.dart';
import 'package:buddy/widgets/custom_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    NotesScreen(),
    TasksScreen(),
    RemindersScreen(),
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      final syncManager = ref.read(globalSyncManagerProvider);
      syncManager?.syncAll();
      syncManager?.listenForConnectivityAndSync();
      ref.read(tasksProvider.notifier).cleanupCompletedTasks();
    });
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(resizeToAvoidBottomInset: false,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar:  Padding(
        padding:  EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
        child: CustomNavBar(
            selectedIndex: _currentIndex,
            onTabChanged: _onTabTapped,
          ),
      ),
    );
  }
}
