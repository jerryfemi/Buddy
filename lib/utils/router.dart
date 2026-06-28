import 'dart:async';

import 'package:buddy/providers/auth_provider.dart';
import 'package:buddy/screens/edit_note_screen.dart';
import 'package:buddy/screens/events_screen.dart';
import 'package:buddy/screens/home_screen.dart';
import 'package:buddy/screens/login_or_register_screen.dart';
import 'package:buddy/screens/navigation_screen.dart';
import 'package:buddy/screens/notes_screen.dart';
import 'package:buddy/screens/recently_deleted_notes_screen.dart';
import 'package:buddy/screens/tasks_screen.dart';
import 'package:buddy/screens/user_profile_screen.dart';
import 'package:buddy/screens/year_view_screen.dart';
import 'package:buddy/utils/app_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/note_model.dart';

abstract final class AppRoutes {
  static const root = '/';
  static const auth = '/auth';
  static const home = '/home';
  static const notes = '/notes';
  static const tasks = '/tasks';
  static const reminders = '/reminders';
  static const yearView = '/yearView';
  static const editNote = '/edit-note';
  static const recentlyDeletedNotes = '/recently-deleted-notes';
  static const profile = '/profile';

  static String yearViewFor(int year) => '$yearView/$year';
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authService = ref.watch(authServiceProvider);
  final authRefresh = GoRouterRefreshStream(authService.authStateChanges);

  ref.onDispose(authRefresh.dispose);

  final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppRoutes.home,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final isLoggedIn = authService.currentUser != null;
      final location = state.matchedLocation;
      final isAuthRoute = location == AppRoutes.auth;



      if (isLoggedIn && isAuthRoute) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        redirect: (context, state) => AppRoutes.home,
      ),
      GoRoute(
        path: AppRoutes.auth,
        builder: (context, state) => const LoginOrRegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.editNote,
        pageBuilder: (context, state) {
          final note = state.extra is Note ? state.extra as Note : null;
          return CustomTransitionPage<void>(
            key: state.pageKey,
            transitionDuration: const Duration(milliseconds: 220),
            reverseTransitionDuration: const Duration(milliseconds: 170),
            child: EditNotesScreen(existingNote: note),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final fade = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOut,
                    reverseCurve: Curves.easeIn,
                  );
                  final scale = Tween<double>(begin: 0.98, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                      reverseCurve: Curves.easeInCubic,
                    ),
                  );

                  return FadeTransition(
                    opacity: fade,
                    child: ScaleTransition(scale: scale, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recentlyDeletedNotes,
        builder: (context, state) => const RecentlyDeletedNotesScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.yearView}/:year',
        builder: (context, state) {
          final yearParam = state.pathParameters['year'];
          final year = int.tryParse(yearParam ?? '') ?? DateTime.now().year;
          return YearViewScreen(year: year, onMonthSelected: (_) {});
        },
      ),
      // statefull shell
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            NavigationScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notes,
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.tasks,
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.reminders,
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (_) => notifyListeners(),
      onError: (_) => notifyListeners(),
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
