import 'dart:async';

import 'package:buddy/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:receive_intent/receive_intent.dart' as receive_intent;

import '../main.dart';
import '../screens/edit_note_screen.dart';
import '../screens/navigation_screen.dart';
import '../widgets/add_events_sheet.dart';
import '../widgets/task_dialog.dart';

class ShortcutHandler {
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
          navigateBasedOnShortcut(shortcutValue);
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
        navigateBasedOnShortcut(shortcutValue);
      }
    }
  }

  // navigate to the screen based on shortcut tapped
  static void navigateBasedOnShortcut(String value) {
    final ctx = navigatorKey.currentContext;

    if (ctx == null) return;

    switch (value) {
      case 'new_note':
        NavigationScreen.openShortcut(1, () async {
          await navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => EditNotesScreen(existingNote: null),
            ),
          );
        });
        break;
      case 'new_task':
        NavigationScreen.openShortcut(2, () => openTaskDialog(ctx));
        break;
      case 'new_event':
        NavigationScreen.openShortcut(3, () => openAddEventsDialog(ctx));

        break;
    }
  }

  static Future<void> openTaskDialog(BuildContext ctx) async {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (context, scrollController) =>
              TaskDialog(controller: scrollController),
        );
      },
    );
  }

  //
  static Future<void> openAddEventsDialog(BuildContext ctx) async {
    showModalBottomSheet(
      isDismissible: false,
      context: ctx,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: context.adaptSize(0.6, tab: 0.5),
        minChildSize: 0.37,
        maxChildSize: 0.8,
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
