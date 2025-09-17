import 'package:flutter/cupertino.dart';

class AppTransitions {
  static PageRouteBuilder<T> fadeScale<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static PageRouteBuilder<T> slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_,_, _) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  static PageRoute<T> cupertino<T>(Widget page) {
    return CupertinoPageRoute<T>(builder: (_) => page);
  }
}
