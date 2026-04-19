import 'dart:async';

import 'package:buddy/utils/responsive_utils.dart';
import 'package:buddy/utils/router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_intent/receive_intent.dart' as receive_intent;

import '../utils/app_keys.dart';
import '../widgets/add_events_sheet.dart';
import '../widgets/task_dialog.dart';

class ShortcutHandler {
  static const double _collapsedTaskSnap = 0.58;
  static const double _expandedTaskSnap = 0.8;
  static const double _expandedEventSnap = 0.8;

  static StreamSubscription? intentSub;
  static bool hasHandledIntent = false;

  //  initialize and listen for shortcuts
  static void init() {
    // handle shortcut
    if (!hasHandledIntent) {
      handleInitialIntent();
    }

    // Handle shortcuts while the app is already running
    intentSub = receive_intent.ReceiveIntent.receivedIntentStream.listen(
      (intent) {
        final shortcutValue = intent?.extra?['shortcut'];
        if (shortcutValue != null) {
          unawaited(navigateBasedOnShortcut(shortcutValue));
        }
      },
      onError: (e) {
        debugPrint('Error receiving shortcut intent: $e');
      },
    );
  }

  // handle shortcuts
  static Future<void> handleInitialIntent() async {
    final intent = await receive_intent.ReceiveIntent.getInitialIntent();
    if (intent != null) {
      final shortcutValue = intent.extra?['shortcut'];
      if (shortcutValue != null) {
        hasHandledIntent = true;
        await Future.delayed(const Duration(milliseconds: 200));
        await navigateBasedOnShortcut(shortcutValue);
      }
    }
  }

  // navigate to the screen based on shortcut tapped
  static Future<void> navigateBasedOnShortcut(String value) async {
    switch (value) {
      case 'new_note':
        await _goToBranch(AppRoutes.notes);
        final noteContext = navigatorKey.currentContext;
        if (noteContext != null) {
          await GoRouter.of(noteContext).push(AppRoutes.editNote);
        }
        break;
      case 'new_task':
        await _goToBranch(AppRoutes.tasks);
        final taskContext = navigatorKey.currentContext;
        if (taskContext != null) {
          await openTaskDialog(taskContext);
        }
        break;
      case 'new_event':
        await _goToBranch(AppRoutes.reminders);
        final eventContext = navigatorKey.currentContext;
        if (eventContext != null) {
          await openAddEventsDialog(eventContext);
        }

        break;
    }
  }

  static Future<void> _goToBranch(String location) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) {
      return;
    }

    GoRouter.of(ctx).go(location);
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static Future<void> openTaskDialog(BuildContext ctx) async {
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 190),
        reverseDuration: Duration(milliseconds: 170),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: _collapsedTaskSnap,
          minChildSize: _collapsedTaskSnap,
          maxChildSize: _expandedTaskSnap,
          snap: true,
          snapSizes: const [_collapsedTaskSnap, _expandedTaskSnap],
          builder: (context, scrollController) =>
              TaskDialog(controller: scrollController),
        );
      },
    );
  }

  //
  static Future<void> openAddEventsDialog(BuildContext ctx) async {
    final collapsedEventSnap = ctx.adaptSize(0.6, tab: 0.5);

    showModalBottomSheet<void>(
      isDismissible: false,
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 190),
        reverseDuration: Duration(milliseconds: 170),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: collapsedEventSnap,
        minChildSize: collapsedEventSnap,
        maxChildSize: _expandedEventSnap,
        snap: true,
        snapSizes: [collapsedEventSnap, _expandedEventSnap],
        builder: (context, scrollController) {
          return AddEventSheet(scrollController: scrollController);
        },
      ),
    );
  }

  static void dispose() {
    intentSub?.cancel();
    hasHandledIntent = false;
  }
}
