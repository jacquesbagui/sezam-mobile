import 'package:flutter/material.dart';

/// Helper pour des navigations rapides et fluides
class NavigationHelper {
  /// Navigation rapide avec transition fade (plus rapide que MaterialPageRoute)
  static Route<T> fadeRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
    );
  }

  /// Navigation rapide avec transition slide (plus rapide que MaterialPageRoute)
  static Route<T> slideRoute<T extends Object?>(
    Widget page, {
    Duration duration = const Duration(milliseconds: 200),
    Offset begin = const Offset(1.0, 0.0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: begin,
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        ));
        return SlideTransition(
          position: slideAnimation,
          child: child,
        );
      },
    );
  }

  /// Navigation instantanée (sans animation)
  static Route<T> instantRoute<T extends Object?>(
    Widget page,
  ) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }
}

