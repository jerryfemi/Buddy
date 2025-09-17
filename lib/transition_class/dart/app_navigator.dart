import 'package:buddy/transition_class/dart/transition_manager.dart';
import 'package:flutter/material.dart';

enum TransitionType { fadeScale, slide, cupertino }

class AppNavigator {
  static Future<T?> push<T>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.cupertino,
  }) {
    switch (type) {
      case TransitionType.fadeScale:
        return Navigator.of(context).push(AppTransitions.fadeScale(page));
      case TransitionType.slide:
        return Navigator.of(context).push(AppTransitions.slide(page));
      case TransitionType.cupertino:
        return Navigator.of(context).push(AppTransitions.cupertino(page));
    }
  }

  static void pop<T extends Object?>(BuildContext context, [T? result]) {
    Navigator.of(context).pop(result);
  }

  static Future<T?> replace<T>(
    BuildContext context,
    Widget page, {
    TransitionType type = TransitionType.cupertino,
  }) {
    switch (type) {
      case TransitionType.fadeScale:
        return Navigator.of(
          context,
        ).pushReplacement(AppTransitions.fadeScale(page));
      case TransitionType.slide:
        return Navigator.of(
          context,
        ).pushReplacement(AppTransitions.slide(page));
      case TransitionType.cupertino:
        return Navigator.of(
          context,
        ).pushReplacement(AppTransitions.cupertino(page));
    }
  }
}
