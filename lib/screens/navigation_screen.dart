import 'package:buddy/screens/notes_screen.dart';
import 'package:buddy/screens/reminders_screen.dart';
import 'package:buddy/screens/tasks_screen.dart';
import 'package:buddy/widgets/custom_nav_bar.dart';
import 'package:flutter/material.dart';

import 'home_screen.dart';

class NavigationScreen extends StatefulWidget {
  const NavigationScreen({super.key});

  @override
  State<NavigationScreen> createState() => _NavigationScreenState();

  //  helper for HomeScreen to switch tabs
  static void switchToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_NavigationScreenState>();
    state?._onTabTapped(index);
  }
}

class _NavigationScreenState extends State<NavigationScreen> {
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
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: SafeArea(
        child: CustomNavBar(
          selectedIndex: _currentIndex,
          onTabChanged: _onTabTapped,
        ),
      ),
    );
  }
}