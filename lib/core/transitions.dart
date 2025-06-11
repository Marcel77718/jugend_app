import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jugend_app/core/performance_monitor.dart';

class FadePageTransition extends CustomTransitionPage<void> {
  FadePageTransition({required super.child, super.key})
    : super(
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
                PerformanceWidget(
                  name: 'FadeTransition',
                  child: FadeTransition(opacity: animation, child: child),
                ),
      );
}

class SlidePageTransition extends CustomTransitionPage<void> {
  SlidePageTransition({required super.child, super.key})
    : super(
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
                PerformanceWidget(
                  name: 'SlideTransition',
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: child,
                  ),
                ),
      );
}

class ScalePageTransition extends CustomTransitionPage<void> {
  ScalePageTransition({required super.child, super.key})
    : super(
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) =>
                PerformanceWidget(
                  name: 'ScaleTransition',
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                ),
      );
}
