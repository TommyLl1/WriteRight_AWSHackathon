import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FadeTransitionPage<T> extends CustomTransitionPage<T> {
  FadeTransitionPage({
    required super.child,
    super.transitionDuration,
  }) : super(
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}
