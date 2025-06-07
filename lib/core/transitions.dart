import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FadePageTransition extends CustomTransitionPage<void> {
  FadePageTransition({required Widget child, LocalKey? key})
    : super(
        key: key,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      );
}

class SlidePageTransition extends CustomTransitionPage<void> {
  SlidePageTransition({required Widget child, LocalKey? key})
    : super(
        key: key,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(-1.0, 0.0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: child,
          );
        },
      );
}

class ScalePageTransition extends CustomTransitionPage<void> {
  ScalePageTransition({required Widget child, LocalKey? key})
    : super(
        key: key,
        child: child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.8, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      );
}
